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

# ---- 2b. update signing key (spec 18.3) -----------------------------------------------------
# The private DSA key lives OUTSIDE the repo. The public half is compiled into the app (windows/dsa_pub.pem).
# They must match, or every installed copy would reject all future updates - so check before building.
$dsaKey = if ($env:MTC_DSA_KEY) { $env:MTC_DSA_KEY } else { "$HOME\.mtc-iptv\dsa_priv.pem" }
$env:PATH = "$HOME\scoop\apps\openssl\current\bin;$env:PATH"
if (-not (Test-Path $dsaKey)) { throw "DSA private key not found at $dsaKey (set MTC_DSA_KEY). See docs/runbooks/release.md" }
# (openssl prints "read DSA key" on stderr; Windows PowerShell 5 turns that into a terminating error under Stop)
$ErrorActionPreference = 'Continue'
$pubFromKey = (openssl dsa -in $dsaKey -pubout 2>$null) -join "`n"
$ErrorActionPreference = 'Stop'
$pubInApp = ((Get-Content "$root\windows\dsa_pub.pem") -join "`n").Trim()
if ($pubFromKey.Trim() -ne $pubInApp) { throw 'windows/dsa_pub.pem does not match the private key - refusing to release.' }

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

# Secrets scan (spec 26.1/26.2: no secret keys in the package). The anon key is public by design;
# a service_role JWT or any private key must never ship. Scans the Windows output and every APK entry.
# Patterns require actual key material: TLS libraries contain bare PEM header names, and the Supabase
# SDK contains the 'sb_secret_' prefix constant - neither is a secret.
$secretPatterns = @(
  '-----BEGIN [A-Z ]*PRIVATE KEY-----\r?\n[A-Za-z0-9+/=]{40}',   # PEM private key with body
  'sb_secret_[A-Za-z0-9_-]{20,}',                                # Supabase secret API key
  'service_role',                                                 # plain JWT role claim
  'c2VydmljZV9yb2xl', 'NlcnZpY2Vfcm9sZ', 'zZXJ2aWNlX3JvbG'        # base64 of service_role (3 offsets)
)
function Find-Secrets([byte[]]$bytes, [string]$where) {
  $text = [Text.Encoding]::GetEncoding(28591).GetString($bytes)   # byte-for-byte latin1 view
  foreach ($p in $secretPatterns) { if ([regex]::IsMatch($text, $p)) { throw "SECRET LEAK: /$p/ matched in $where" } }
}
Get-ChildItem "$root\build\windows\x64\runner\Release" -Recurse -File | ForEach-Object { Find-Secrets ([IO.File]::ReadAllBytes($_.FullName)) $_.FullName }
Add-Type -AssemblyName System.IO.Compression.FileSystem
foreach ($apk in Get-ChildItem "$root\build\app\outputs\flutter-apk" -Filter 'app-*-release.apk') {
  $zip = [IO.Compression.ZipFile]::OpenRead($apk.FullName)
  try {
    foreach ($e in $zip.Entries) {
      if ($e.Length -eq 0) { continue }
      $ms = New-Object IO.MemoryStream; $s = $e.Open(); $s.CopyTo($ms); $s.Close()
      Find-Secrets $ms.ToArray() "$($apk.Name)!$($e.FullName)"
    }
  } finally { $zip.Dispose() }
}
Write-Host 'Secrets scan: clean' -ForegroundColor Green

# Android signing (spec 24.6): every APK must carry the official certificate of the React Native app,
# or it could never upgrade it in R2 (and users would have to uninstall).
$officialCert = 'f9e2e0990964ed0639a6de6c3fbcc033d2471112e3de8d13a03a01008bf6c5f7'
$apksigner = Get-ChildItem "$env:ANDROID_HOME\build-tools" -Recurse -Filter apksigner.bat | Sort-Object FullName -Descending | Select-Object -First 1
if (-not $apksigner) { throw 'apksigner not found (ANDROID_HOME/build-tools)' }
$aapt2 = Get-ChildItem "$env:ANDROID_HOME\build-tools" -Recurse -Filter aapt2.exe | Sort-Object FullName -Descending | Select-Object -First 1
if (-not $aapt2) { throw 'aapt2 not found (ANDROID_HOME/build-tools)' }
$ErrorActionPreference = 'Continue'
foreach ($apk in Get-ChildItem "$root\build\app\outputs\flutter-apk" -Filter 'app-*-release.apk') {
  $certOut = (& $apksigner.FullName verify --print-certs $apk.FullName 2>&1 | Out-String)
  $certM = [regex]::Match($certOut, 'certificate SHA-256 digest: ([0-9a-f]{64})')
  if (-not $certM.Success -or $certM.Groups[1].Value -ne $officialCert) {
    $ErrorActionPreference = 'Stop'
    throw "$($apk.Name) is not signed with the official key (got '$($certM.Groups[1].Value)'). Check android/key.properties."
  }
  # Since alpha.26 (owner approval 2026-10-16) the package is the official RN id, so it installs as an update.
  $badging = (& $aapt2.FullName dump badging $apk.FullName 2>&1 | Out-String)
  $pkgM = [regex]::Match($badging, "package: name='([^']+)'")
  if ($pkgM.Groups[1].Value -ne 'com.mtciptv') {
    $ErrorActionPreference = 'Stop'
    throw "$($apk.Name) has package '$($pkgM.Groups[1].Value)', expected com.mtciptv"
  }
}
$ErrorActionPreference = 'Stop'
Write-Host 'Android signing: official certificate, package com.mtciptv' -ForegroundColor Green

Run 'windows installer' { iscc /Q "/DAppVersion=$full" "/DFileVersion=$core.$build" "/DSourceDir=$root\build\windows\x64\runner\Release" "/DOutputDir=$dist" "$root\installer\mtc_iptv.iss" }
foreach ($abi in 'arm64-v8a', 'armeabi-v7a', 'x86_64') {
  Copy-Item "$root\build\app\outputs\flutter-apk\app-$abi-release.apk" "$dist\MTC-iPTv-$full-android-$abi.apk"
}
# DSA signature of the Windows installer for WinSparkle (Defender may briefly lock a fresh .exe: retry)
$setup = "$dist\MTC-iPTv-$full-windows-setup.exe"
$ErrorActionPreference = 'Continue'
for ($i = 1; $i -le 6; $i++) {
  $sigOut = (dart run auto_updater:sign_update $setup $dsaKey 2>&1 | Out-String)
  $sigM = [regex]::Match($sigOut, 'sparkle:dsaSignature="([^"]+)"')
  if ($sigM.Success) { break }
  Write-Host "sign attempt $i failed, retrying..."
  Start-Sleep -Seconds 3
}
if (-not $sigM.Success) { throw "DSA signing failed: $sigOut" }
$dsaSig = $sigM.Groups[1].Value
# self-check: the signature must verify with the public key shipped in the app
$tmpSig = [IO.Path]::GetTempFileName(); $tmpDig = [IO.Path]::GetTempFileName()
[IO.File]::WriteAllBytes($tmpSig, [Convert]::FromBase64String($dsaSig))
$sha1 = [Security.Cryptography.SHA1]::Create().ComputeHash([IO.File]::ReadAllBytes($setup))
[IO.File]::WriteAllBytes($tmpDig, $sha1)
$verify = (openssl dgst -sha1 -verify "$root\windows\dsa_pub.pem" -signature $tmpSig $tmpDig 2>&1 | Out-String)
$ErrorActionPreference = 'Stop'
Remove-Item $tmpSig, $tmpDig
if ($verify -notmatch 'Verified OK') { throw "DSA signature does not verify with windows/dsa_pub.pem: $verify" }
Write-Host 'DSA signature: Verified OK' -ForegroundColor Green

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
# Display label per file with the target system in parentheses (owner request 2026-10-17).
# The file names stay unchanged: the Android in-app updater matches "-android-<abi>.apk".
function AssetLabel($name) {
  if ($name -like '*-windows-setup.exe') { return "MTC-iPTv $full (Windows - installer)" }
  if ($name -like '*-android-arm64-v8a.apk') { return "MTC-iPTv $full (Android ARM64 - most phones)" }
  if ($name -like '*-android-armeabi-v7a.apk') { return "MTC-iPTv $full (Android ARMv7 - older phones)" }
  if ($name -like '*-android-x86_64.apk') { return "MTC-iPTv $full (Android x86_64 - emulators / TV boxes)" }
  return $name
}
$ghArgs += ($assets | ForEach-Object { "$($_.FullName)#$(AssetLabel $_.Name)" })
$ghArgs += "$dist\SHA256SUMS.txt#SHA256SUMS (file checksums)"
Run 'gh release' { gh @ghArgs }
Write-Host "Published v$full" -ForegroundColor Green

# ---- 6. appcast (only after the installer is downloadable) ------------------------------------
# Served by GitHub Pages from the repo root: https://aneesadwan.github.io/MTC-iPTv/updates/windows-<channel>.xml
# sparkle:version = the exe's own version string (build-name+build-number), which WinSparkle compares.
# NO sparkle:minimumSystemVersion: WinSparkle 0.8.1 misreads the Windows version, so with it every client
# answered "you're up to date" (tested 2026-10-16: same feed with/without it). The installer's
# MinVersion=10.0.19044 already blocks unsupported Windows.
$channel = if ($Stable) { 'stable' } else { $tag }
$feedDir = "$repo\updates"
New-Item -ItemType Directory -Force $feedDir | Out-Null
$setupName = Split-Path $setup -Leaf
$notesHtml = [Net.WebUtility]::HtmlEncode($sec.Value.Trim()) -replace "`r?`n", '<br/>'
$date = (Get-Date).ToUniversalTime().ToString('r')
@"
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>MTC-iPTv ($channel)</title>
    <item>
      <title>MTC-iPTv $full</title>
      <description><![CDATA[<div dir="rtl">$notesHtml</div>]]></description>
      <pubDate>$date</pubDate>
      <enclosure url="https://github.com/AneesAdwan/MTC-iPTv/releases/download/v$full/$setupName"
                 sparkle:version="$core+$build"
                 sparkle:shortVersionString="$full"
                 sparkle:os="windows"
                 sparkle:dsaSignature="$dsaSig"
                 length="$((Get-Item $setup).Length)"
                 type="application/octet-stream" />
    </item>
  </channel>
</rss>
"@ | ForEach-Object { [IO.File]::WriteAllText("$feedDir\windows-$channel.xml", $_, (New-Object Text.UTF8Encoding($false))) }   # UTF-8 without BOM
# Same data for the download page (download/index.html): version, link, size and SHA-256 of the installer
$setupHash = (Get-FileHash $setup -Algorithm SHA256).Hash.ToLower()
[ordered]@{
  version = $full; channel = $channel; date = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd')
  url = "https://github.com/AneesAdwan/MTC-iPTv/releases/download/v$full/$setupName"
  size = (Get-Item $setup).Length; sha256 = $setupHash
  notes = "https://github.com/AneesAdwan/MTC-iPTv/releases/tag/v$full"
} | ConvertTo-Json | Set-Content "$feedDir\latest-windows-$channel.json" -Encoding ascii
Run 'git add appcast' { git add "updates/windows-$channel.xml" "updates/latest-windows-$channel.json" }
Run 'git commit appcast' { git commit -m "updates: windows-$channel appcast v$full" }
Run 'git push appcast' { git push origin HEAD }
Write-Host "Appcast: https://aneesadwan.github.io/MTC-iPTv/updates/windows-$channel.xml" -ForegroundColor Green
