# Builds MTC-iPTv SuperAdmin (the ONLY program with the admin panel, owner 2026-10-17) for Windows.
#  - Same code as the viewer app, built with MTC_SUPERADMIN: admin panel + scheduler, no auto-update
#    (the public appcast is the viewer app's), its own exe/window/mutex/%APPDATA% folder -> runs next to MTC-iPTv.
#  - Never published to the public GitHub releases. Output: %USERPROFILE%\.mtc-iptv\superadmin\
#    (a folder + a zip) and a desktop shortcut.
#  - build\windows is wiped before and after, so a later viewer build never inherits this identity.
#
#   powershell -File scripts/build-superadmin.ps1
$ErrorActionPreference = 'Stop'
$root = Resolve-Path "$PSScriptRoot\.."
$env:PATH = "$HOME\scoop\apps\flutter\current\bin;$HOME\scoop\shims;$env:PATH"
Set-Location $root

$pub = [IO.File]::ReadAllText("$root\pubspec.yaml")
$m = [regex]::Match($pub, '(?m)^version:\s*([^+\s]+)\+(\d+)\s*$')
if (-not $m.Success) { throw 'pubspec version not found' }
$full = $m.Groups[1].Value; $build = $m.Groups[2].Value
$core = ($full -split '-')[0]

function Clear-WindowsBuild {
  # only processes started from build\windows (never the installed apps)
  Get-Process | Where-Object { $_.Path -and $_.Path.StartsWith("$root\build\windows", 'OrdinalIgnoreCase') } | Stop-Process -Force
  if (Test-Path "$root\build\windows") { Remove-Item "$root\build\windows" -Recurse -Force }
}

Clear-WindowsBuild
$env:MTC_SUPERADMIN = '1'
try {
  flutter build windows --release "--build-name=$core" "--build-number=$build" "--dart-define=APP_VERSION=$full" '--dart-define=MTC_SUPERADMIN=true' | Out-Host
  if ($LASTEXITCODE -ne 0) { throw "build failed (exit $LASTEXITCODE)" }
  $rel = "$root\build\windows\x64\runner\Release"
  if (-not (Test-Path "$rel\mtc_superadmin.exe")) { throw 'mtc_superadmin.exe missing - identity not applied' }

  $out = "$HOME\.mtc-iptv\superadmin"
  $app = "$out\MTC-iPTv SuperAdmin"
  Get-Process | Where-Object { $_.Path -and $_.Path.StartsWith($app, 'OrdinalIgnoreCase') } | ForEach-Object { throw "MTC-iPTv SuperAdmin is running from $app - close it first." }
  if (Test-Path $app) { Remove-Item $app -Recurse -Force }
  New-Item -ItemType Directory -Force $app | Out-Null
  Copy-Item "$rel\*" $app -Recurse
  $zip = "$out\MTC-iPTv-SuperAdmin-$full-windows.zip"
  if (Test-Path $zip) { Remove-Item $zip }
  Compress-Archive -Path $app -DestinationPath $zip

  $lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'MTC-iPTv SuperAdmin.lnk'
  $sh = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
  $sh.TargetPath = "$app\mtc_superadmin.exe"
  $sh.WorkingDirectory = $app
  $sh.Description = 'MTC-iPTv SuperAdmin'
  $sh.Save()

  Write-Host "SuperAdmin $full -> $app" -ForegroundColor Green
  Write-Host "zip: $zip"
  Write-Host "shortcut: $lnk"
} finally {
  Remove-Item Env:\MTC_SUPERADMIN -ErrorAction SilentlyContinue
  Clear-WindowsBuild
}
