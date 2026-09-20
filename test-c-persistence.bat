@echo off
chcp 65001 >nul
title C Drive Persistence Probe

REM ============================================================
REM  C Drive Persistence Probe
REM
REM  PURPOSE: Test which C drive folders survive reboot.
REM  If ANY C drive location shows [SURVIVED], it means that
REM  folder is NOT protected by the restore card - we can use
REM  it to place an auto-start trigger without thawing.
REM
REM  HOW TO USE:
REM    1. Run this script ON THE CLASSROOM COMPUTER (as admin)
REM    2. It creates test files in 8 locations
REM    3. Reboot the computer
REM    4. Run THIS SAME SCRIPT again
REM    5. Read the [SURVIVED] / [REVERTED] results
REM
REM  MOST IMPORTANT LOCATION: #5 - Startup folder
REM    If it shows [SURVIVED], you can auto-start with NO password!
REM ============================================================

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "TS=%DATE% %TIME%"
set "MARK=C persistence test - created at %TS%"

set "L1=C:\RESTORE_TEST_ROOT.txt"
set "L2=C:\ProgramData\RESTORE_TEST.txt"
set "L3=C:\Users\Public\RESTORE_TEST.txt"
set "L4=C:\Windows\Temp\RESTORE_TEST.txt"
set "L5=C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\RESTORE_TEST.txt"
set "L6=C:\Users\Public\Desktop\RESTORE_TEST.txt"
set "L7=C:\Program Files\RESTORE_TEST.txt"
set "L8=D:\RESTORE_TEST_D.txt"

echo ============================================================
echo   C Drive Persistence Probe
echo ============================================================
echo.

REM Check if markers already exist (second run after reboot)
set "ANY_EXIST=0"
if exist "%L1%" set "ANY_EXIST=1"
if exist "%L2%" set "ANY_EXIST=1"
if exist "%L3%" set "ANY_EXIST=1"
if exist "%L4%" set "ANY_EXIST=1"
if exist "%L5%" set "ANY_EXIST=1"
if exist "%L6%" set "ANY_EXIST=1"
if exist "%L7%" set "ANY_EXIST=1"
if exist "%L8%" set "ANY_EXIST=1"

if "%ANY_EXIST%"=="0" goto :CREATE

REM === STAGE 2: Check which survived ===
echo STAGE 2: Checking which locations survived the reboot...
echo.
echo ------------------------------------------------------------

if exist "%L1%" (
    echo [SURVIVED] C:\
    echo            ^^^ OPEN location - safe for startup trigger
) else (
    echo [REVERTED] C:\
)

if exist "%L2%" (
    echo [SURVIVED] C:\ProgramData\
    echo            ^^^ OPEN location - safe for startup trigger
) else (
    echo [REVERTED] C:\ProgramData\
)

if exist "%L3%" (
    echo [SURVIVED] C:\Users\Public\
    echo            ^^^ OPEN location
) else (
    echo [REVERTED] C:\Users\Public\
)

if exist "%L4%" (
    echo [SURVIVED] C:\Windows\Temp\
    echo            ^^^ Unusual - normally Temp is wiped
) else (
    echo [REVERTED] C:\Windows\Temp\
)

if exist "%L5%" (
    echo [SURVIVED] Startup folder:
    echo   C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\
    echo   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    echo   JACKPOT! Put shortcut here for passwordless auto-start!
    echo   Run install-autostart.bat to set it up.
    echo   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
) else (
    echo [REVERTED] Startup folder
)

if exist "%L6%" (
    echo [SURVIVED] C:\Users\Public\Desktop\
) else (
    echo [REVERTED] C:\Users\Public\Desktop\
)

if exist "%L7%" (
    echo [SURVIVED] C:\Program Files\ (very unusual!)
) else (
    echo [REVERTED] C:\Program Files\
)

if exist "%L8%" (
    echo [SURVIVED] D:\ (expected - D is the open drive)
) else (
    echo [REVERTED] D:\ (BAD - D drive also protected!)
)

echo ------------------------------------------------------------
echo.
echo Cleaning up test markers...
del "%L1%" >nul 2>&1
del "%L2%" >nul 2>&1
del "%L3%" >nul 2>&1
del "%L4%" >nul 2>&1
del "%L5%" >nul 2>&1
del "%L6%" >nul 2>&1
del "%L7%" >nul 2>&1
del "%L8%" >nul 2>&1
echo   Done.
echo.
echo ============================================================
echo   PROBE COMPLETE - Read results above carefully
echo ============================================================
echo.
pause
exit /b

:CREATE
REM === STAGE 1: Create markers ===
echo STAGE 1: Creating test markers in 8 locations...
echo.
echo ------------------------------------------------------------

echo %MARK% > "%L1%" 2>nul && echo   [OK] %L1% || echo   [FAIL] %L1%
echo %MARK% > "%L2%" 2>nul && echo   [OK] %L2% || echo   [FAIL] %L2%
echo %MARK% > "%L3%" 2>nul && echo   [OK] %L3% || echo   [FAIL] %L3%
echo %MARK% > "%L4%" 2>nul && echo   [OK] %L4% || echo   [FAIL] %L4%

if not exist "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp" mkdir "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp" 2>nul
echo %MARK% > "%L5%" 2>nul && echo   [OK] %L5% || echo   [FAIL] %L5%

echo %MARK% > "%L6%" 2>nul && echo   [OK] %L6% || echo   [FAIL] %L6%
echo %MARK% > "%L7%" 2>nul && echo   [OK] %L7% || echo   [FAIL] %L7%
echo %MARK% > "%L8%" 2>nul && echo   [OK] %L8% || echo   [FAIL] %L8%

echo ------------------------------------------------------------
echo.
echo ============================================================
echo   STAGE 1 COMPLETE
echo ============================================================
echo.
echo Markers placed in 8 locations.
echo.
echo NEXT STEP:
echo   1. RESTART the classroom computer NOW.
echo   2. After restart, run THIS SAME SCRIPT again.
echo   3. It will show which locations survived.
echo.
echo The most important one is #5 (Startup folder).
echo If it survives, you can auto-start with NO password!
echo.
pause
