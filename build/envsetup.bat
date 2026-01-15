@echo off
REM GlassPorts Build Environment Setup for Windows
REM Cross-platform build system for porting AOSP to Google Glass Rev 1
REM
REM This script sets up the build environment on Windows using WSL2 or Cygwin

setlocal EnableDelayedExpansion

REM Configuration
set "GLASSPORTS_ROOT=%~dp0.."
set "GLASSPORTS_BUILD=%GLASSPORTS_ROOT%\build"
set "GLASSPORTS_OUT=%GLASSPORTS_ROOT%\out"

REM Colors (Windows 10+)
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

echo.
echo %BLUE%================================================%NC%
echo %BLUE%       GlassPorts Build System - Windows        %NC%
echo %BLUE%================================================%NC%
echo.

goto :main

:log_info
echo %BLUE%[INFO]%NC% %~1
goto :eof

:log_success
echo %GREEN%[SUCCESS]%NC% %~1
goto :eof

:log_warning
echo %YELLOW%[WARNING]%NC% %~1
goto :eof

:log_error
echo %RED%[ERROR]%NC% %~1
goto :eof

:check_wsl
call :log_info "Checking for WSL2..."
wsl --status >nul 2>&1
if %errorlevel% equ 0 (
    call :log_success "WSL2 is available"
    set "BUILD_BACKEND=wsl"
    goto :eof
)
call :log_warning "WSL2 not found"
set "BUILD_BACKEND=none"
goto :eof

:check_cygwin
call :log_info "Checking for Cygwin..."
if exist "C:\cygwin64\bin\bash.exe" (
    call :log_success "Cygwin found"
    set "BUILD_BACKEND=cygwin"
    set "CYGWIN_PATH=C:\cygwin64"
    goto :eof
)
if exist "C:\cygwin\bin\bash.exe" (
    call :log_success "Cygwin found"
    set "BUILD_BACKEND=cygwin"
    set "CYGWIN_PATH=C:\cygwin"
    goto :eof
)
call :log_warning "Cygwin not found"
goto :eof

:check_git_bash
call :log_info "Checking for Git Bash..."
where git >nul 2>&1
if %errorlevel% equ 0 (
    call :log_success "Git is available"
    goto :eof
)
call :log_error "Git not found - please install Git for Windows"
goto :eof

:check_java
call :log_info "Checking for Java..."
where java >nul 2>&1
if %errorlevel% equ 0 (
    java -version 2>&1 | findstr /i "version" >nul
    if %errorlevel% equ 0 (
        call :log_success "Java is available"
        goto :eof
    )
)
call :log_error "Java not found - please install JDK 8+"
goto :eof

:check_python
call :log_info "Checking for Python..."
where python >nul 2>&1
if %errorlevel% equ 0 (
    python --version 2>&1 | findstr /i "Python 3" >nul
    if %errorlevel% equ 0 (
        call :log_success "Python 3 is available"
        goto :eof
    )
)
call :log_warning "Python 3 not found - some features may not work"
goto :eof

:check_dependencies
call :log_info "Checking build dependencies..."
echo.

call :check_wsl
call :check_cygwin
call :check_git_bash
call :check_java
call :check_python

echo.
if "%BUILD_BACKEND%"=="none" (
    call :log_error "No suitable build backend found!"
    call :log_info "Please install WSL2 (recommended) or Cygwin"
    echo.
    echo To install WSL2:
    echo   1. Open PowerShell as Administrator
    echo   2. Run: wsl --install
    echo   3. Restart your computer
    echo   4. Install Ubuntu from Microsoft Store
    echo.
    goto :eof
)
call :log_success "Build backend: %BUILD_BACKEND%"
goto :eof

:show_menu
echo.
echo Available options:
echo   1. Check dependencies
echo   2. Select AOSP version
echo   3. Initialize AOSP source
echo   4. Sync AOSP source
echo   5. Setup device tree
echo   6. Build ROM
echo   7. Clean build
echo   8. Package ROM
echo   9. Full build (all steps)
echo   0. Exit
echo.
set /p "choice=Select option [0-9]: "
goto :eof

:run_in_wsl
wsl bash -c "cd '%GLASSPORTS_ROOT:\=/%' && source build/envsetup.sh && %~1"
goto :eof

:run_in_cygwin
"%CYGWIN_PATH%\bin\bash.exe" -c "cd '%GLASSPORTS_ROOT:\=/%' && source build/envsetup.sh && %~1"
goto :eof

:execute_command
if "%BUILD_BACKEND%"=="wsl" (
    call :run_in_wsl "%~1"
) else if "%BUILD_BACKEND%"=="cygwin" (
    call :run_in_cygwin "%~1"
) else (
    call :log_error "No build backend available"
)
goto :eof

:select_aosp_version
echo.
echo Available AOSP versions for Google Glass:
echo   1. Android 9.0 (Pie)       - API 28
echo   2. Android 8.1 (Oreo MR1)  - API 27
echo   3. Android 8.0 (Oreo)      - API 26
echo   4. Android 7.1 (Nougat)    - API 25
echo   5. Android 7.0 (Nougat)    - API 24
echo   6. Android 6.0 (Marshmallow) - API 23
echo   7. Android 5.1 (Lollipop)  - API 22
echo   8. Android 5.0 (Lollipop)  - API 21
echo   9. Android 4.4 (KitKat)    - API 19 (Original Glass OS base)
echo.
set /p "ver_choice=Select version [1-9]: "

if "%ver_choice%"=="1" set "AOSP_BRANCH=android-9.0.0_r61"
if "%ver_choice%"=="2" set "AOSP_BRANCH=android-8.1.0_r81"
if "%ver_choice%"=="3" set "AOSP_BRANCH=android-8.0.0_r51"
if "%ver_choice%"=="4" set "AOSP_BRANCH=android-7.1.2_r39"
if "%ver_choice%"=="5" set "AOSP_BRANCH=android-7.0.0_r36"
if "%ver_choice%"=="6" set "AOSP_BRANCH=android-6.0.1_r81"
if "%ver_choice%"=="7" set "AOSP_BRANCH=android-5.1.1_r38"
if "%ver_choice%"=="8" set "AOSP_BRANCH=android-5.0.2_r3"
if "%ver_choice%"=="9" set "AOSP_BRANCH=android-4.4.4_r2"

if defined AOSP_BRANCH (
    call :log_success "Selected AOSP branch: %AOSP_BRANCH%"
) else (
    call :log_error "Invalid selection"
)
goto :eof

:full_build
call :log_info "Starting full build process..."
call :check_dependencies
if "%BUILD_BACKEND%"=="none" goto :eof
call :select_aosp_version
call :execute_command "init_aosp"
call :execute_command "sync_aosp 4"
call :execute_command "setup_device"
call :execute_command "build_rom"
call :execute_command "package_rom"
call :log_success "Full build complete!"
goto :eof

:main
call :check_dependencies

:menu_loop
call :show_menu

if "%choice%"=="1" call :check_dependencies
if "%choice%"=="2" call :select_aosp_version
if "%choice%"=="3" call :execute_command "init_aosp"
if "%choice%"=="4" call :execute_command "sync_aosp 4"
if "%choice%"=="5" call :execute_command "setup_device"
if "%choice%"=="6" call :execute_command "build_rom"
if "%choice%"=="7" call :execute_command "clean_build"
if "%choice%"=="8" call :execute_command "package_rom"
if "%choice%"=="9" call :full_build
if "%choice%"=="0" goto :end

goto :menu_loop

:end
echo.
call :log_info "Goodbye!"
endlocal
