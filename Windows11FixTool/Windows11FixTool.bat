@echo off
chcp 437 >nul 2>&1
title Windows 11 Fix Tool
color 0B

:MENU
cls
echo ==============================================
echo            Windows 11 Fix Tool
echo    Applicable to version 22H2 and above,
echo		 Please run as administrator.
echo ==============================================
echo 1. Show Full Right-Click Menu
echo 2. Show Compact Right-Click Menu
echo 3. Enable New File Explorer Interface
echo 4. Enable Classic File Explorer Interface
echo 5. Disable F1 Key for Edge Help
echo 6. Enable F1 Key for Edge Help
echo 7. Extend the pause duration for Windows 11 updates
echo 8. Disable Windows Defender
echo 9. Enable Windows Defender
echo 10. Exit Script
echo ==============================================

set /p "choice=Please enter your choice (1-10): "

if "%choice%"=="1" goto FullRightClick
if "%choice%"=="2" goto CompactRightClick
if "%choice%"=="3" goto NewExplorer
if "%choice%"=="4" goto ClassicExplorer
if "%choice%"=="5" goto DisableF1Help
if "%choice%"=="6" goto EnableF1Help
if "%choice%"=="7" goto Extend
if "%choice%"=="8" goto DisableDefender
if "%choice%"=="9" goto EnableDefender
if "%choice%"=="10" goto EXIT

echo Invalid option, please enter a number between 1 and 10
pause
goto MENU

:FullRightClick
echo.
echo Applying full right-click menu...
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve >nul 2>&1
if %errorlevel% equ 0 (
    echo Success: Full right-click menu enabled. Please restart your computer for changes to take effect.
) else (
    echo Error: Failed to enable full right-click menu. Please run as administrator.
)
echo.
pause
goto MENU

:CompactRightClick
echo.
echo Applying compact right-click menu...
reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f >nul 2>&1
if %errorlevel% equ 0 (
    echo Success: Compact right-click menu enabled. Please restart your computer for changes to take effect.
) else (
    echo Error: Failed to enable compact right-click menu. Please run as administrator.
)
echo.
pause
goto MENU

:NewExplorer
echo.
echo Enabling new File Explorer interface...
:: 删除第一个CLSID项及其所有子项
reg delete "HKCU\Software\Classes\CLSID\{2aa9162e-c906-4dd9-ad0b-3d24a8eef5a0}" /f
:: 删除第二个CLSID项及其所有子项
reg delete "HKCU\Software\Classes\CLSID\{6480100b-5a83-4d1e-9f69-8ae5a88e9a33}" /f

if %errorlevel% equ 0 (
    echo Success: Classic File Explorer interface enabled. Please restart File Explorer for changes to take effect.
) else (
    echo Error: Failed to enable classic File Explorer interface. Please run as administrator.
)
echo.
pause
goto MENU

:ClassicExplorer
echo.
echo Enabling classic File Explorer interface...
:: ==================================================
:: 第一个CLSID项：{2aa9162e-c906-4dd9-ad0b-3d24a8eef5a0}
:: ==================================================
:: 创建CLSID主项并设置默认值
reg add "HKCU\Software\Classes\CLSID\{2aa9162e-c906-4dd9-ad0b-3d24a8eef5a0}" /ve /t REG_SZ /d "CLSID_ItemsViewAdapter" /f
:: 创建InProcServer32子项并设置默认值（DLL路径）
reg add "HKCU\Software\Classes\CLSID\{2aa9162e-c906-4dd9-ad0b-3d24a8eef5a0}\InProcServer32" /ve /t REG_SZ /d "C:\Windows\System32\Windows.UI.FileExplorer.dll_" /f
:: 设置ThreadingModel属性
reg add "HKCU\Software\Classes\CLSID\{2aa9162e-c906-4dd9-ad0b-3d24a8eef5a0}\InProcServer32" /v "ThreadingModel" /t REG_SZ /d "Apartment" /f
:: ==================================================
:: 第二个CLSID项：{6480100b-5a83-4d1e-9f69-8ae5a88e9a33}
:: ==================================================
:: 创建CLSID主项并设置默认值
reg add "HKCU\Software\Classes\CLSID\{6480100b-5a83-4d1e-9f69-8ae5a88e9a33}" /ve /t REG_SZ /d "File Explorer Xaml Island View Adapter" /f
:: 创建InProcServer32子项并设置默认值（DLL路径）
reg add "HKCU\Software\Classes\CLSID\{6480100b-5a83-4d1e-9f69-8ae5a88e9a33}\InProcServer32" /ve /t REG_SZ /d "C:\Windows\System32\Windows.UI.FileExplorer.dll_" /f
:: 设置ThreadingModel属性
reg add "HKCU\Software\Classes\CLSID\{6480100b-5a83-4d1e-9f69-8ae5a88e9a33}\InProcServer32" /v "ThreadingModel" /t REG_SZ /d "Apartment" /f

if %errorlevel% equ 0 (
    echo Success: New File Explorer interface enabled. Please restart File Explorer for changes to take effect.
) else (
    echo Error: Failed to enable new File Explorer interface. Please run as administrator.
)
echo.
pause
goto MENU

:DisableF1Help
echo.
echo Disabling F1 key for Edge help...
:: 创建并设置win32子项的默认值（空值）
reg add "HKCU\SOFTWARE\Classes\Typelib\{8cec5860-07a1-11d9-b15e-000d56bfe6ee}\1.0\0\win32" /ve /t REG_SZ /d "" /f
:: 创建并设置win64子项的默认值（空值）
reg add "HKCU\SOFTWARE\Classes\Typelib\{8cec5860-07a1-11d9-b15e-000d56bfe6ee}\1.0\0\win64" /ve /t REG_SZ /d "" /f

if %errorlevel% equ 0 (
    echo Success: F1 key for Edge help disabled. Changes will take effect immediately.
) else (
    echo Error: Failed to disable F1 help shortcut. Please run as administrator.
)
echo.
pause
goto MENU

:EnableF1Help
echo.
echo Enabling F1 key for Edge help...
:: 删除指定的注册表项及其所有子项（包括win32和win64子项）
reg delete "HKCU\SOFTWARE\Classes\Typelib\{8cec5860-07a1-11d9-b15e-000d56bfe6ee}\1.0\0" /f

if %errorlevel% equ 0 (
    echo Success: F1 key for Edge help enabled. Changes will take effect immediately.
) else (
    echo Error: Failed to enable F1 help shortcut. Please run as administrator.
)
echo.
pause
goto MENU

:Extend
echo.
echo Extending the pause duration for Windows 11 updates
:: 修改注册表暂停时长显示
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "FlightSettingsMaxPauseDays" /t REG_DWORD /d 7300 /f

if %errorlevel% equ 0 (
    echo Success: The pause duration for Windows 11 updates extended.
) else (
    echo Error: Failed to extend the pause duration for Windows 11 updates.
)
echo.
pause
goto MENU

:DisableDefender
echo.
echo Disabling Windows Defender...
:: ==================================================
:: Windows Defender 主策略项
:: ==================================================
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableRealtimeMonitoring" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiVirus" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableSpecialRunningModes" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableRoutinelyTakingAction" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "ServiceKeepAlive" /t REG_DWORD /d 1 /f
:: ==================================================
:: 实时保护策略项
:: ==================================================
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableBehaviorMonitoring" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableOnAccessProtection" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableScanOnRealtimeEnable" /t REG_DWORD /d 1 /f
:: ==================================================
:: 签名更新策略项
:: ==================================================
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" /v "ForceUpdateFromMU" /t REG_DWORD /d 1 /f
:: ==================================================
:: Spynet 策略项（云端保护）
:: ==================================================
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "DisableBlockAtFirstSeen" /t REG_DWORD /d 1 /f

if %errorlevel% equ 0 (
    echo Success: Windows Defender fully disabled. Please restart your computer for changes to take effect.
) else (
    echo Error: Failed to disable Windows Defender. Please run as administrator.
)
echo.
pause
goto MENU

:EnableDefender
echo.
echo Enabling Windows Defender...
:: ==================================================
:: 删除 Windows Defender 主策略项中的禁用值
:: ==================================================
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableRealtimeMonitoring" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiVirus" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableSpecialRunningModes" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableRoutinelyTakingAction" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "ServiceKeepAlive" /f >nul 2>&1
:: ==================================================
:: 删除实时保护策略项中的禁用值
:: ==================================================
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableBehaviorMonitoring" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableOnAccessProtection" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableScanOnRealtimeEnable" /f >nul 2>&1
:: ==================================================
:: 删除签名更新策略项
:: ==================================================
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" /v "ForceUpdateFromMU" /f >nul 2>&1
:: ==================================================
:: 删除 Spynet 策略项
:: ==================================================
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "DisableBlockAtFirstSeen" /f >nul 2>&1

if %errorlevel% equ 0 (
    echo Success: Windows Defender fully enabled. All protection features are restored. Please restart your computer for changes to take effect.
) else (
    echo Error: Failed to enable Windows Defender. Please run as administrator.
)
echo.
pause
goto MENU

:EXIT
echo.
echo Thank you for using Windows 11 Fix Tool. Exiting...
ping -n 2 127.0.0.1 >nul
exit