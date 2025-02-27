Transform your Windows Computer into a Video Game console first, PC second! GamesDows is intended to emulate Steam OS's "Game Mode" as closely as possible. 

**New: Now with Decky Loader support for Windows!**

**This script is a WIP. Currently, the main functionality works as intended. Steam Big Picture (or Playnite) launches automatically when the OS boots with high priority set as as the shell, then explorer starts automatically after a delay, which allows you to exit to desktop via the menu without needing to launch a shortcut for Explorer.exe first.**

**Note: Steam or Playnite must be installed, you must be signed in to Steam if using the Steam variant, and finally the Steam Autostart entry in task manager must be disabled/deleted before running the script.**

**This script must be run as admin!**

# GamesDows
The Enable GamesDows batch script makes Windows boot straight into Steam Big Picture or Playnite without displaying any Explorer UI elements to ensure a Game Console like experience on Windows. I made this because I have a Steam Deck and I want the experience to mirror that of Steam OS as closely as possible. However, this will work on any Windows PC, the commands are not specific to the Steam Deck.

**How the main functionality works: The enable Game Mode batch script sets steam big picture as the shell and creates a manifest file in the Steam folder which allows it to always start as admin. The enable Game Mode batch script creates a VBS script to suppress the command prompt window when Explorer.exe launches in the background > The VBS script launches a second batch script created by the enable script creates and launches the second batch script via a scheduled task after a 20 second delay > delayed explorer batch script resets the shell to to explorer.exe, then launches explorer in the background so that it's possible to exit big picture without running a shortcut (menu performs as expected and exits directly to desktop without manually launching a separate shortcut).** 

After another delay once explorer.exe is started (it retains elevated permissions once started), the default shell is reset to Steam Big Picture so that it boots directly to Big Picture as expected upon reboot. 

The powershell commands are run directly via the batch script, so no secondary powershell script is needed. Everything in the script is done automatically when run as admin.

**How the script works**

Here's a breakdown of what each part of the script does:

**1) Set Steam Big Picture as Default Shell:**

Disables echoing the command to the console (@echo off).

Enables the use of advanced scripting features (SETLOCAL EnableExtensions).

Changes the Windows shell from the default explorer.exe to Steam's Big Picture mode. It modifies the Windows Registry to make Steam.exe -bigpicture the default shell that launches upon user login.

**2) Creates and Sets Up a Delayed Start Script for Explorer:**

Defines paths for the Steam folder and Delayed Explorer Start script name.

Creates a batch file (DelayedExplorerStart.bat) that checks if the user is logged on. If the user is logged on, it sets the shell back to Windows Explorer (explorer.exe) after a delay, allowing Steam Big Picture to launch first.

After booting directly into Steam Big Picture, explorer.exe is launched automatically so that the "Exit to Desktop" menu item in Steam Big Picture works as expected. You do not need to launch a shortcut from within Big Picture first in order to be able exit to the desktop. The menu item will work as intended after the GamesDows script is run, no additional work necessary.

**3) Creates a VBScript to Run the Batch File Silently:**

A VBScript (RunBatchSilently.vbs) is created to run the DelayedExplorerStart.bat to suppress the command prompt window/run silently. This means the batch file will launch explorer in the background without opening a visible command prompt window over the Steam Big Picture UI.

**4) It Sets Up a Scheduled Task to Run the DelayedExplorerStart.bat Script at Logon/bootup:**

Creates an XML file to define a scheduled task. This task will trigger the VBScript at user logon.

Deletes any existing scheduled task with the same name and creates a new one using the XML configuration. This ensures that the DelayedExplorerStart.bat script runs every time the user logs on.

**5) Enable Automatic Logon and Disable Boot UI:**

Configures Windows to automatically log in with the current user account (AutoAdminLogon).

Sets an empty default password for automatic logon (DefaultPassword). If you have a password, please insert it into the empty quotation marks in the batch script inside this command. This is the command that inputs the user password, it is set to be blank by default. I have put a placeholder in the script breakdown here for clarity:

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d "YourPasswordGoesHere" /f

The command "bcdedit.exe -set {globalsettings} bootuxdisabled on" disables the boot user interface (bootuxdisabled). This disables Windows Branded Boot, and therefore no Windows logo is displayed when the OS boots.


What remains to be fixed:

1. Completely suppressing the taskbar from appearing when Windows Explorer automatically launches in the background. The taskbar displays temporarily for ~1 second when explorer.exe launches, which makes it appear over the Big Picture UI; and then it disappears. This is not intended behavior, and it is visually distracting. 

2. Disabling the Windows welcome sign-in UI animation (user picture, user name, spinning wheel) entirely. Currently the Boot logo is removed as intended, and the script is set to log the user account which ran the script in automatically. The welcome sign-in animation still remains, and will be disabled in future versions of the script. Going to have to write a custom C++ application or a custom credential provider to do so since there is no off the shelf way to disable the Welcome Screen on Windows 11.

3. Disabling the Steam client update window which displays momentarily when Steam updates (this only occurs when the Steam Client has an update, otherwise it will not appear) before launching Big Picture.

**Please let me know if you have any issues with existing functionality and I'll try to get the bugs fixed up if any arise.**

I will gladly take PRs to fix the 3 remaining issues if anyone knows how to solve them.

**Note: If for any reason explorer doesn't start and you get a black screen and cannot view the desktop, it needs to be launched manually via task manager by launching explorer.exe. It needs to be set as the shell first before it is launched from task manager for the desktop to appear when launched a single time, otherwise it will just launch a file browser window. Due to this limitation, you must start explorer.exe twice from task manager to load the Desktop**

-------------------
# Decky Loader for Windows

https://github.com/ACCESS-DENIIED/Decky-Loader-For-Windows

ACCESS-DENIIED's Decky Install Scripts are now included with GamesDows! Just run the separate install-decky.bat to get Decky automatically installed and configured for Steam! **Please ensure Python and Steam have already  been installed and configured, and make sure to already be signed into Steam before running the install script for Decky!**

**Please make sure to check the original thread for the caveats described by ACCESS-DENIIED, the author of the Decky install scripts:**

https://www.reddit.com/r/WindowsOnDeck/comments/1hl40i5/i_created_a_python_script_to_install_decky_loader/

Below is the description of these scripts from ACCESS-DENIIED's repo:

A Work-in-progress Python-based installer and build system for Decky Loader on Windows. This tool automates the entire process of building, installing, and configuring Decky Loader - bringing the Steam Deck's popular plugin system to Windows.

## Features
- 🚀 Simple installation and build process
- ⚙️ Automatic dependency management (Node.js, npm, pnpm, Python)
- 🔧 Configures Steam for plugin development
- 🏃‍♂️ Sets up autostart for PluginLoader
- 📁 Creates proper homebrew directory structure
- 💻 Builds both console and GUI executables

## Requirements
- Windows 10/11
- Steam installation
- Internet connection for downloading dependencies

## Usage
Download the files or the zip in the releases section, run the Enable GamesDows script for either Steam or Playnite. 

If you would also like to install Decky Loader, run "install_decky.bat" as administrator and follow the prompts. This script is not necessary for GamesDows to function, it enables the Decky Loader plugin system for Steam. I've included it in this project as it brings Windows one step closer to Steam OS functionality.

