# Builds the media_kit PoC app and runs the automated test on the same samples (Phase 0, Appendix C).
# Requires: Visual Studio "Desktop development with C++" and Windows Developer Mode.
# Usage:  powershell -ExecutionPolicy Bypass -File run_flutter_poc.ps1 [-Only generated|official|catalog] [-Play 20]
# (Kept ASCII-only: Windows PowerShell 5 misreads UTF-8 files without a BOM.)
param([string]$Only = '', [int]$Play = 20)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$env:PATH = "$HOME\scoop\apps\flutter\current\bin;$env:PATH"
$env:PYTHONIOENCODING = 'utf-8'

Push-Location "$here\flutter_poc"
flutter build windows --release
if ($LASTEXITCODE -ne 0) { throw 'flutter build failed' }
Pop-Location

$samples = Resolve-Path "$here\..\..\docs\poc\data\samples.json"
$out = "$here\..\..\docs\poc\data\results-mediakit.json"
$py = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $py) { $py = 'C:\laragon\bin\python\python-3.13\python.exe' }
$server = Start-Process $py -ArgumentList "`"$here\serve.py`"" -PassThru -WindowStyle Hidden
Start-Sleep 2
try {
  $appArgs = @('--auto', '--samples', "$samples", '--out', $out, '--play', "$Play")
  if ($Only) { $appArgs += @('--only', $Only) }
  $app = Start-Process "$here\flutter_poc\build\windows\x64\runner\Release\mtc_player_poc.exe" -ArgumentList $appArgs -PassThru -Wait
  Write-Host "exit=$($app.ExitCode) results: $out"
} finally {
  Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
}
