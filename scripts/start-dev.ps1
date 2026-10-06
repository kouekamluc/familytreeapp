param([int]$BackendPort = 8000, [int]$FrontendPort = 8085, [string]$PythonPath, [switch]$NoOpen)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location $projectRoot
if (!$PythonPath) {
    $PythonPath = Join-Path $projectRoot '.runtime-venv/Scripts/python.exe'
    if (!(Test-Path -LiteralPath $PythonPath)) { $PythonPath = Join-Path $projectRoot '.venv/Scripts/python.exe' }
}
if (!(Test-Path -LiteralPath $PythonPath)) { throw 'Install the backend dependencies first; see backend/README.md.' }
$flutterExecutable = (Get-Command flutter -ErrorAction SilentlyContinue).Source
if (!$flutterExecutable) { $flutterExecutable = Join-Path $env:USERPROFILE 'dev/flutter/bin/flutter.bat' }
if (!(Test-Path -LiteralPath $flutterExecutable)) { throw 'Flutter was not found. Add it to PATH.' }
$logDirectory = Join-Path $projectRoot '.dev-logs'
New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null
function Wait-Ready([string]$Url, [switch]$Backend) {
    for ($attempt = 0; $attempt -lt 30; $attempt++) {
        try {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 2
            if ($response.StatusCode -eq 200) {
                if (!$Backend) { return }
                $payload = $response.Content | ConvertFrom-Json
                if ($payload.service -eq 'familytree' -and $payload.status -eq 'ok') { return }
            }
        } catch { }
        Start-Sleep -Milliseconds 500
    }
    throw "Server did not become ready at $Url. Check .dev-logs."
}
$createdProcesses = @()
try {
    Push-Location (Join-Path $projectRoot 'backend')
    try {
        & $PythonPath manage.py check
        if ($LASTEXITCODE) { throw 'Backend configuration failed.' }
        & $PythonPath manage.py migrate --check
        if ($LASTEXITCODE) { throw 'Pending migrations. Back up the database, then run manage.py migrate.' }
    } finally { Pop-Location }
    Push-Location (Join-Path $projectRoot 'flutter_frontend')
    try {
        & $flutterExecutable pub get
        if ($LASTEXITCODE) { throw 'Frontend dependency installation failed.' }
        & $flutterExecutable build web --dart-define="API_BASE_URL=http://127.0.0.1:$BackendPort/api"
        if ($LASTEXITCODE) { throw 'Frontend build failed.' }
    } finally { Pop-Location }
    $backendUrl = "http://127.0.0.1:$BackendPort/api/health/"
    $backendReady = $false
    try {
        $payload = Invoke-RestMethod -Uri $backendUrl -TimeoutSec 2
        $backendReady = $payload.service -eq 'familytree' -and $payload.status -eq 'ok'
    } catch { }
    if (!$backendReady) {
        $createdProcesses += Start-Process -FilePath $PythonPath -ArgumentList @('manage.py', 'runserver', "127.0.0.1:$BackendPort", '--noreload') -WorkingDirectory (Join-Path $projectRoot 'backend') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $logDirectory 'backend.out.log') -RedirectStandardError (Join-Path $logDirectory 'backend.err.log')
    }
    Wait-Ready $backendUrl -Backend
    $webUrl = "http://127.0.0.1:$FrontendPort"
    $webDirectory = Join-Path $projectRoot 'flutter_frontend/build/web'
    $createdProcesses += Start-Process -FilePath $PythonPath -ArgumentList @('-m', 'http.server', "$FrontendPort", '--bind', '127.0.0.1', '--directory', "`"$webDirectory`"") -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $logDirectory 'web.out.log') -RedirectStandardError (Join-Path $logDirectory 'web.err.log')
    Wait-Ready $webUrl
    Write-Host "App ready: $webUrl"
    Write-Host "API ready: $backendUrl"
    $createdProcesses.Id | Set-Content (Join-Path $logDirectory 'processes.txt')
    if (!$NoOpen) { Start-Process $webUrl }
} catch {
    foreach ($ownedProcess in $createdProcesses) {
        if (!$ownedProcess.HasExited) { Stop-Process -Id $ownedProcess.Id -ErrorAction SilentlyContinue }
    }
    throw
}
