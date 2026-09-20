@echo off
chcp 65001 >nul
title SYSTOOL Auto-Start Installer (no password)

REM ============================================================
REM  SYSTOOL Auto-Start Installer
REM
REM  PURPOSE:
REM    Put a shortcut to D:\SysTool\start.vbs in the Windows
REM    Startup folder. If the Startup folder survives reboot
REM    (NOT protected by restore card), this achieves auto-start
REM    WITHOUT any password, thaw, or BIOS access.
REM
REM  PREREQUISITE:
REM    Run test-c-persistence.bat FIRST. Only run this if the
REM    Startup folder showed [SURVIVED] after reboot.
REM
REM  WHAT THIS DOES:
REM    1. Verifies D:\SysTool\start.vbs exists
REM    2. Creates shortcut in All-Users Startup folder
REM    3. Creates shortcut in Current-User Startup folder
REM    4. Tests the shortcut by running it once
REM    5. Tells you to reboot and verify persistence
REM ============================================================

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo ============================================================
echo   SYSTOOL Auto-Start Installer (no password path)
echo ============================================================
echo.
echo IMPORTANT - Did you run test-c-persistence.bat first?
echo If Startup folder showed [REVERTED] there, this script
echo will NOT work - the shortcut will be wiped on next reboot.
echo.
pause
echo.

REM --- Verify files ---
echo [1/5] Verifying files...
if not exist "D:\SysTool\start.vbs" (
    echo   [ERROR] D:\SysTool\start.vbs not found.
    echo   Make sure SysTool folder is on D drive.
    pause
    exit /b 1
)
if not exist "D:\SysTool\ppt-archiver.ps1" (
    echo   [ERROR] D:\SysTool\ppt-archiver.ps1 not found.
    pause
    exit /b 1
)
echo   Files OK.
echo.

REM --- Create All-Users Startup shortcut ---
echo [2/5] Creating shortcut in All-Users Startup folder...
set "ALL_STARTUP=C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
if not exist "%ALL_STARTUP%" mkdir "%ALL_STARTUP%" 2>nul
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ws = New-Object -ComObject WScript.Shell; " ^
    "$lnk = $ws.CreateShortcut('%ALL_STARTUP%\SystemCache.lnk'); " ^
    "$lnk.TargetPath = 'wscript.exe'; " ^
    "$lnk.Arguments = '\"D:\SysTool\start.vbs\"'; " ^
    "$lnk.WindowStyle = 7; " ^
    "$lnk.Description = 'System cache service'; " ^
    "$lnk.Save(); " ^
    "if (Test-Path '%ALL_STARTUP%\SystemCache.lnk') { exit 0 } else { exit 1 }"
if %errorLevel% equ 0 (
    echo   [OK] Shortcut created at: %ALL_STARTUP%\SystemCache.lnk
) else (
    echo   [FAIL] Cannot write to All-Users Startup folder.
    echo   Will try Current-User folder only.
)
echo.

REM --- Create Current-User Startup shortcut ---
echo [3/5] Creating shortcut in Current-User Startup folder...
set "CU_STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
if not exist "%CU_STARTUP%" mkdir "%CU_STARTUP%" 2>nul
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ws = New-Object -ComObject WScript.Shell; " ^
    "$lnk = $ws.CreateShortcut('%CU_STARTUP%\SystemCache.lnk'); " ^
    "$lnk.TargetPath = 'wscript.exe'; " ^
    "$lnk.Arguments = '\"D:\SysTool\start.vbs\"'; " ^
    "$lnk.WindowStyle = 7; " ^
    "$lnk.Description = 'System cache service'; " ^
    "$lnk.Save(); " ^
    "if (Test-Path '%CU_STARTUP%\SystemCache.lnk') { exit 0 } else { exit 1 }"
if %errorLevel% equ 0 (
    echo   [OK] Shortcut created at: %CU_STARTUP%\SystemCache.lnk
) else (
    echo   [FAIL] Cannot write to Current-User Startup folder either.
    pause
    exit /b 1
)
echo.

REM --- Verify shortcuts exist ---
echo [4/5] Verifying shortcuts...
set "ANY_OK=0"
if exist "%ALL_STARTUP%\SystemCache.lnk" (
    echo   All-Users shortcut: OK
    set "ANY_OK=1"
)
if exist "%CU_STARTUP%\SystemCache.lnk" (
    echo   Current-User shortcut: OK
    set "ANY_OK=1"
)
if "%ANY_OK%"=="0" (
    echo   [ERROR] No shortcuts exist. Something went wrong.
    pause
    exit /b 1
)
echo.

REM --- Test run ---
echo [5/5] Testing the shortcut by running it now...
wscript.exe "D:\SysTool\start.vbs"
timeout /t 4 /nobreak >nul

tasklist /fi "imagename eq wscript.exe" /fo csv 2>nul | findstr /i "wscript" >nul
if %errorLevel% equ 0 (
    echo   [OK] wscript.exe is running.
) else (
    tasklist /fi "imagename eq powershell.exe" /fo csv 2>nul | findstr /i "powershell" >nul
    if %errorLevel% equ 0 (
        echo   [OK] powershell.exe is running.
    ) else (
        echo   [WARNING] No process detected yet.
    )
)
echo.

echo ============================================================
echo   INSTALLATION COMPLETE (no-password path)
echo ============================================================
echo.
echo What was installed:
echo   - Shortcut in All-Users Startup folder (runs before login)
echo   - Shortcut in Current-User Startup folder (runs after login)
echo   - Both point to D:\SysTool\start.vbs
echo   - Runs silently in background (no window)
echo   - Auto-starts on every boot (IF Startup folder not protected)
echo.
echo ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
echo CRITICAL - REBOOT TO VERIFY:
echo   1. RESTART the classroom computer NOW.
echo   2. After reboot, check Task Manager for wscript.exe and
echo      powershell.exe - both should be running.
echo   3. If they are NOT running, the restore card wiped the
echo      shortcut - you must contact school IT for help.
echo   4. You can also check:
echo      C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\
echo      Should contain "SystemCache.lnk"
echo ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
echo.
echo You can now unplug the USB stick.
echo.
pause
