@echo off
echo ========================================
echo SAMS App APK Builder
echo ========================================
echo.

cd /d "%~dp0frontend"

echo [1/4] Checking Flutter installation...
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Flutter not found in PATH!
    echo.
    echo Please add Flutter to your PATH or run this from Android Studio terminal.
    echo Common Flutter locations:
    echo   - C:\flutter\bin
    echo   - C:\src\flutter\bin
    echo   - %LOCALAPPDATA%\Android\Sdk\flutter\bin
    echo.
    pause
    exit /b 1
)

echo Flutter found!
flutter --version
echo.

echo [2/4] Getting dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Failed to get dependencies!
    pause
    exit /b 1
)
echo.

echo [3/4] Building APK (this may take 3-5 minutes)...
call flutter build apk --release
if %errorlevel% neq 0 (
    echo ERROR: Build failed!
    pause
    exit /b 1
)
echo.

echo [4/4] Copying APK to Desktop and Google Drive...
set DESKTOP=%USERPROFILE%\OneDrive\OneDrive - ump.edu.my\Desktop
if not exist "%DESKTOP%" set DESKTOP=%USERPROFILE%\Desktop
set GDRIVE=G:\My Drive

copy /Y "build\app\outputs\flutter-apk\app-release.apk" "%DESKTOP%\sams-app.apk"
if %errorlevel% neq 0 (
    echo WARNING: Failed to copy to Desktop
    echo APK location: %CD%\build\app\outputs\flutter-apk\app-release.apk
) else (
    echo SUCCESS! APK copied to: %DESKTOP%\sams-app.apk
)

if exist "%GDRIVE%" (
    echo.
    echo Uploading to Google Drive...
    copy /Y "build\app\outputs\flutter-apk\app-release.apk" "%GDRIVE%\sams-app-release.apk"
    if %errorlevel% equ 0 (
        echo SUCCESS! APK uploaded to: %GDRIVE%\sams-app-release.apk
    ) else (
        echo WARNING: Failed to upload to Google Drive
    )
) else (
    echo Google Drive not mounted at G:\My Drive - skipping upload
)
echo.

echo ========================================
echo BUILD COMPLETE!
echo ========================================
echo APK Size:
dir "%DESKTOP%\sams-app.apk" 2>nul || dir "build\app\outputs\flutter-apk\app-release.apk"
echo.
pause
