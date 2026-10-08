function Get-MobileBuildFingerprint {
    param([Parameter(Mandatory)][string]$Frontend)
    $rootPath = (Resolve-Path -LiteralPath $Frontend).Path
    $files = @(
        foreach ($folder in @('lib', 'assets', 'android/app/src', 'android/gradle/wrapper')) {
            $path = Join-Path $rootPath $folder
            if (Test-Path -LiteralPath $path) { Get-ChildItem -LiteralPath $path -File -Recurse }
        }
        foreach ($name in @('pubspec.yaml', 'pubspec.lock', 'android/app/build.gradle.kts', 'android/build.gradle.kts', 'android/settings.gradle.kts', 'android/gradle.properties')) {
            $path = Join-Path $rootPath $name
            if (Test-Path -LiteralPath $path) { Get-Item -LiteralPath $path }
        }
    ) | Sort-Object FullName -Unique
    $entries = foreach ($file in $files) {
        $relative = $file.FullName.Substring($rootPath.Length).Replace('\', '/')
        "$relative=$((Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash)"
    }
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        [Convert]::ToBase64String($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes(($entries -join "`n"))))
    } finally { $sha.Dispose() }
}

function Test-MobileBuildCache {
    param([string]$Apk, [string]$Stamp, [string]$Fingerprint, [string]$ApiBaseUrl)
    if (!(Test-Path -LiteralPath $Apk) -or !(Test-Path -LiteralPath $Stamp)) { return $false }
    try {
        $saved = Get-Content -LiteralPath $Stamp -Raw | ConvertFrom-Json
        return $saved.schema -eq 1 -and $saved.sourcesSha256 -eq $Fingerprint -and
            $saved.apiBaseUrl -eq $ApiBaseUrl -and
            $saved.apkSha256 -eq (Get-FileHash -LiteralPath $Apk -Algorithm SHA256).Hash
    } catch { return $false }
}
