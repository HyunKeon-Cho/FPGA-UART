@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"

echo ──────────────────────────────── [bat] args check
set "MODULE=%~1"
set "GUI="
if not defined MODULE goto usage
if not "%~3"=="" goto usage
if not "%~2"=="" if /i not "%~2"=="--gui" goto usage
if /i "%~2"=="--gui" set "GUI=1"

echo ──────────────────────────────── [bat] Setup PATH
set "SIM_DIR=%~dp0.behav\%MODULE%"
set "TB_PATH=%~dp0UART\sim\%MODULE%"
set "WCFG_FILE=%TB_PATH%\%MODULE%_sim.wcfg"
set "SNAPSHOT=%MODULE%_behavior_sim"
set "READY_FILE=%SIM_DIR%\prepared.txt"
if not exist "%READY_FILE%" (
    echo Prepared snapshot not found. Run behavior.bat %MODULE% first.
    exit /b 1
)
set "TB_KIND="
set /p TB_KIND=<"%READY_FILE%"
cd /d "%SIM_DIR%"
if errorlevel 1 goto failed

echo ──────────────────────────────── [bat] Simulation
rem Run the prepared snapshot without compiling or elaborating again.
if defined GUI (
    if exist "%WCFG_FILE%" (
        call xsim.bat "%SNAPSHOT%" -gui -view "%WCFG_FILE%"
    ) else (
        call xsim.bat "%SNAPSHOT%" -gui
    )
) else (
    call xsim.bat "%SNAPSHOT%" -runall
)
if errorlevel 1 goto failed
rem Batch UVM runs must reach the TB's explicit success marker.
if not defined GUI if /i "!TB_KIND!"=="UVM" (
    findstr /c:"UART_UVM_PASS" "xsim.log" >nul
    if errorlevel 1 goto failed
)
echo [bat] Results: %SIM_DIR%
exit /b 0

:usage
echo Usage: behavior_sim.bat MODULE [--gui]
exit /b 1

:failed
echo Behavioral simulation failed. See the error above.
exit /b 1
