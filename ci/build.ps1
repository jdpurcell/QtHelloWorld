$qtVersion = [version](qmake -query QT_VERSION)
Write-Host "Detected Qt version $qtVersion"

if ($IsWindows) {
    $argArch =
        $env:buildArch -eq 'X64' ? 'x64' :
        $env:buildArch -eq 'Arm64' ? 'x64_arm64' :
        $null
    if (-not $argArch) {
        throw 'Unsupported build architecture.'
    }
    $vsDir = vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    cmd /c "`"$(Join-Path $vsDir 'VC\Auxiliary\Build\vcvarsall.bat')`" $argArch > null && set" | ForEach-Object {
        $name, $value = $_ -Split '=', 2
        [Environment]::SetEnvironmentVariable($name, $value)
    }
}

if ($IsMacOS) {
    $argDeviceArchs =
        $env:buildArch -eq 'X64' ? 'QMAKE_APPLE_DEVICE_ARCHS=x86_64' :
        $env:buildArch -eq 'Arm64' ? 'QMAKE_APPLE_DEVICE_ARCHS=arm64' :
        $env:buildArch -eq 'Universal' ? 'QMAKE_APPLE_DEVICE_ARCHS=x86_64 arm64' :
        $null
    if (-not $argDeviceArchs) {
        throw 'Unsupported build architecture.'
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
    if ($env:buildArch -eq 'Arm64') {
        $winDeployQt = "$env:QT_HOST_PATH\bin\windeployqt"
        $argTargetQtScript = $qtVersion -ge [version]'6.3.0' ?
            "--qtpaths=$env:QT_ROOT_DIR\bin\qtpaths.bat" :
            "--qmake=$env:QT_ROOT_DIR\bin\qmake.bat"
    } else {
        $winDeployQt = "windeployqt"
    }
    $argNoDxcComp = $qtVersion -ge [version]'6.7.0' ? "--no-system-dxc-compiler" : $null
    & $winDeployQt $argTargetQtScript --no-compiler-runtime --no-translations --no-system-d3d-compiler $argNoDxcComp --no-opengl-sw "$appName.exe"
} elseif ($IsMacOS) {
    macdeployqt "$appName.app"

    codesign --sign "-" --deep --force "$appName.app"

    hdiutil create -srcfolder "$appName.app" -volname "$appName" -format UDSB "temp.sparsebundle"
    hdiutil convert "temp.sparsebundle" -format ULFO -o "$appName.dmg"
    Remove-Item -Recurse "temp.sparsebundle"
    Remove-Item -Recurse "$appName.app"
}
