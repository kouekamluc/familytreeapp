param([switch]$RunChecks, [switch]$Rebuild)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$sdk = Join-Path $env:LOCALAPPDATA 'Android/Sdk'
$adb = Join-Path $sdk 'platform-tools/adb.exe'
$emulator = Join-Path $sdk 'emulator/emulator.exe'
$avdmanager = Join-Path $sdk 'cmdline-tools/latest/bin/avdmanager.bat'
$flutter = Join-Path $env:USERPROFILE 'dev/flutter/bin/flutter.bat'
$python = Join-Path $projectRoot '.runtime-venv/Scripts/python.exe'
$logs = Join-Path $projectRoot '.dev-logs'
$frontend = Join-Path $projectRoot 'flutter_frontend'
. (Join-Path $PSScriptRoot 'android-build-cache.ps1')
$serial = 'emulator-5554'
$avdName = 'familytree_pc_test_api35'
$package = 'com.kkevo.familytree.audit'
foreach ($required in @($adb, $emulator, $avdmanager, $flutter, $python)) {
    if (!(Test-Path -LiteralPath $required)) { throw "Required testing tool is missing: $required" }
}
New-Item -ItemType Directory -Force -Path $logs | Out-Null
$env:ANDROID_AVD_HOME = Join-Path $logs 'avds'
$env:ANDROID_HOME = $sdk
New-Item -ItemType Directory -Force -Path $env:ANDROID_AVD_HOME | Out-Null
$avdDirectory = Join-Path $env:ANDROID_AVD_HOME "$avdName.avd"
if (!(Test-Path -LiteralPath (Join-Path $avdDirectory 'config.ini'))) {
    'no' | & $avdmanager create avd -n $avdName -k 'system-images;android-35;google_apis;x86_64' -d pixel_5 -p $avdDirectory
    if ($LASTEXITCODE) { throw 'Virtual phone creation failed. Install the Android 15 Google APIs x86_64 image in the SDK.' }
}
$deviceLines = & $adb devices
if (($deviceLines -join "`n") -notmatch "$serial\s+(device|offline)") {
    # A visible window is intentional: the user requested an app they can run on the PC.
    $process = Start-Process -FilePath $emulator -ArgumentList @('-avd', $avdName, '-port', '5554', '-memory', '3072', '-gpu', 'swiftshader_indirect', '-no-snapshot', '-camera-front', 'none', '-camera-back', 'none') -WindowStyle Normal -PassThru -RedirectStandardOutput (Join-Path $logs 'pc-emulator.out.log') -RedirectStandardError (Join-Path $logs 'pc-emulator.err.log')
    $process.Id | Set-Content (Join-Path $logs 'pc-emulator.pid')
}
Write-Host 'Waiting for the PC virtual phone to finish booting...'
$ready = $false
for ($attempt = 0; $attempt -lt 150; $attempt++) {
    try { $state = & $adb -s $serial get-state 2>$null } catch { $state = '' }
    if ($state -match '^\s*device\s*$') {
        $name = & $adb -s $serial shell getprop ro.boot.qemu.avd_name
        if ($name -notmatch "^\s*$avdName\s*$") { throw "Port 5554 belongs to another emulator. Close it before using this launcher." }
        $boot = & $adb -s $serial shell getprop sys.boot_completed
        if ($boot -match '^\s*1\s*$') { $ready = $true; break }
    }
    Start-Sleep -Seconds 2
}
if (!$ready) { throw 'The virtual phone did not finish booting. Check .dev-logs/pc-emulator.*.log.' }
# This virtual device has no Bluetooth workflow; disabling its unstable HAL
# avoids emulator service crashes without changing the PC's Bluetooth settings.
& $adb -s $serial shell svc bluetooth disable | Out-Null

$listener = Get-NetTCPConnection -LocalPort 18000 -State Listen -ErrorAction SilentlyContinue
if ($listener) {
    $pidFile = Join-Path $logs 'pc-api.pid'
    $ownedServer = $false
    if (Test-Path -LiteralPath $pidFile) {
        $launcherId = [int](Get-Content $pidFile)
        $launcher = Get-CimInstance Win32_Process -Filter "ProcessId=$launcherId"
        foreach ($listenerId in $listener.OwningProcess) {
            $server = Get-CimInstance Win32_Process -Filter "ProcessId=$listenerId"
            # Windows virtual environments may start a child interpreter.
            if ($launcher.ExecutablePath -eq $python -and
                ($listenerId -eq $launcherId -or $server.ParentProcessId -eq $launcherId)) {
                $ownedServer = $true
            }
        }
    }
    if (!$ownedServer) {
        throw 'Port 18000 is occupied by another server. This launcher only uses its isolated test backend.'
    }
    if ($RunChecks -or $Rebuild) {
        # Load current API code and migrations whenever rebuilding the app.
        foreach ($listenerId in $listener.OwningProcess) {
            Stop-Process -Id $listenerId -Force
        }
        if ($launcherId -notin $listener.OwningProcess) {
            Stop-Process -Id $launcherId -Force -ErrorAction SilentlyContinue
        }
        $listener = $null
    }
}
if (!$listener) {
    $originalSettings = $env:DJANGO_SETTINGS_MODULE
    try {
        $env:DJANGO_SETTINGS_MODULE = 'familytree.device_test_settings'
        Push-Location (Join-Path $projectRoot 'backend')
        try {
            & $python manage.py migrate --noinput
            if ($LASTEXITCODE) { throw 'The isolated test database could not be prepared.' }
            $process = Start-Process -FilePath $python -ArgumentList @('manage.py', 'runserver', '127.0.0.1:18000', '--noreload') -WorkingDirectory (Get-Location).Path -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $logs 'pc-api.out.log') -RedirectStandardError (Join-Path $logs 'pc-api.err.log')
            $process.Id | Set-Content (Join-Path $logs 'pc-api.pid')
        } finally { Pop-Location }
    } finally { $env:DJANGO_SETTINGS_MODULE = $originalSettings }
}
$apiReady = $false
for ($attempt = 0; $attempt -lt 30; $attempt++) {
    try {
        $health = Invoke-RestMethod -Uri 'http://127.0.0.1:18000/api/health/' -TimeoutSec 2
        if ($health.service -eq 'familytree' -and $health.status -eq 'ok') { $apiReady = $true; break }
    } catch { }
    Start-Sleep -Milliseconds 500
}
if (!$apiReady) { throw 'The isolated test backend is not ready.' }
& $adb -s $serial reverse tcp:18000 tcp:18000
if ($LASTEXITCODE) { throw 'The virtual phone could not reach the PC test backend.' }

Push-Location $frontend
try {
    $apk = Join-Path $frontend 'build/pc-test-results/app-pc-audit-debug.apk'
    $stamp = "$apk.build.json"
    $apiBaseUrl = 'http://127.0.0.1:18000/api'
    $fingerprint = Get-MobileBuildFingerprint -Frontend $frontend
    $cached = Test-MobileBuildCache -Apk $apk -Stamp $stamp -Fingerprint $fingerprint -ApiBaseUrl $apiBaseUrl
    $buildApp = $RunChecks -or $Rebuild -or !$cached
    if (!$cached) { Write-Host 'The installed build cache is missing or outdated. Building the current mobile app...' }
    if ($buildApp) {
        # Regenerate native plugin registration, including the integration-test
        # plugin which a preceding release/web build may have excluded.
        & $flutter pub get
        if ($LASTEXITCODE) { throw 'The app testing dependencies could not be prepared.' }
    }
    if ($RunChecks) {
        $env:FAMILYTREE_TEST_RESULTS = 'build/pc-test-results'
        & $flutter drive --driver=test_driver/device_driver.dart --target=integration_test/pc_journeys_test.dart --flavor audit --debug -d $serial --dart-define=API_BASE_URL=http://127.0.0.1:18000/api --no-pub
        if ($LASTEXITCODE) { throw 'The PC app journey failed. The test output identifies the failing step.' }
    }
    if ($buildApp) {
        $fingerprint = Get-MobileBuildFingerprint -Frontend $frontend
        & $flutter build apk --debug --flavor audit --target-platform android-x64 --no-pub --dart-define=API_BASE_URL=http://127.0.0.1:18000/api
        if ($LASTEXITCODE) { throw 'The current Android test app did not build.' }
        if ((Get-MobileBuildFingerprint -Frontend $frontend) -ne $fingerprint) {
            throw 'Mobile source files changed during the build. Run the launcher again to build that version.'
        }
        New-Item -ItemType Directory -Force -Path (Split-Path $apk -Parent) | Out-Null
        # Keep the interactive app separate from the journey-test APK.
        Copy-Item -LiteralPath (Join-Path $frontend 'build/app/outputs/flutter-apk/app-audit-debug.apk') -Destination $apk -Force
        @{ schema = 1; sourcesSha256 = $fingerprint; apiBaseUrl = $apiBaseUrl;
            apkSha256 = (Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash
        } | ConvertTo-Json | Set-Content -LiteralPath $stamp -Encoding UTF8
    }
    & $adb -s $serial install -r $apk
    if ($LASTEXITCODE) { throw 'The app could not be installed on the PC virtual phone.' }
    & $adb -s $serial shell am start -n "$package/com.kkevo.flutter_frontend.MainActivity"
    if ($LASTEXITCODE) { throw 'The test app could not be launched.' }
    Write-Host 'Kkevo Family Tree is running on the PC virtual phone. This app uses isolated test records.'
} finally { Pop-Location }
