@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"

echo ──────────────────────────────── [bat] args check
set "MODULE=%~1"
if not defined MODULE goto usage
if not "%~2"=="" goto usage

echo ──────────────────────────────── [bat] Setup PATH
set "SIM_DIR=%~dp0.behav\%MODULE%"
set "TB_PATH=%~dp0UART\sim\%MODULE%"
set "UVM_PATH=%~dp0UART\sim\UVM"
set "FILELIST=%TB_PATH%\tb_%MODULE%_files.f"
set "DUT_FILE=%~dp0UART\rtl\%MODULE%.sv"
set "TB_FILE=%TB_PATH%\tb_%MODULE%.sv"
set "SNAPSHOT=%MODULE%_behavior_sim"
set "READY_FILE=%SIM_DIR%\prepared.txt"
set "TB_KIND=RTL"
set "UVM_ARGS="
if not exist "%TB_FILE%" (
    echo Testbench not found: %TB_FILE%
    exit /b 1
)

echo ──────────────────────────────── [bat] Read file list
set "SOURCES="
if exist "%FILELIST%" (
    set "TB_KIND=UVM"
    set "UVM_ARGS=-L uvm"
    for /f "usebackq eol=# delims=" %%F in ("%FILELIST%") do (
        set SOURCES=!SOURCES! "%~dp0%%~F"
    )
) else (
    if not exist "%DUT_FILE%" (
        echo RTL file not found: %DUT_FILE%
        exit /b 1
    )
    set SOURCES="%DUT_FILE%" "%TB_FILE%"
)

echo ──────────────────────────────── [bat] Setup output directory
if not exist "%SIM_DIR%\" mkdir "%SIM_DIR%"
cd /d "%SIM_DIR%"
if errorlevel 1 goto failed
rem Invalidate the previous ready marker before rebuilding the snapshot.
if exist "%READY_FILE%" del /q "%READY_FILE%"

echo ──────────────────────────────── [bat] Compile
rem Compile RTL and the selected testbench without running simulation.
call xvlog.bat --sv !UVM_ARGS! -i "%UVM_PATH%" -i "%TB_PATH%" !SOURCES!
if errorlevel 1 goto failed

echo ──────────────────────────────── [bat] Elaboration
rem Link modules and create a reusable simulation snapshot.
call xelab.bat "tb_%MODULE%" !UVM_ARGS! -s "%SNAPSHOT%" --timescale 1ns/1ps -debug typical
if errorlevel 1 goto failed
>"%READY_FILE%" echo !TB_KIND!
echo [bat] Prepared: %SNAPSHOT%
echo [bat] Results: %SIM_DIR%
exit /b 0

:usage
echo Usage: behavior.bat MODULE
exit /b 1

:failed
echo Behavioral simulation preparation failed. See the error above.
exit /b 1
