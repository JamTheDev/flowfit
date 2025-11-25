@echo off
echo ========================================
echo Testing Watch App on Galaxy Watch
echo ========================================
echo.

echo Building and installing on watch (SM_R930)...
flutter run -d adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp -t lib/main_wear.dart --release

echo.
echo ========================================
echo Watch app deployed!
echo ========================================
