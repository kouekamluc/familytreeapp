$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../android-build-cache.ps1')
$workspace = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$testRoot = Join-Path $workspace ('.dev-logs/cache-test-' + [Guid]::NewGuid())
New-Item -ItemType Directory -Path (Join-Path $testRoot 'lib') -Force | Out-Null
try {
    $source = Join-Path $testRoot 'lib/main.dart'
    'old design' | Set-Content -LiteralPath $source
    $apk = Join-Path $testRoot 'app.apk'
    'test apk' | Set-Content -LiteralPath $apk
    $stamp = "$apk.build.json"
    $fingerprint = Get-MobileBuildFingerprint -Frontend $testRoot
    $api = 'http://127.0.0.1:18000/api'
    if (Test-MobileBuildCache $apk $stamp $fingerprint $api) { throw 'Legacy unstamped APK must rebuild.' }
    @{ schema = 1; sourcesSha256 = $fingerprint; apiBaseUrl = $api;
        apkSha256 = (Get-FileHash -LiteralPath $apk).Hash
    } | ConvertTo-Json | Set-Content -LiteralPath $stamp
    if (!(Test-MobileBuildCache $apk $stamp $fingerprint $api)) { throw 'Identical build must be reusable.' }
    'new design' | Set-Content -LiteralPath $source
    $changed = Get-MobileBuildFingerprint -Frontend $testRoot
    if (Test-MobileBuildCache $apk $stamp $changed $api) { throw 'Changed app source must rebuild.' }
    if (Test-MobileBuildCache $apk $stamp $fingerprint 'http://another-server/api') { throw 'Changed build configuration must rebuild.' }
    'replacement apk' | Set-Content -LiteralPath $apk
    if (Test-MobileBuildCache $apk $stamp $fingerprint $api) { throw 'Replaced cached APK must rebuild.' }
    Write-Host 'All 5 Android build-cache checks passed.'
} finally {
    $resolved = (Resolve-Path -LiteralPath $testRoot).Path
    if (!$resolved.StartsWith((Join-Path $workspace '.dev-logs/cache-test-'), [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Unexpected test cleanup path.'
    }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
