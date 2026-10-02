@echo off
rem Uploads this project to GitHub. Double-click to run.
rem
rem Before running: create an EMPTY repository named "creba-connect" at
rem https://github.com/new (do not tick "Add a README").
title CreBa Connect - push to GitHub
cd /d "%~dp0.."
set "PATH=C:\Program Files\Git\cmd;%PATH%"

git remote remove origin 2>nul
git remote add origin https://github.com/karujan23-ai/creba-connect.git
echo.
echo   Uploading to https://github.com/karujan23-ai/creba-connect
echo   A browser window may open asking you to sign in to GitHub.
echo.
git push -u origin main
echo.
pause
