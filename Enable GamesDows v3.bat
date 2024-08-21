@echo off
SETLOCAL EnableExtensions EnableDelayedExpansion

echo Checking for administrative privileges...
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrative privileges.
    echo Please run it as an administrator.
    pause
    exit /b 1
)

echo Define the default Steam folder path and script names
SET "STEAM_FOLDER=C:\Program Files (x86)\Steam"
SET "SCRIPT_NAME=DelayedExplorerStart.bat"
SET "SCRIPT_PATH=%STEAM_FOLDER%\%SCRIPT_NAME%"
SET "EXPLORER_PATH=C:\Windows\explorer.exe"
SET "VBS_NAME=RunBatchSilently.vbs"
SET "VBS_PATH=%STEAM_FOLDER%\%VBS_NAME%"
SET "ADMIN_VBS_NAME=LaunchSteamAsAdmin.vbs"
SET "ADMIN_VBS_PATH=%STEAM_FOLDER%\%ADMIN_VBS_NAME%"
SET "STEAM_PATH=C:\Program Files (x86)\Steam\Steam.exe -bigpicture -nobootstrapupdate -skipinitialbootstrap -skipverifyfiles"

echo Creating LaunchSteamAsAdmin.vbs script

:: Create VBScript to launch Steam as admin and set the shell to Steam
(
    echo Set WshShell = CreateObject^("WScript.Shell"^)
    echo ' Run REG ADD command to set the shell to Steam
    echo WshShell.Run "cmd /c REG ADD 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' /v Shell /t REG_SZ /d '!STEAM_PATH!' /f", 0, True
    echo ' Launch Steam with elevated privileges
    echo Set objShell = CreateObject^("Shell.Application"^)
    echo objShell.ShellExecute "!STEAM_PATH!", "", "", "runas", 1
    echo Set WshShell = Nothing
    echo Set objShell = Nothing
) > "!ADMIN_VBS_PATH!"
if %errorlevel% neq 0 (
    echo Error creating LaunchSteamAsAdmin.vbs
    pause
    exit /b 1
)

echo Creating RunBatchSilently.vbs script

:: Create VBScript to run the batch file silently
(
    echo Set WshShell = CreateObject^("WScript.Shell"^)
    echo WshShell.Run chr^(34^)^&"!SCRIPT_PATH!"^&chr^(34^), 0, True
    echo Set WshShell = Nothing
) > "!VBS_PATH!"
if %errorlevel% neq 0 (
    echo Error creating RunBatchSilently.vbs
    pause
    exit /b 1
)

echo Creating DelayedExplorerStart.bat script

:: Create the DelayedExplorerStart.bat script in the Steam folder
(
    echo @echo off
    echo :CHECK_LOGON
    echo query user ^| find /i "%USERNAME%" ^>nul
    echo if %errorlevel% neq 0 ^(
    echo     timeout /t 10 /nobreak ^>nul
    echo     goto CHECK_LOGON
    echo ^)
    echo echo Set Shell back to Explorer
    echo REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "!EXPLORER_PATH!" /f
    echo if %%errorlevel%% neq 0 ^(
    echo     echo Error setting shell to Explorer
    echo     exit /b 1
    echo ^)
    echo timeout /t 20 /nobreak ^>nul
    echo start C:\Windows\explorer.exe
    echo timeout /t 10 /nobreak ^>nul
    echo REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v Shell /t REG_SZ /d "\"!ADMIN_VBS_PATH!\"" /f
    echo if %%errorlevel%% neq 0 ^(
    echo     echo Error setting shell to Steam
    echo     exit /b 1
    echo ^)
) > "!SCRIPT_PATH!"
if %errorlevel% neq 0 (
    echo Error creating DelayedExplorerStart.bat
    pause
    exit /b 1
)

echo Create XML file for the scheduled task
SET "XML_PATH=%STEAM_FOLDER%\DelayedExplorerStartTask.xml"

echo Delete the existing XML file if it exists
IF EXIST "!XML_PATH!" DEL "!XML_PATH!"

for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set CURRENT_DATE=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2%T%datetime:~8,2%:%datetime:~10,2%:%datetime:~12,2%

(
    echo ^<?xml version="1.0" encoding="UTF-16"?^>
    echo ^<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^>
    echo   ^<RegistrationInfo^>
    echo     ^<Date^>!CURRENT_DATE!^</Date^>
    echo     ^<Author^>"%USERNAME%"^</Author^>
    echo     ^<Description^>Run DelayedExplorerStart.bat at logon.^</Description^>
    echo   ^</RegistrationInfo^>
    echo   ^<Triggers^>
    echo     ^<LogonTrigger^>
    echo       ^<Enabled^>true^</Enabled^>
    echo     ^</LogonTrigger^>
    echo   ^</Triggers^>
    echo   ^<Principals^>
    echo     ^<Principal id="Author"^>
    echo       ^<UserId^>%USERNAME%^</UserId^>
    echo       ^<LogonType^>InteractiveToken^</LogonType^>
    echo       ^<RunLevel^>HighestAvailable^</RunLevel^>
    echo     ^</Principal^>
    echo   ^</Principals^>
    echo   ^<Settings^>
    echo       ^<MultipleInstancesPolicy^>IgnoreNew^</MultipleInstancesPolicy^>
    echo       ^<DisallowStartIfOnBatteries^>false^</DisallowStartIfOnBatteries^>
    echo       ^<StopIfGoingOnBatteries^>false^</StopIfGoingOnBatteries^>
    echo       ^<AllowHardTerminate^>true^</AllowHardTerminate^>
    echo       ^<StartWhenAvailable^>true^</StartWhenAvailable^>
    echo       ^<RunOnlyIfNetworkAvailable^>false^</RunOnlyIfNetworkAvailable^>
    echo       ^<IdleSettings^>
    echo         ^<StopOnIdleEnd^>true^</StopOnIdleEnd^>
    echo         ^<RestartOnIdle^>false^</RestartOnIdle^>
    echo       ^</IdleSettings^>
    echo       ^<Enabled^>true^</Enabled^>
    echo       ^<Hidden^>false^</Hidden^>
    echo       ^<WakeToRun^>false^</WakeToRun^>
    echo       ^<ExecutionTimeLimit^>PT72H^</ExecutionTimeLimit^>
    echo       ^<Priority^>7^</Priority^>
    echo   ^</Settings^>
    echo   ^<Actions Context="Author"^>
    echo     ^<Exec^>
    echo       ^<Command^>wscript.exe^</Command^>
    echo       ^<Arguments^>"!VBS_PATH!"^</Arguments^>
    echo     ^</Exec^>
    echo   ^</Actions^>
    echo ^</Task^>
) > "!XML_PATH!"
if %errorlevel% neq 0 (
    echo Error creating XML file
    pause
    exit /b 1
)

echo Delete the existing scheduled task if it exists
schtasks /delete /tn "RunDelayedExplorerStart" /f

echo Create the scheduled task using the XML file
schtasks /create /tn "RunDelayedExplorerStart" /xml "!XML_PATH!"
if %errorlevel% neq 0 (
    echo Error creating scheduled task
    pause
    exit /b 1
)

echo Script completed successfully.
pause
