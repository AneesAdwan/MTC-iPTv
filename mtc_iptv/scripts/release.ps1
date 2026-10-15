# MTC-iPTv unified release (owner rule: ONE version for all platforms, every update is published).
#
# Single source of truth: mtc_iptv/pubspec.yaml  ->  version: X.Y.Z[-alpha.N]+BUILD
#
#   powershell -ExecutionPolicy Bypass -File scripts\release.ps1                 # next prerelease (alpha.N+1)
#   powershell -ExecutionPolicy Bypass -File scripts\release.ps1 -Bump none      # release current version as-is
#   powershell -ExecutionPolicy Bypass -File scripts\release.ps1 -Bump patch     # X.Y.(Z+1)-alpha.1
#   ... -Bump minor | major, add -Stable for a final (non-prerelease) version
#   ... -NoPush   build everything locally, do not commit/push/publish
#
# Steps: bump -> analyze + tests -> build Windows + Android -> installer -> SHA256SUMS
#        -> commit + tag -> push -> GitHub release (prerelease until R1 is accepted).
# Release notes come from the matching "## [version]" section of mtc_iptv/CHANGELOG.md (required).
# ASCII only: Windows PowerShell 5 misreads UTF-8 files without a BOM.
param(
  [ValidateSet('none', 'pre', 'patch', 'minor', 'major')][string]$Bump = 'pre',
  [switch]$Stable,
  [switch]$NoPush
)
$ErrorActionPreference = 'Stop'
$root = Resolve-Path "$PSScriptRoot\.."
$repo = Resolve-Path "$root\.."
$env:PATH = "$HOME\scoop\apps\flutter\current\bin;$HOME\scoop\shims;$env:PATH"
Set-Location $root

function Run($what, [scriptblock]$cmd) {
  Write-Host "==> $what" -ForegroundColor Cyan
  & $cmd | Out-Host
  if ($LASTEXITCODE -ne 0) { throw "$what failed (exit $LASTEXITCODE)" }
}

# ---- 1. version ---------------------------------------------------------------
$pub = [IO.File]::ReadAllText("$root\pubspec.yaml")
$m = [regex]::Match($pub, '(?m)^version:\s*(\d+)\.(\d+)\.(\d+)(?:-([a-z]+)\.(\d+))?\+(\d+)\s*$')
if (-not $m.Success) { throw 'pubspec version must look like X.Y.Z[-alpha.N]+BUILD' }
[int]$maj = $m.Groups[1].Value; [int]$min = $m.Groups[2].Value; [int]$pat = $m.Groups[3].Value
$tag = $m.Groups[4].Value; [int]$pre = if ($m.Groups[5].Success) { $m.Groups[5].Value } else { 0 }
[int]$build = $m.Groups[6].Value
if (-not $tag) { $tag = 'alpha' }

switch ($Bump) {
  'pre'   { $pre++ }
  'patch' { $pat++; $pre = 1 }
  'minor' { $min++; $pat = 0; $pre = 1 }
  'major' { $maj++; $min = 0; $pat = 0; $pre = 1 }
  'none'  { if ($pre -eq 0 -and -not $Stable) { $pre = 1 } }
}
if ($Bump -ne 'none') { $build++ }
$core = "$maj.$min.$pat"
$full = if ($Stable) { $core } else { "$core-$tag.$pre" }
$newLine = "version: $full+$build"
$pub = [regex]::Replace($pub, '(?m)^version:.*$', $newLine)
[IO.File]::WriteAllText("$root\pubspec.yaml", $pub, (New-Object Text.UTF8Encoding($false)))
Write-Host "Version: $full (build $build)" -ForegroundColor Green

# ---- 2. release notes from CHANGELOG ------------------------------------------------
$changelog = [IO.File]::ReadAllText("$root\CHANGELOG.md")
$sec = [regex]::Match($changelog, "(?ms)^## \[$([regex]::Escape($full))\].*?(?=^## \[|\z)")
if (-not $sec.Success) { throw "CHANGELOG.md has no section '## [$full]' - write the notes first." }
$dist = "$root\dist"
if (Test-Path $dist) { Remove-Item $dist -Recurse -Force }
New-Item -ItemType Directory $dist | Out-Null
[IO.File]::WriteAllText("$dist\NOTES.md", $sec.Value.Trim(), (New-Object Text.UTF8Encoding($false)))

# ---- 3. quality gates -----------------------------------------------------------------
Run 'flutter pub get' { flutter pub get }
Run 'flutter analyze' { flutter analyze --fatal-infos }
Run 'flutter test' { flutter test }
Push-Location "$root\packages\mtc_core"
Run 'mtc_core test' { dart test }
Pop-Location

# ---- 4. builds ----------------------------------------------------------------------------
$defs = @("--build-name=$core", "--build-number=$build", "--dart-define=APP_VERSION=$full")
Run 'build windows' { flutter build windows --release @defs }
Run 'build android' { flutter build apk --release --split-per-abi @defs }

Run 'windows installer' { iscc /Q "/DAppVersion=$full" "/DFileVersion=$core.$build" "/DSourceDir=$root\build\windows\x64\runner\Release" "/DOutputDir=$dist" "$root\installer\mtc_iptv.iss" }
foreach ($abi in 'arm64-v8a', 'armeabi-v7a', 'x86_64') {
  Copy-Item "$root\build\app\outputs\flutter-apk\app-$abi-release.apk" "$dist\MTC-iPTv-$full-android-$abi.apk"
}
$assets = Get-ChildItem $dist -File | Where-Object { $_.Extension -in '.exe', '.apk' }
($assets | Get-FileHash -Algorithm SHA256 | ForEach-Object { "$($_.Hash.ToLower())  $(Split-Path $_.Path -Leaf)" }) -join "`n" |
  Set-Content "$dist\SHA256SUMS.txt" -Encoding ascii
$assets | ForEach-Object { Write-Host ("  {0,-55} {1,6:N1} MB" -f $_.Name, ($_.Length / 1MB)) }

if ($NoPush) { Write-Host "Built locally in $dist (no push)." -ForegroundColor Yellow; return }

# ---- 5. commit, tag, push, publish ------------------------------------------------------
Set-Location $repo
Run 'git add' { git add mtc_iptv/pubspec.yaml mtc_iptv/CHANGELOG.md }
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) { Run 'git commit' { git commit -m "release: MTC-iPTv v$full" } }
Run 'git tag' { git tag -a "v$full" -m "MTC-iPTv v$full" }
Run 'git push' { git push origin HEAD --follow-tags }

$ghArgs = @('release', 'create', "v$full", '--title', "MTC-iPTv $full", '--notes-file', "$dist\NOTES.md")
if (-not $Stable) { $ghArgs += '--prerelease' }   # keeps the live React Native updater (/releases/latest) away from dev builds
$ghArgs += ($assets | ForEach-Object { $_.FullName })
$ghArgs += "$dist\SHA256SUMS.txt"
Run 'gh release' { gh @ghArgs }
Write-Host "Published v$full" -ForegroundColor Green
