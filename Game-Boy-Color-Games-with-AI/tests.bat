@echo off
setlocal enabledelayedexpansion
rem Runs the engine unit tests (tests/engine, GBDK + headless emulator). Needs Node 18+.
chcp 65001 >nul
cd /d "%~dp0"
set "LOGDIR=build\tests"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
set "ENGINE_LOG=%LOGDIR%\engine.log"
set /a EP=0, EF=0
set "ERRORS="

where node >nul 2>&1 || (
  echo ERROR: node not found in PATH
  set "ERRORS=node not found"
  goto :summary
)

echo ============================================================
echo  Engine tests  (tests\engine, builds one ROM per suite...)
echo ============================================================
node tests\engine\run.mjs > "%ENGINE_LOG%" 2>&1
type "%ENGINE_LOG%"
set "ENGINE_OK="
for /f "tokens=1,3" %%a in ('findstr /r /c:"^[0-9][0-9]* passed, [0-9][0-9]* failed" "%ENGINE_LOG%"') do (
  set /a EP=%%a, EF=%%b
  set "ENGINE_OK=1"
)
if not defined ENGINE_OK set "ERRORS=!ERRORS! [engine tests did not run: see output above]"

:summary
set /a PASS=EP, FAIL=EF, TOTAL=PASS+FAIL
echo.
echo ============================================================
echo  RESULTS
echo ============================================================
echo  Engine : !EP! passed, !EF! failed
echo  ------------------------------------------------------------
echo  Total  : !TOTAL!   Pass: !PASS!   Fail: !FAIL!
if defined ERRORS echo  ERROR  :!ERRORS!
echo.
if "!FAIL!"=="0" if not defined ERRORS (
  echo  ALL TESTS PASSED
  set "RC=0"
  goto :end
)
echo  SOME TESTS FAILED  (failure messages are listed above, under each suite)
set "RC=1"
:end
echo.
set /p "DUMMY=Press Enter to close..."
exit /b %RC%
