@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul
echo ──────────────────────────────── [bat] args check
if "%~1"=="" goto usage
if /i not "%~2"=="--board" goto usage
if "%~3"=="" goto usage
if not "%~5"=="" goto usage
if not "%~4"=="" if /i not "%~4"=="--gui" goto usage
echo ──────────────────────────────── [bat] Setup PATH
set "UART_SIM_SELF=%~f0"
set "UART_SIM_ROOT=%~dp0"
set "UART_SIM_TOP=%~1"
set "UART_SIM_BOARD=%~3"
set "UART_SIM_MODE=%~4"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$taskBody = (Get-Content -LiteralPath $env:UART_SIM_SELF -Raw -Encoding UTF8) -split '(?m)^# POWERSHELL_PAYLOAD\r?\n', 2; & ([scriptblock]::Create($taskBody[1]))"
exit /b %errorlevel%

:usage
echo Usage: implementation_sim.bat MODULE --board BOARD_DIRECTORY [--gui]
echo Example: implementation_sim.bat UART_rx --board FPGA\cora-z7-07s\board\B.0
exit /b 1

# POWERSHELL_PAYLOAD
$ErrorActionPreference = 'Stop'
$taskExit = 1
try {
    $taskRoot = (Resolve-Path -LiteralPath $env:UART_SIM_ROOT).Path
    $taskTop = $env:UART_SIM_TOP
    if ($taskTop -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
        throw 'MODULE must be a SystemVerilog module name.'
    }
    Write-Host '──────────────────────────────── [bat] Read board'
    $taskBoard = (Resolve-Path -LiteralPath $env:UART_SIM_BOARD).Path
    $taskBoardXml = Join-Path $taskBoard 'board.xml'
    [xml]$taskBoardInfo = Get-Content -LiteralPath $taskBoardXml -Raw
    $taskDevices = @($taskBoardInfo.board.components.component | Where-Object { $_.type -eq 'fpga' })
    if ($taskDevices.Count -ne 1) { throw 'board.xml must describe exactly one FPGA device.' }
    $taskPart = [string]$taskDevices[0].part_name
    if ($taskPart -notmatch '^[A-Za-z0-9_-]+$') { throw 'Invalid FPGA part_name in board.xml.' }
    $taskNetlist = Join-Path $taskRoot ".imple\$taskTop\$taskPart\${taskTop}_impl.v"
    $taskSdf = Join-Path $taskRoot ".imple\$taskTop\$taskPart\${taskTop}_impl.sdf"
    if (-not (Test-Path -LiteralPath $taskNetlist -PathType Leaf)) {
        throw "Implementation netlist not found. Run implementation.bat $taskTop --board `"$taskBoard`" first."
    }
    if (-not (Test-Path -LiteralPath $taskSdf -PathType Leaf)) {
        throw "Implementation SDF not found. Run implementation.bat $taskTop --board `"$taskBoard`" first."
    }
    $taskTbDir = Join-Path $taskRoot "UART\sim\$taskTop"
    $taskUvmDir = Join-Path $taskRoot 'UART\sim\UVM'
    $taskFileList = Join-Path $taskTbDir "tb_${taskTop}_files.f"
    Write-Host '──────────────────────────────── [bat] Read file list'
    $taskSources = @()
    foreach ($taskLine in Get-Content -LiteralPath $taskFileList) {
        $taskSource = $taskLine.Trim()
        if (-not $taskSource -or $taskSource.StartsWith('#')) { continue }
        # Replace RTL with the routed timing netlist; keep the UVM TB.
        if ($taskSource.Replace('\', '/') -like 'UART/rtl/*') { continue }
        $taskSources += Join-Path $taskRoot $taskSource
    }
    $taskXvlog = Get-Command xvlog.bat -ErrorAction Stop
    $taskXelab = Get-Command xelab.bat -ErrorAction Stop
    $taskXsim = Get-Command xsim.bat -ErrorAction Stop
    $taskVivadoRoot = Split-Path (Split-Path $taskXvlog.Source -Parent) -Parent
    $taskGlbl = Join-Path $taskVivadoRoot 'data\verilog\src\glbl.v'
    if (-not (Test-Path -LiteralPath $taskGlbl -PathType Leaf)) { throw "glbl.v not found: $taskGlbl" }
    $taskSources += $taskNetlist
    $taskSources += $taskGlbl
    $taskOutput = Join-Path $taskRoot ".imple\$taskTop\$taskPart\sim"
    Write-Host '──────────────────────────────── [bat] Setup output directory'
    New-Item -ItemType Directory -Path $taskOutput -Force | Out-Null
    Write-Host "[BOARD] $($taskBoardInfo.board.display_name)"
    Write-Host "[PART ] $taskPart"
    Write-Host "[TOP  ] $taskTop"
    Write-Host "[DUT  ] $taskNetlist"
    Write-Host "[SDF  ] $taskSdf (maximum delays)"
    Push-Location -LiteralPath $taskOutput
    try {
        Write-Host '──────────────────────────────── [bat] Compile'
        # Compile UVM, the routed timing DUT and the global primitive reset.
        $taskCompileArgs = @('--sv', '-L', 'uvm', '--define', 'UART_SYNTH_NETLIST', '-i', $taskUvmDir, '-i', $taskTbDir) + $taskSources
        & $taskXvlog.Source @taskCompileArgs
        if ($LASTEXITCODE -ne 0) { throw 'Netlist/UVM compilation failed.' }
        Write-Host '──────────────────────────────── [bat] Elaboration'
        # Apply maximum SDF delays at the UVM TB's DUT instance.
        $taskSnapshot = "${taskTop}_impl_sim"
        # Keep root=file as one argument through the Windows .bat launcher.
        $taskSdfArg = '"/tb_' + $taskTop + '/dut=' + $taskSdf + '"'
        & $taskXelab.Source "tb_$taskTop" glbl -L uvm -L simprims_ver -L unisims_ver -L unimacro_ver -L secureip --maxdelay --sdfmax $taskSdfArg -s $taskSnapshot --timescale 1ns/1ps -debug typical
        if ($LASTEXITCODE -ne 0) { throw 'Netlist/UVM elaboration failed.' }
        Write-Host '──────────────────────────────── [bat] Simulation'
        # Open the waveform GUI or run the simulation to completion.
        if ($env:UART_SIM_MODE -eq '--gui') {
            & $taskXsim.Source $taskSnapshot -gui
        } else {
            & $taskXsim.Source $taskSnapshot -runall
        }
        $taskExit = $LASTEXITCODE
    } finally { Pop-Location }
    if ($taskExit -eq 0) { Write-Host "[RESULT] $taskOutput" }
} catch {
    Write-Host "[SIM_FAILED] $($_.Exception.Message)"
    $taskExit = 1
}
exit $taskExit
