@echo off
echo ========================================
echo Testing Phone App
echo ========================================
echo.

echo Building and installing on phone (22101320G)...
flutter run -d 6ece264d -t lib/main.dart --release

echo.
echo ========================================
echo Phone app deployed!
echo ========================================
