@echo off
chcp 65001 >nul
title SYSTOOL Environment Detector

REM ============================================================
REM  SYSTOOL Environment Detector
REM
REM  IMPORTANT: Run this ON THE CLASSROOM COMPUTER, not your own!
REM  Your personal computer has no restore card, so everything
REM  will show "Not detected" if you run it at home.
REM
REM  What it checks:
REM    1. Computer brand (via BIOS/SMBIOS)
REM    2. DeepFreeze (software restore)
REM    3. Lenovo EasyRestore / OneKey (software restore)
REM    4. Tongfang / Hasee / Founder (software restore)
REM    5. Hardware restore card drivers
REM    6. Classroom management software
REM    7. Key running processes
REM    8. Disk info
REM    9. Startup folders
REM ============================================================

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo ============================================================
echo   SYSTOOL Environment Detector
echo   Run ON THE CLASSROOM COMPUTER (not your own PC!)
echo ============================================================
echo.

REM [1] Computer brand
echo [1] COMPUTER BRAND
echo ------------------------------------------------------------
powershell -NoProfile -Command "Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer, Model | Format-List" 2>nul
powershell -NoProfile -Command "Get-CimInstance Win32_BIOS | Select-Object SerialNumber, SMBIOSBIOSVersion | Format-List" 2>nul
echo.

REM [2] DeepFreeze / Faronics
echo [2] DEEPFREEZE (ice-point / Faronics)
echo ------------------------------------------------------------
set "FOUND=0"
sc query "DeepFreeze" >nul 2>&1 && echo   [FOUND] Service: DeepFreeze && set "FOUND=1"
sc query "Faronics DeepFreeze" >nul 2>&1 && echo   [FOUND] Service: Faronics DeepFreeze && set "FOUND=1"
reg query "HKLM\SOFTWARE\Faronics" >nul 2>&1 && echo   [FOUND] Registry: HKLM\SOFTWARE\Faronics && set "FOUND=1"
reg query "HKLM\SOFTWARE\WOW6432Node\Faronics" >nul 2>&1 && echo   [FOUND] Registry: HKLM\SOFTWARE\WOW6432Node\Faronics && set "FOUND=1"
tasklist /fi "imagename eq FrzState2k.exe" 2>nul | findstr /i "FrzState2k" >nul && echo   [FOUND] Process: FrzState2k.exe && set "FOUND=1"
if exist "%ProgramFiles%\Faronics\DeepFreeze" echo   [FOUND] Folder: %ProgramFiles%\Faronics\DeepFreeze && set "FOUND=1"
if exist "%ProgramFiles(x86)%\Faronics\DeepFreeze" echo   [FOUND] Folder: %ProgramFiles(x86)%\Faronics\DeepFreeze && set "FOUND=1"
if "%FOUND%"=="0" echo   Not detected
echo.

REM [3] Lenovo EasyRestore / OneKey
echo [3] LENOVO RESTORE (EasyRestore / OneKey)
echo ------------------------------------------------------------
set "FOUND=0"
sc query "LnvRDrv" >nul 2>&1 && echo   [FOUND] Service: LnvRDrv && set "FOUND=1"
sc query "Lenovo OneKey Recovery" >nul 2>&1 && echo   [FOUND] Service: Lenovo OneKey Recovery && set "FOUND=1"
reg query "HKLM\SYSTEM\CurrentControlSet\Services\LnvRDrv" >nul 2>&1 && echo   [FOUND] Registry: LnvRDrv && set "FOUND=1"
if exist "C:\LENOVO_PART" echo   [FOUND] Partition: C:\LENOVO_PART && set "FOUND=1"
if exist "D:\LENOVO_PART" echo   [FOUND] Partition: D:\LENOVO_PART && set "FOUND=1"
if "%FOUND%"=="0" echo   Not detected
echo.

REM [4] Tongfang / Hasee / Founder
echo [4] TONGFANG / HASEE / FOUNDER RESTORE
echo ------------------------------------------------------------
set "FOUND=0"
sc query "RTDRV" >nul 2>&1 && echo   [FOUND] Service: RTDRV (Tongfang) && set "FOUND=1"
sc query "HaseeProtect" >nul 2>&1 && echo   [FOUND] Service: HaseeProtect (Hasee) && set "FOUND=1"
sc query "FounderRestore" >nul 2>&1 && echo   [FOUND] Service: FounderRestore (Founder) && set "FOUND=1"
if "%FOUND%"=="0" echo   Not detected
echo.

REM [5] Hardware Restore Card Drivers
echo [5] HARDWARE RESTORE CARD (driver level)
echo ------------------------------------------------------------
set "FOUND=0"
echo   Scanning for known restore card drivers...
powershell -NoProfile -Command ^
    "$drivers = @('SentinelDrv','RTDRV','LnvRDrv','HpgGlh','HpgWyz','HpgWatchDog','SminDrv','HYDRAVISOR','VCRDISK','XSB','YuanZhi','SanMing','XiaoShaoBing','HaiGuang'); " ^
    "$svcs = Get-CimInstance Win32_SystemDriver -ErrorAction SilentlyContinue; " ^
    "foreach ($d in $drivers) { " ^
    "    $match = $svcs | Where-Object { $_.Name -like ('*' + $d + '*') -or $_.DisplayName -like ('*' + $d + '*') }; " ^
    "    if ($match) { foreach ($m in $match) { Write-Host ('  [FOUND] Driver: ' + $m.Name + ' - ' + $m.DisplayName) } }" ^
    "}" 2>nul
sc query "XiaoShaoBing" >nul 2>&1 && echo   [FOUND] Service: XiaoShaoBing (小哨兵) && set "FOUND=1"
sc query "SentinelDrv" >nul 2>&1 && echo   [FOUND] Service: SentinelDrv (小哨兵) && set "FOUND=1"
sc query "HaiGuang" >nul 2>&1 && echo   [FOUND] Service: HaiGuang (海光) && set "FOUND=1"
sc query "HYDRAVISOR" >nul 2>&1 && echo   [FOUND] Service: HYDRAVISOR (海光) && set "FOUND=1"
sc query "YuanZhi" >nul 2>&1 && echo   [FOUND] Service: YuanZhi (远志) && set "FOUND=1"
sc query "SanMing" >nul 2>&1 && echo   [FOUND] Service: SanMing (三茗) && set "FOUND=1"
sc query "VCRDISK" >nul 2>&1 && echo   [FOUND] Service: VCRDISK (Lenovo HDD Protect) && set "FOUND=1"
sc query "XSB" >nul 2>&1 && echo   [FOUND] Service: XSB (小哨兵) && set "FOUND=1"
if "%FOUND%"=="0" echo   No dedicated restore card driver found
echo.

REM [6] Classroom Management Software
echo [6] CLASSROOM MANAGEMENT SOFTWARE
echo ------------------------------------------------------------
set "FOUND=0"
tasklist 2>nul | findstr /i "StudentMain\|NetSchool\|ToDesk\|TeamViewer\|AnyDesk\|RustDesk" >nul && echo   [FOUND] Classroom/remote management process running && set "FOUND=1"
sc query "StudentMain" >nul 2>&1 && echo   [FOUND] Service: StudentMain (极域) && set "FOUND=1"
sc query "NetSchool" >nul 2>&1 && echo   [FOUND] Service: NetSchool && set "FOUND=1"
sc query "ToDesk" >nul 2>&1 && echo   [FOUND] Service: ToDesk && set "FOUND=1"
if "%FOUND%"=="0" echo   Not detected
echo.

REM [7] Key Running Processes
echo [7] KEY RUNNING PROCESSES
echo ------------------------------------------------------------
tasklist /fo csv 2>nul | findstr /i "restore\|freeze\|deep\|faronics\|sentinel\|guard\|protect\|recover\|todesk\|teamviewer\|anydesk\|rustdesk\|StudentMain\|NetSchool" 2>nul
if errorlevel 1 echo   No matching processes found
echo.

REM [8] Disk Info
echo [8] DISK INFO
echo ------------------------------------------------------------
powershell -NoProfile -Command "Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID, DriveType, Size, FreeSpace, VolumeName | Format-Table -AutoSize" 2>nul
echo.

REM [9] Startup Folders
echo [9] STARTUP FOLDERS (what auto-runs on boot)
echo ------------------------------------------------------------
echo   All-Users Startup:
dir /b "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp" 2>nul || echo     (empty or not accessible)
echo.
echo   Current-User Startup:
dir /b "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup" 2>nul || echo     (empty or not accessible)
echo.

echo ============================================================
echo   DETECTION COMPLETE
echo ============================================================
echo.
echo NEXT STEPS:
echo   1. Look for [FOUND] items above - that identifies restore card
echo   2. If nothing found, run test-c-persistence.bat anyway
echo   3. test-c-persistence.bat checks which C folders survive reboot
echo.
echo Save this output or take a screenshot.
echo.
pause
