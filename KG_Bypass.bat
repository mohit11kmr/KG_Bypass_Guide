@echo off
title Samsung KG Bypass Tool (ADB + AppOps)
color 0B
setlocal enabledelayedexpansion

echo ============================================
echo  Samsung Knox Guard (KG) Bypass Tool
echo  For SM-A042F / Android 14 / MT6765
echo ============================================
echo.

:: Check ADB
where adb >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] ADB not found in PATH. Install Android SDK Platform Tools.
    pause
    exit /b 1
)

:: Check device
echo [*] Checking for connected device...
adb devices | findstr /R "device$" >nul
if %errorlevel% neq 0 (
    echo [ERROR] No device connected or unauthorized.
    echo        Connect your phone via USB and enable USB debugging.
    pause
    exit /b 1
)

echo [✓] Device connected
echo.

:: List Knox/EMM packages
echo [*] Detecting Knox/EMM packages...
adb shell pm list packages | findstr /I "knox mdm emm" > packages.txt
type packages.txt
echo.

:: Check for known EMM packages
set PACKAGE1=com.sds.emm.cloud.knox.samsung
set PACKAGE2=com.sec.enterprise.knox.cloudmdm.smdms

adb shell pm list packages | findstr /I "%PACKAGE1%" >nul
if %errorlevel% equ 0 (
    echo [✓] Found: %PACKAGE1%
) else (
    echo [!] %PACKAGE1% not found - check packages.txt for correct names
)

adb shell pm list packages | findstr /I "%PACKAGE2%" >nul
if %errorlevel% equ 0 (
    echo [✓] Found: %PACKAGE2%
) else (
    echo [!] %PACKAGE2% not found - check packages.txt for correct names
)
echo.

:: Step 1: Disable provisioning
echo [1/5] Disabling device provisioning...
adb shell settings put global device_provisioned 0
adb shell settings put secure user_setup_complete 0
echo [✓] Done

:: Step 2: Reboot
echo [2/5] Rebooting phone (KG should clear)...
adb shell reboot
echo      Waiting for device to come back...
:waitloop
adb devices | findstr /R "device$" >nul
if %errorlevel% neq 0 (
    timeout /t 2 /nobreak >nul
    goto waitloop
)
echo [✓] Device detected

:: Step 3: Apply AppOps restrictions
echo [3/5] Applying AppOps restrictions to block KG...
adb shell appops set %PACKAGE1% RUN_ANY_IN_BACKGROUND deny
adb shell appops set %PACKAGE1% RUN_IN_BACKGROUND deny
adb shell appops set %PACKAGE1% START_FOREGROUND deny
adb shell appops set %PACKAGE1% WAKE_LOCK deny
echo      [✓] %PACKAGE1% blocked

adb shell appops set %PACKAGE2% RUN_ANY_IN_BACKGROUND deny
adb shell appops set %PACKAGE2% RUN_IN_BACKGROUND deny
adb shell appops set %PACKAGE2% START_FOREGROUND deny
adb shell appops set %PACKAGE2% WAKE_LOCK deny
echo      [✓] %PACKAGE2% blocked

:: Step 4: Restore settings
echo [4/5] Restoring device settings...
adb shell settings put global device_provisioned 1
adb shell settings put secure user_setup_complete 1
echo [✓] Done

:: Step 5: Final reboot
echo [5/5] Rebooting to verify KG stays gone...
adb shell reboot
echo      Waiting for device...
:waitloop2
adb devices | findstr /R "device$" >nul
if %errorlevel% neq 0 (
    timeout /t 2 /nobreak >nul
    goto waitloop2
)
echo [✓] Device detected

echo.
echo ============================================
echo  Done! KG should now be bypassed.
echo  If KG returns, run this tool again.
echo ============================================
echo.
echo  Note: DO NOT factory reset or open Knox apps.
echo ============================================
pause
