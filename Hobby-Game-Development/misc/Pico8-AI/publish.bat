@echo off
REM publish.bat - for every games\<name>\game.p8:
REM   1. export the cart image     -> publish\<name>.p8.png
REM   2. render the cart label     -> images\<name>.png
REM   3. export the web build      -> html\<name>.zip  (index.html + index.js)
REM
REM   publish                 everything, label PNGs at 128x128
REM   publish --scale 4       label PNGs at 512x512
REM   publish --only stone,triad
REM   publish --no-html       skip the web builds (they are the slow part)
REM   publish --no-export --no-images
setlocal
cd /d "%~dp0"
node publish-all.js %*
if errorlevel 1 (
  echo.
  echo Publish finished with errors.
  exit /b 1
)
