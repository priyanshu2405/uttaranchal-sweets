@echo off
REM One-time setup for Windows (builds Android only - iOS needs a Mac).
cd /d "%~dp0"
where flutter >nul 2>nul || (echo Flutter is not installed or not on PATH. See README.md & exit /b 1)

echo Generating android/ and ios/ ...
call flutter create . --project-name uttaranchal_app --org com.uttaranchal.dairy --platforms=android,ios || exit /b 1

echo Fetching packages ...
call flutter pub get || exit /b 1

powershell -NoProfile -Command "(Get-Content android/app/src/main/AndroidManifest.xml) -replace 'android:label=\"[^\"]*\"','android:label=\"Uttaranchal\"' ^| Set-Content android/app/src/main/AndroidManifest.xml"

echo Generating launcher icons and splash screen ...
call dart run flutter_launcher_icons || exit /b 1
call dart run flutter_native_splash:create || exit /b 1

echo.
echo Done. Connect an Android phone (USB debugging on) or start an emulator, then run:
echo     flutter run --release
