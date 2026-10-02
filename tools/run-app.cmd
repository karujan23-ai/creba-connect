@echo off
rem Builds the app and runs it on the connected phone or the virtual phone.
rem Double-click to run. Start the virtual phone first (start-phone.cmd),
rem or plug in an Android phone with USB debugging switched on.
title CreBa Connect - run app
cd /d "%~dp0.."
set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
set "ANDROID_HOME=C:\dev\android-sdk"
set "PUB_CACHE=C:\dev\pub-cache"
set "PATH=C:\Program Files\Git\cmd;C:\dev\flutter\bin;C:\dev\android-sdk\platform-tools;%PATH%"
echo.
echo   Running CreBa Connect. The first build takes a few minutes.
echo   While it runs: press r to reload after a code change, q to quit.
echo.
call flutter run
pause
