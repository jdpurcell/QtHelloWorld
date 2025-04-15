$qtVersion = [version](qmake -query QT_VERSION)
Write-Host "Detected Qt version $qtVersion"

if ($IsWindows) {
    switch ($env:buildArch) {
        'X64' {
            $argArch = 'x64'
            $argComponent = 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64'
        }
        'Arm64' {
            $argArch = 'arm64'
            $argComponent = 'Microsoft.VisualStudio.Component.VC.Tools.ARM64'
        }
        default { throw 'Unsupported build architecture.' }
    }
    $vsDir = vswhere -latest -products * -requires $argComponent -property installationPath
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
} else {
    make
}

Set-Location "build"
$appName = "QtHelloWorld"

if ($IsWindows) {
    windeployqt --no-compiler-runtime --no-translations --no-system-d3d-compiler --no-system-dxc-compiler --no-opengl-sw "$appName.exe"
} elseif ($IsMacOS) {
    macdeployqt "$appName.app"

    codesign --sign "-" --deep --force "$appName.app"

    hdiutil create -srcfolder "$appName.app" -volname "$appName" -format UDSB "temp.sparsebundle"
    hdiutil convert "temp.sparsebundle" -format ULFO -o "$appName.dmg"
    Remove-Item -Recurse "temp.sparsebundle"
    Remove-Item -Recurse "$appName.app"
} elseif ($IsLinux) {
    sudo apt update
    sudo apt install libfuse2

    $archName = switch ($env:buildArch) {
        'X64' { 'x86_64' }
        'Arm64' { 'aarch64' }
        default { throw 'Unsupported build architecture.' }
    }

    Invoke-WebRequest -Uri "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-$archName.AppImage" -OutFile "../linuxdeploy-$archName.AppImage"
    Invoke-WebRequest -Uri "https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-$archName.AppImage" -OutFile "../linuxdeploy-plugin-qt-$archName.AppImage"
    chmod +x "../linuxdeploy-$archName.AppImage"
    chmod +x "../linuxdeploy-plugin-qt-$archName.AppImage"

    & "../linuxdeploy-$archName.AppImage" `
        --appdir "AppDir" `
        --executable "$appName" `
        --create-desktop-file `
        --icon-file "$env:GITHUB_WORKSPACE/dist/app-generic.svg" `
        --icon-filename "$appName" `
        --plugin qt `
        --output appimage

    Remove-Item -Recurse "AppDir" -Force
    Remove-Item $appName
}
