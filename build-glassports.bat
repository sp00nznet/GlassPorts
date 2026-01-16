@echo off
REM ============================================================================
REM GlassPorts One-Click Automated Build System for Windows
REM ============================================================================
REM
REM This script automatically:
REM   1. Installs/configures WSL2 if needed
REM   2. Installs all Linux build dependencies
REM   3. Downloads Google Glass factory images
REM   4. Extracts proprietary binary blobs
REM   5. Syncs AOSP source code
REM   6. Builds the complete ROM
REM
REM Just double-click this file and wait for your ROM!
REM ============================================================================

setlocal EnableDelayedExpansion

REM Get script directory (where GlassPorts is located)
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

REM Colors for Windows 10+
for /F "delims=" %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "RED=%ESC%[91m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "BLUE=%ESC%[94m"
set "CYAN=%ESC%[96m"
set "WHITE=%ESC%[97m"
set "NC=%ESC%[0m"

REM Build configuration - modify these as needed
set "AOSP_VERSION=9"
set "PARALLEL_JOBS=8"
set "GLASS_IMAGE_VERSION=XE24"

title GlassPorts Automated Build System

cls
echo.
echo %CYAN%========================================================================%NC%
echo %CYAN%         GlassPorts One-Click Automated Build System%NC%
echo %CYAN%========================================================================%NC%
echo.
echo %WHITE%This script will automatically build GlassPorts for Google Glass.%NC%
echo.
echo %YELLOW%Configuration:%NC%
echo   - AOSP Version: Android %AOSP_VERSION%.0
echo   - Parallel Jobs: %PARALLEL_JOBS%
echo   - Factory Image: %GLASS_IMAGE_VERSION%
echo.
echo %YELLOW%Requirements:%NC%
echo   - Windows 10 version 2004+ or Windows 11
echo   - 16GB+ RAM (32GB recommended)
echo   - 300GB+ free disk space
echo   - Fast internet connection
echo.
echo %YELLOW%The build process will take several hours. You can leave it running.%NC%
echo.

REM Check if running as admin for WSL installation
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %YELLOW%[NOTE]%NC% Not running as Administrator.
    echo       If WSL2 needs to be installed, you will be prompted for elevation.
    echo.
)

pause
echo.

REM ============================================================================
REM Step 1: Check/Install WSL2
REM ============================================================================

echo %BLUE%[STEP 1/7]%NC% Checking WSL2 installation...
echo.

wsl --status >nul 2>&1
if %errorlevel% neq 0 (
    echo %YELLOW%[INFO]%NC% WSL2 not found. Installing...
    echo.

    REM Try to install WSL
    echo %CYAN%Installing WSL2 - this may require a restart...%NC%
    echo.

    powershell -Command "Start-Process wsl -ArgumentList '--install' -Verb RunAs -Wait"

    echo.
    echo %YELLOW%========================================================================%NC%
    echo %YELLOW%WSL2 installation initiated!%NC%
    echo.
    echo %WHITE%Please restart your computer and run this script again.%NC%
    echo %WHITE%After restart, Ubuntu will finish installing automatically.%NC%
    echo %YELLOW%========================================================================%NC%
    echo.
    pause
    exit /b 0
)

REM Check if Ubuntu is installed (use PowerShell to handle Unicode output from wsl -l)
set "UBUNTU_FOUND=0"
for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "(wsl -l -q 2>$null) -join ',' -replace '\x00','' | Select-String -Pattern 'Ubuntu' -Quiet"`) do (
    if "%%i"=="True" set "UBUNTU_FOUND=1"
)

if "%UBUNTU_FOUND%"=="0" (
    REM Double-check using wsl -d to see if Ubuntu actually responds
    wsl -d Ubuntu -e echo "test" >nul 2>&1
    if !errorlevel! equ 0 (
        set "UBUNTU_FOUND=1"
    )
)

if "%UBUNTU_FOUND%"=="0" (
    echo %YELLOW%[INFO]%NC% Ubuntu not found in WSL. Installing...
    wsl --install -d Ubuntu
    echo.
    echo %YELLOW%Please wait for Ubuntu to finish installing, then run this script again.%NC%
    pause
    exit /b 0
)

echo %GREEN%[OK]%NC% WSL2 with Ubuntu is available
echo.

REM ============================================================================
REM Step 2: Convert Windows path to WSL path
REM ============================================================================

echo %BLUE%[STEP 2/7]%NC% Setting up build environment...
echo.

REM Convert Windows path to WSL path
set "WIN_PATH=%SCRIPT_DIR%"
set "WSL_PATH=%WIN_PATH:\=/%"
set "WSL_PATH=%WSL_PATH:C:=/mnt/c%"
set "WSL_PATH=%WSL_PATH:D:=/mnt/d%"
set "WSL_PATH=%WSL_PATH:E:=/mnt/e%"
set "WSL_PATH=%WSL_PATH:F:=/mnt/f%"

echo %WHITE%Windows path: %WIN_PATH%%NC%
echo %WHITE%WSL path: %WSL_PATH%%NC%
echo.

REM ============================================================================
REM Step 3: Install Linux dependencies in WSL
REM ============================================================================

echo %BLUE%[STEP 3/7]%NC% Installing Linux build dependencies...
echo.

REM Fix line endings (Windows may have converted them to CRLF)
wsl bash -c "cd '%WSL_PATH%' && find build -name '*.sh' -exec sed -i 's/\r$//' {} \; 2>/dev/null"

wsl bash -c "cd '%WSL_PATH%' && chmod +x build/tools/*.sh build/tools/*.py 2>/dev/null; bash build/tools/install-deps.sh"

if %errorlevel% neq 0 (
    echo %RED%[ERROR]%NC% Failed to install dependencies
    echo Please check the error messages above and try again.
    pause
    exit /b 1
)

echo.
echo %GREEN%[OK]%NC% Dependencies installed
echo.

REM ============================================================================
REM Step 4: Download and extract Google Glass factory images
REM ============================================================================

echo %BLUE%[STEP 4/7]%NC% Downloading Google Glass factory images...
echo.

wsl bash -c "cd '%WSL_PATH%' && bash build/tools/download-factory-images.sh %GLASS_IMAGE_VERSION%"

if %errorlevel% neq 0 (
    echo %YELLOW%[WARNING]%NC% Factory image download may have had issues.
    echo Continuing with build - some proprietary features may not work.
    echo.
)

echo.
echo %GREEN%[OK]%NC% Factory images processed
echo.

REM ============================================================================
REM Step 5: Initialize and sync AOSP
REM ============================================================================

echo %BLUE%[STEP 5/7]%NC% Initializing AOSP source (this will take a while)...
echo.
echo %YELLOW%[NOTE]%NC% AOSP requires a case-sensitive filesystem.
echo       Source will be stored in WSL at: ~/GlassPorts-aosp
echo.

REM Create the automated build script
echo #!/bin/bash > "%SCRIPT_DIR%\build\temp_build.sh"
echo set -e >> "%SCRIPT_DIR%\build\temp_build.sh"
echo cd "%WSL_PATH%" >> "%SCRIPT_DIR%\build\temp_build.sh"
echo source build/envsetup.sh >> "%SCRIPT_DIR%\build\temp_build.sh"
echo. >> "%SCRIPT_DIR%\build\temp_build.sh"
echo # Select AOSP version >> "%SCRIPT_DIR%\build\temp_build.sh"

REM Map version number to branch
if "%AOSP_VERSION%"=="9" (
    echo export AOSP_BRANCH="android-9.0.0_r61" >> "%SCRIPT_DIR%\build\temp_build.sh"
) else if "%AOSP_VERSION%"=="8" (
    echo export AOSP_BRANCH="android-8.1.0_r81" >> "%SCRIPT_DIR%\build\temp_build.sh"
) else if "%AOSP_VERSION%"=="7" (
    echo export AOSP_BRANCH="android-7.1.2_r39" >> "%SCRIPT_DIR%\build\temp_build.sh"
) else if "%AOSP_VERSION%"=="6" (
    echo export AOSP_BRANCH="android-6.0.1_r81" >> "%SCRIPT_DIR%\build\temp_build.sh"
) else if "%AOSP_VERSION%"=="5" (
    echo export AOSP_BRANCH="android-5.1.1_r38" >> "%SCRIPT_DIR%\build\temp_build.sh"
) else if "%AOSP_VERSION%"=="4" (
    echo export AOSP_BRANCH="android-4.4.4_r2" >> "%SCRIPT_DIR%\build\temp_build.sh"
) else (
    echo export AOSP_BRANCH="android-9.0.0_r61" >> "%SCRIPT_DIR%\build\temp_build.sh"
)

echo. >> "%SCRIPT_DIR%\build\temp_build.sh"
echo echo "Initializing AOSP with branch: $AOSP_BRANCH" >> "%SCRIPT_DIR%\build\temp_build.sh"
echo init_aosp >> "%SCRIPT_DIR%\build\temp_build.sh"
echo. >> "%SCRIPT_DIR%\build\temp_build.sh"
echo echo "Syncing AOSP source..." >> "%SCRIPT_DIR%\build\temp_build.sh"
echo sync_aosp %PARALLEL_JOBS% >> "%SCRIPT_DIR%\build\temp_build.sh"
echo. >> "%SCRIPT_DIR%\build\temp_build.sh"
echo echo "Setting up device tree..." >> "%SCRIPT_DIR%\build\temp_build.sh"
echo setup_device >> "%SCRIPT_DIR%\build\temp_build.sh"
echo. >> "%SCRIPT_DIR%\build\temp_build.sh"
echo echo "Building ROM..." >> "%SCRIPT_DIR%\build\temp_build.sh"
echo build_rom %PARALLEL_JOBS% >> "%SCRIPT_DIR%\build\temp_build.sh"
echo. >> "%SCRIPT_DIR%\build\temp_build.sh"
echo echo "Packaging ROM..." >> "%SCRIPT_DIR%\build\temp_build.sh"
echo package_rom >> "%SCRIPT_DIR%\build\temp_build.sh"

REM Convert line endings for WSL
wsl bash -c "cd '%WSL_PATH%' && sed -i 's/\r$//' build/temp_build.sh && chmod +x build/temp_build.sh"

REM Run the build
wsl bash -c "cd '%WSL_PATH%' && bash build/temp_build.sh"

if %errorlevel% neq 0 (
    echo.
    echo %RED%[ERROR]%NC% Build failed!
    echo Please check the error messages above.
    echo.
    echo Common issues:
    echo   - Not enough disk space (need 300GB+)
    echo   - Not enough RAM (need 16GB+, try closing other apps)
    echo   - Network issues during sync (try running again)
    echo.
    pause
    exit /b 1
)

REM Cleanup temp script
del "%SCRIPT_DIR%\build\temp_build.sh" 2>nul

REM ============================================================================
REM Step 6: Build complete!
REM ============================================================================

echo.
echo %GREEN%========================================================================%NC%
echo %GREEN%                    BUILD COMPLETE!%NC%
echo %GREEN%========================================================================%NC%
echo.
echo %WHITE%Your GlassPorts ROM has been built successfully!%NC%
echo.
echo %CYAN%Output files are located in:%NC%
echo   %SCRIPT_DIR%\out\
echo.
echo %CYAN%To flash to your Google Glass:%NC%
echo   1. Connect Glass via USB
echo   2. Enable USB debugging
echo   3. Run: adb reboot bootloader
echo   4. Run: fastboot flash boot boot.img
echo   5. Run: fastboot flash system system.img
echo   6. Run: fastboot reboot
echo.
echo %YELLOW%Or use the packaged ZIP with custom recovery:%NC%
echo   adb sideload GlassPorts_*.zip
echo.

REM Open output folder
start "" "%SCRIPT_DIR%\out"

echo.
echo Press any key to exit...
pause >nul
exit /b 0
