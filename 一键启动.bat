@echo off
chcp 65001 >nul
title SYSTOOL One-Click Starter

REM ============================================================
REM  SYSTOOL One-Click Starter
REM
REM  Works from ANY location: D drive, USB stick, anywhere.
REM  Auto-copies itself to D:\SysTool before starting,
REM  so you can UNPLUG the USB stick after launching.
REM
REM  How to use:
REM    1. Copy entire SysTool folder to USB stick
REM    2. Plug USB into classroom PC
REM    3. Right-click 一键启动.bat -> Run as administrator
REM    4. Wait for "SUCCESS" message
REM    5. UNPLUG USB stick and leave - done!
REM
REM  What it does:
REM    - Copies start.vbs + ppt-archiver.ps1 to D:\SysTool\
REM    - Starts from D:\SysTool (so USB removal is safe)
REM    - Archives PPT files to D:\AppCacheData\yyyy-MM-dd\
REM    - D drive is permanent, not wiped by restore card
REM ============================================================

set "SCRIPTDIR=%~dp0"
set "SCRIPTDIR=%SCRIPTDIR:~0,-1%"
set "TARGETDIR=D:\SysTool"

REM --- Self-elevate to admin ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo ============================================================
echo   SYSTOOL One-Click Starter
echo ============================================================
echo.

REM --- Step 1: Copy files to D drive if needed ---
echo [1/4] Copying files to D drive (permanent location)...
if not exist "%TARGETDIR%" mkdir "%TARGETDIR%" 2>nul

REM Always copy fresh (in case scripts were updated)
copy /y "%SCRIPTDIR%\start.vbs" "%TARGETDIR%\start.vbs" >nul 2>&1
copy /y "%SCRIPTDIR%\ppt-archiver.ps1" "%TARGETDIR%\ppt-archiver.ps1" >nul 2>&1

if exist "%TARGETDIR%\start.vbs" if exist "%TARGETDIR%\ppt-archiver.ps1" (
    echo   Files copied to %TARGETDIR%
) else (
    echo   [ERROR] Cannot write to D:\SysTool
    echo   Is D drive the open/non-protected drive?
    pause
    exit /b 1
)
echo.

REM --- Step 2: Check if already running ---
echo [2/4] Checking if already running...
powershell -NoProfile -Command "$p = Get-CimInstance Win32_Process -Filter \"Name='powershell.exe' OR Name='wscript.exe'\" | Where-Object { $_.CommandLine -like '*ppt-archiver*' -or $_.CommandLine -like '*start.vbs*' }; if ($p) { exit 1 } else { exit 0 }"
if %errorLevel% equ 1 (
    echo   Already running. No action needed.
    echo   You can unplug the USB stick now.
    echo.
    timeout /t 3 /nobreak >nul
    exit /b 0
)
echo   Not running yet, will start now.
echo.

REM --- Step 3: Verify D drive files ---
echo [3/4] Verifying D drive files...
if not exist "%TARGETDIR%\start.vbs" (
    echo   [ERROR] %TARGETDIR%\start.vbs missing
    pause
    exit /b 1
)
if not exist "%TARGETDIR%\ppt-archiver.ps1" (
    echo   [ERROR] %TARGETDIR%\ppt-archiver.ps1 missing
    pause
    exit /b 1
)
echo   D drive files OK.
echo.

REM --- Step 4: Launch from D drive ---
echo [4/4] Starting SYSTOOL from D drive...
wscript.exe "%TARGETDIR%\start.vbs"
timeout /t 3 /nobreak >nul

REM --- Verify ---
tasklist /fi "imagename eq wscript.exe" /fo csv 2>nul | findstr /i "wscript" >nul
if %errorLevel% equ 0 (
    echo   SUCCESS: wscript.exe is running.
) else (
    tasklist /fi "imagename eq powershell.exe" /fo csv 2>nul | findstr /i "powershell" >nul
    if %errorLevel% equ 0 (
        echo   SUCCESS: powershell.exe is running.
    ) else (
        echo   [WARNING] Process not detected yet.
        echo   It may take a few seconds to start.
    )
)

echo.
echo ============================================================
echo   SYSTOOL IS RUNNING IN BACKGROUND
echo ============================================================
echo.
echo   Source: D:\SysTool\ (permanent location)
echo   Archives: D:\AppCacheData\yyyy-MM-dd\
echo.
echo  ******************************
echo  *  YOU CAN UNPLUG THE USB NOW *
echo  ******************************
echo.
echo   The archiver keeps running from D drive.
echo   Teacher's PPTs will be silently saved to D:\AppCacheData
echo.
echo This window closes in 5 seconds...
timeout /t 5 /nobreak >nul
