@echo off
REM open.bat - opens the archive folder in Explorer
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$a=$null; foreach($d in (Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3')){ $c=Join-Path $d.DeviceID 'AppCacheData'; if(Test-Path (Join-Path $c '.marker')){ $a=$c; break } }; if(-not $a){ $a='D:\AppCacheData' }; Start-Process explorer.exe $a"
