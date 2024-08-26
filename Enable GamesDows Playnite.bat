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

echo Define the default Playnite folder path and script names
SET "PLAYNITE_FOLDER=%LOCALAPPDATA%\Playnite"
SET "SCRIPT_NAME=DelayedExplorerStart.bat"
SET "SCRIPT_PATH=%PLAYNITE_FOLDER%\%SCRIPT_NAME%"
SET "EXPLORER_PATH=C:\Windows\explorer.exe"
SET "VBS_NAME=RunBatchSilently.vbs"
SET "VBS_PATH=%PLAYNITE_FOLDER%\%VBS_NAME%"
SET "ADMIN_VBS_NAME=LaunchPlayniteAsAdmin.vbs"
SET "ADMIN_VBS_PATH=%PLAYNITE_FOLDER%\%ADMIN_VBS_NAME%"
SET "PLAYNITE_PATH=%LOCALAPPDATA%\Playnite\Playnite.FullscreenApp.exe"

echo Creating LaunchPlayniteAsAdmin.vbs script

:: Create VBScript to launch Playnite as admin and set the shell to Playnite
(
    echo Set WshShell = CreateObject^("WScript.Shell"^)
    echo ' Run REG ADD command to set the shell to Playnite
    echo WshShell.Run "cmd /c REG ADD 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' /v Shell /t REG_SZ /d '!PLAYNITE_PATH!' /f", 0, True
    echo ' Launch Playnite with elevated privileges
    echo Set objShell = CreateObject^("Shell.Application"^)
    echo objShell.ShellExecute "!PLAYNITE_PATH!", "", "", "runas", 1
    echo Set WshShell = Nothing
    echo Set objShell = Nothing
) > "!ADMIN_VBS_PATH!"
if %errorlevel% neq 0 (
    echo Error creating LaunchPlayniteAsAdmin.vbs
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

:: Create the DelayedExplorerStart.bat script in the Playnite folder
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
    echo     echo Error setting shell to Playnite
    echo     exit /b 1
    echo ^)
) > "!SCRIPT_PATH!"
if %errorlevel% neq 0 (
    echo Error creating DelayedExplorerStart.bat
    pause
    exit /b 1
)

echo Create XML file for the scheduled task
SET "XML_PATH=%PLAYNITE_FOLDER%\DelayedExplorerStartTask.xml"

echo Delete the existing XML file if it exists
IF EXIST "!XML_PATH!" DEL "!XML_PATH!"

(
    echo ^<?xml version="1.0" encoding="UTF-16"?^>
    echo ^<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^>
    echo   ^<RegistrationInfo^>
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

echo Delayed Explorer start script and VBScript created in Steam folder.
echo Scheduled Task added to run the script at logon.
echo XML file for Scheduled Task created.

echo Disable the boot UI
bcdedit.exe -set {globalsettings} bootuxdisabled on

echo Disable Visual Effects
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v VisualEffects /t REG_DWORD /d 3 /f

echo Increase File System Performance
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsDisableLastAccessUpdate /t REG_DWORD /d 1 /f

echo Optimize Paging File Performance
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t REG_DWORD /d 1 /f

echo Disable Startup Delay
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /f
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /t REG_DWORD /d 0 /f

echo Improve Windows Explorer Process Priority
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\explorer.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 3 /f
echo Adjust Large System Cache
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 1 /f
echo Enabling No GUI Boot
bcdedit /set {current} quietboot on

echo Registry modifications are complete.
echo Steam Big Picture set as default shell.
echo Automatic logon enabled.
echo Boot UI disabled.

pause

echo Script completed successfully.
pause