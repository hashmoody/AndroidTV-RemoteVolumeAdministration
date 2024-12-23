@echo off
title Moody's Remote Volume Administration System
setlocal EnableDelayedExpansion

REM File to store connected devices history
set historyFile=devices_history.txt

REM Ensure the history file exists
if not exist %historyFile% (
    echo. > %historyFile%
)

REM Function to select device
:SelectDevice
echo.
echo ==== Connected Devices History ====
set i=1
set validOptions=
for /f "tokens=*" %%A in (%historyFile%) do (
    echo [!i!] %%A
    set device[!i!]=%%A
    set validOptions=!validOptions!!i!
    set /a i+=1
)

echo [0] Enter a new device IP
echo ================================
set /p deviceOption="Select a device (0-%i%): "

REM Handle user selection
if %deviceOption%==0 (
    set /p deviceIP="Enter the IP address of the TV you want to control: "
) else (
    set deviceIP=!device[%deviceOption%]!
    if "!deviceIP!"=="" (
        echo Invalid option. Please try again.
        goto SelectDevice
    )
)

REM Connect to the selected or entered device
adb connect %deviceIP% >nul 2>&1
if %errorlevel% NEQ 0 (
    echo Unable to connect to the device. Please try again.
    goto SelectDevice
)
echo Connected to %deviceIP%.

REM Update history file
findstr /v /r /c:"^%deviceIP%$" %historyFile% > temp.txt && move /y temp.txt %historyFile% >nul
echo %deviceIP%>>%historyFile%

REM Keep only the last 4 devices in history
for /f "skip=4 delims=" %%A in ('type %historyFile%') do (
    findstr /v /c:"%%A" %historyFile% > temp.txt && move /y temp.txt %historyFile% >nul
)

REM Function to set and monitor volume
:MonitorVolume
set /p volumeLevel="Enter desired volume level (0-100): "
if %volumeLevel% LSS 0 (
    echo Invalid input. Volume level must be between 0 and 100.
    goto MonitorVolume
)
if %volumeLevel% GTR 100 (
    echo Invalid input. Volume level must be between 0 and 100.
    goto MonitorVolume
)
echo Locking volume to %volumeLevel% and monitoring changes...
:MonitorLoop

REM Adjust volume using media volume (fallback if needed)
adb shell media volume --set %volumeLevel% >nul 2>&1
if %errorlevel% NEQ 0 (
    echo Failed to set volume. Please check the device connection.
    goto Cleanup
)
echo Volume set to %volumeLevel%.

REM Wait and continue monitoring without resetting unnecessarily
timeout /t 2 >nul
goto MonitorLoop

REM Cleanup on exit
:Cleanup
echo Disconnecting from device...
adb disconnect
echo Exiting Moody's Remote Volume Administration System.
exit
