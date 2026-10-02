@echo off
rem Starts the virtual Android phone. Double-click to run.
rem Leave this window open while you use the phone; closing it closes the phone.
title CreBa Connect - virtual phone
set "ANDROID_HOME=C:\dev\android-sdk"
echo.
echo   Starting the virtual phone "creba_phone"...
echo   Keep this window open. Close it when you are finished.
echo.
"C:\dev\android-sdk\emulator\emulator.exe" -avd creba_phone -no-boot-anim
