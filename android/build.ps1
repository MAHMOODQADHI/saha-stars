# Builds njoom-almalab.apk from ../njoom-almalab.html and ../voice without Gradle,
# using the Android SDK build-tools directly. Run from anywhere:  powershell -File android\build.ps1
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $here
$sdk = $env:ANDROID_HOME; if (-not $sdk) { $sdk = "$env:LOCALAPPDATA\Android\Sdk" }
$bt = Get-ChildItem "$sdk\build-tools" -Directory | Sort-Object { [version]($_.Name -replace '[^0-9.]', '') } | Select-Object -Last 1 -ExpandProperty FullName
$platform = Get-ChildItem "$sdk\platforms" -Directory | Sort-Object Name | Select-Object -Last 1 -ExpandProperty FullName
$androidJar = "$platform\android.jar"
$jdk = $env:JAVA_HOME
Write-Host "build-tools: $bt"; Write-Host "platform:    $platform"; Write-Host "jdk:         $jdk"

$b = "$here\build"
if (Test-Path $b) { Remove-Item -Recurse -Force $b }
New-Item -ItemType Directory -Force "$b\assets\www\voice", "$b\gen", "$b\classes", "$b\dex" | Out-Null

function Run($exe, [string[]]$a) {
    & $exe @a
    if ($LASTEXITCODE -ne 0) { throw "$([IO.Path]::GetFileName($exe)) failed with exit code $LASTEXITCODE" }
}

# 1. game page + the app shim (phone text-to-speech bridge), and the voice clips
$html = [IO.File]::ReadAllText("$root\njoom-almalab.html", [Text.Encoding]::UTF8)
$shim = [IO.File]::ReadAllText("$here\app-shim.js", [Text.Encoding]::UTF8)
$marker = '<meta charset="utf-8">'
if (-not $html.StartsWith($marker)) { throw "expected the game file to start with $marker" }
$html = $marker + "`n<script>" + $shim + "</script>" + $html.Substring($marker.Length)
[IO.File]::WriteAllText("$b\assets\www\index.html", $html, (New-Object Text.UTF8Encoding $false))
if (Test-Path "$root\voice") { Copy-Item "$root\voice\*" "$b\assets\www\voice\" }

# 2. resources + manifest
Run "$bt\aapt2.exe" @('compile', '--dir', "$here\res", '-o', "$b\res.zip")
Run "$bt\aapt2.exe" @('link', '-o', "$b\base.apk", '-I', $androidJar, '--manifest', "$here\AndroidManifest.xml",
    "$b\res.zip", '--java', "$b\gen", '--auto-add-overlay')

# 3. java -> dex
$srcs = @(Get-ChildItem "$here\src", "$b\gen" -Recurse -Filter *.java | ForEach-Object FullName)
Run "$jdk\bin\javac.exe" (@('-encoding', 'UTF-8', '-source', '11', '-target', '11', '-Xlint:-options', '-nowarn',
    '-classpath', $androidJar, '-d', "$b\classes") + $srcs)
$classes = @(Get-ChildItem "$b\classes" -Recurse -Filter *.class | ForEach-Object FullName)
Run "$bt\d8.bat" (@('--release', '--lib', $androidJar, '--min-api', '24', '--output', "$b\dex") + $classes)

# 4. add classes.dex and the assets (zip entry names must use "/", which aapt2 -A on Windows does not do)
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::Open("$b\base.apk", 'Update')
[void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, "$b\dex\classes.dex", 'classes.dex', 'Optimal')
$assetRoot = (Resolve-Path "$b\assets").Path
Get-ChildItem $assetRoot -Recurse -File | ForEach-Object {
    $name = 'assets/' + $_.FullName.Substring($assetRoot.Length + 1).Replace('\', '/')
    $level = if ($_.Extension -match '^\.(mp4|m4a|mp3|ogg|wav|png|jpg|webp)$') { 'NoCompression' } else { 'Optimal' }
    [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $name, $level)
}
$zip.Dispose()

# 5. align + sign (the key lives next to this script; keep it to publish updates over this install)
Run "$bt\zipalign.exe" @('-p', '-f', '4', "$b\base.apk", "$b\aligned.apk")
$ks = "$here\njoom-release.jks"; $pwFile = "$here\keystore-password.txt"
if (-not (Test-Path $ks)) {
    $pw = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 24 | ForEach-Object { [char]$_ })
    [IO.File]::WriteAllText($pwFile, $pw)
    Run "$jdk\bin\keytool.exe" @('-genkeypair', '-keystore', $ks, '-alias', 'njoom', '-keyalg', 'RSA', '-keysize', '2048',
        '-validity', '10000', '-storepass', $pw, '-keypass', $pw, '-dname', 'CN=Njoom Almalab')
}
$pw = [IO.File]::ReadAllText($pwFile).Trim()
$out = "$root\njoom-almalab.apk"
Run "$bt\apksigner.bat" @('sign', '--ks', $ks, '--ks-key-alias', 'njoom', '--ks-pass', "pass:$pw", '--key-pass', "pass:$pw",
    '--out', $out, "$b\aligned.apk")
Run "$bt\apksigner.bat" @('verify', '--verbose', $out)
Write-Host ("APK: {0} ({1:N0} KB)" -f $out, ((Get-Item $out).Length / 1KB))
