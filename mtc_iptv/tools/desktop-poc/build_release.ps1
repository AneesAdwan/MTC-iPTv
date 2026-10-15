# Phase 0 updater PoC: builds two versions (1.0.0 and 1.0.1), packages each with Inno Setup,
# signs 1.0.1 with the DSA private key and writes dist\appcast.xml for WinSparkle.
# Then serves dist\ on http://127.0.0.1:8793 so an installed 1.0.0 can find and install 1.0.1.
# Usage: powershell -ExecutionPolicy Bypass -File build_release.ps1 [-Serve]
param([switch]$Serve)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$env:PATH = "$HOME\scoop\apps\flutter\current\bin;$HOME\scoop\apps\openssl\current\bin;$HOME\scoop\shims;$env:PATH"
Set-Location $here
New-Item -ItemType Directory -Force dist | Out-Null

# NOTE: every command output inside a PowerShell function becomes part of its return value,
# so all tool output is sent to Out-Host and only the installer path is returned.
function Build($ver, $build) {
  flutter build windows --release --build-name=$ver --build-number=$build --dart-define=APP_VERSION=$ver | Out-Host
  if ($LASTEXITCODE -ne 0) { throw "flutter build $ver failed" }
  $stage = "dist\stage-$ver"
  if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
  Copy-Item build\windows\x64\runner\Release $stage -Recurse | Out-Null
  iscc /Q "/DAppVersion=$ver" "/DSourceDir=$here\$stage" installer.iss | Out-Host
  if ($LASTEXITCODE -ne 0) { throw "iscc $ver failed" }
  Remove-Item $stage -Recurse -Force
  return "dist\mtc-desktop-poc-$ver-setup.exe"
}

$old = Build '1.0.0' 1
$new = Build '1.0.1' 2

# Sign the new installer (DSA, as required by WinSparkle via auto_updater on Windows)
# (stderr warnings from dart must not abort the script; sign_update also prints length="0", so we take
#  only the signature and write the real file length ourselves)
#  Retries: Windows Defender briefly locks a freshly written .exe while scanning it.
$ErrorActionPreference = 'Continue'
for ($i = 1; $i -le 6; $i++) {
  Start-Sleep -Seconds 3
  $out = (dart run auto_updater:sign_update $new 2>&1 | Out-String)
  $m = [regex]::Match($out, 'sparkle:dsaSignature="([^"]+)"')
  if ($m.Success) { break }
  Write-Host "sign attempt $i failed, retrying..."
}
$ErrorActionPreference = 'Stop'
if (-not $m.Success) { throw "signing failed: $out" }
$len = (Get-Item $new).Length
$sig = "sparkle:dsaSignature=""$($m.Groups[1].Value)"" length=""$len"""
$name = Split-Path $new -Leaf
$date = (Get-Date).ToUniversalTime().ToString('r')
@"
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>MTC-iPTv PoC</title>
    <item>
      <title>Version 1.0.1</title>
      <description><![CDATA[<h3>1.0.1</h3><ul><li>Phase 0 update test</li></ul>]]></description>
      <pubDate>$date</pubDate>
      <enclosure url="http://127.0.0.1:8793/$name"
                 sparkle:version="1.0.1+2"
                 sparkle:os="windows"
                 $sig
                 type="application/octet-stream" />
    </item>
  </channel>
</rss>
"@ | Set-Content dist\appcast.xml -Encoding utf8

Get-FileHash $old, $new -Algorithm SHA256 | ForEach-Object { "$($_.Hash)  $(Split-Path $_.Path -Leaf)" } | Set-Content dist\SHA256SUMS.txt
Write-Host "Built: $old , $new  (appcast + SHA256SUMS in dist\)"

if ($Serve) {
  $py = (Get-Command python -ErrorAction SilentlyContinue).Source
  if (-not $py) { $py = 'C:\laragon\bin\python\python-3.13\python.exe' }
  Write-Host 'Serving dist\ on http://127.0.0.1:8793  (Ctrl+C to stop)'
  & $py -m http.server 8793 --bind 127.0.0.1 --directory dist
}
