@echo off
set FLUTTER_DIR=e:\flutter

if not exist "%FLUTTER_DIR%\bin\flutter.bat" (
    echo Flutter SDK not found at %FLUTTER_DIR%.
    echo Downloading and Installing Flutter SDK...
    git clone -b stable https://github.com/flutter/flutter.git "%FLUTTER_DIR%"
)

echo Adding Flutter to PATH for this session...
set PATH=%FLUTTER_DIR%\bin;%PATH%

echo Setting up Flutter SDK...
call flutter config --enable-web

echo Running Flutter app in Chrome...
cd /d "%~dp0"
call flutter run -d chrome
pause
