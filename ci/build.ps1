$qtVersion = [version](qmake -query QT_VERSION)
Write-Host "Detected Qt version $qtVersion"

if ($IsWindows) {
    if ($env:buildArch -eq 'Arm64') {
        $env:QT_HOST_PATH = (qmake -query QT_HOST_PREFIX)
    }

    $argArch = switch ($env:buildArch) {
        'X64' { 'x64' }
        'Arm64' { 'x64_arm64' }
        default { throw 'Unsupported build architecture.' }
    }
    $vsDir = vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    cmd /c "`"$(Join-Path $vsDir 'VC\Auxiliary\Build\vcvarsall.bat')`" $argArch > null && set" | ForEach-Object {
        $name, $value = $_ -Split '=', 2
        [Environment]::SetEnvironmentVariable($name, $value)
    }
}

if ($IsMacOS) {
    $argDeviceArchs = switch ($env:buildArch) {
        'X64' { 'QMAKE_APPLE_DEVICE_ARCHS=x86_64' }
        'Arm64' { 'QMAKE_APPLE_DEVICE_ARCHS=arm64' }
        'Universal' { 'QMAKE_APPLE_DEVICE_ARCHS=x86_64 arm64' }
        default { throw 'Unsupported build architecture.' }
    }
}
qmake DESTDIR="build" $argDeviceArchs

if ($IsWindows) {
    nmake
} elseif ($IsMacOS) {
    make
}

Set-Location "build"
$appName = "QtHelloWorld"

if ($IsWindows) {
    $isCrossCompile = $env:buildArch -eq 'Arm64'
    $winDeployQt = $isCrossCompile ? "$env:QT_HOST_PATH\bin\windeployqt" : "windeployqt"
    $argQmake = $isCrossCompile ? "--qmake=$env:QT_ROOT_DIR\bin\qmake.bat" : $null
    & $winDeployQt $argQmake --no-compiler-runtime --no-translations --no-system-d3d-compiler --no-system-dxc-compiler --no-opengl-sw "$appName.exe"
} elseif ($IsMacOS) {
    macdeployqt "$appName.app"

    codesign --sign "-" --deep --force "$appName.app"

    hdiutil create -srcfolder "$appName.app" -volname "$appName" -format UDSB "temp.sparsebundle"
    hdiutil convert "temp.sparsebundle" -format ULFO -o "$appName.dmg"
    Remove-Item -Recurse "temp.sparsebundle"
    Remove-Item -Recurse "$appName.app"
}
