@echo off
rem Signs this computer in to Firebase. Double-click to run.
rem Needed once, so that security rules can be deployed from this machine.
title CreBa Connect - Firebase sign-in
set "PATH=C:\Program Files\nodejs;C:\dev\npm-global;%PATH%"
echo.
echo   FIREBASE SIGN-IN FOR CREBA CONNECT
echo   ----------------------------------
echo   1) For each question below, type n and press Enter.
echo   2) Your browser opens: pick your Google account and click Allow.
echo   3) When this window says "Success", go back to Claude.
echo.
call firebase login
echo.
echo   Finished. You can close this window.
pause
