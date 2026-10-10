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
set "UART_SYN_SELF=%~f0"
set "UART_SYN_ROOT=%~dp0"
set "UART_SYN_TOP=%~1"
set "UART_SYN_BOARD=%~3"
set "UART_SYN_MODE=%~4"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$taskBody = (Get-Content -LiteralPath $env:UART_SYN_SELF -Raw -Encoding UTF8) -split '(?m)^# POWERSHELL_PAYLOAD\r?\n', 2; & ([scriptblock]::Create($taskBody[1]))"
exit /b %errorlevel%

:usage
echo Usage: systhesis.bat MODULE --board BOARD_DIRECTORY [--gui]
echo Example: systhesis.bat UART_rx --board FPGA\cora-z7-07s\board\B.0
exit /b 1

# POWERSHELL_PAYLOAD
$ErrorActionPreference = 'Stop'
$taskExit = 1
$taskTcl = $null
try {
    $taskRoot = (Resolve-Path -LiteralPath $env:UART_SYN_ROOT).Path
    $taskTop = $env:UART_SYN_TOP
    if ($taskTop -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
        throw 'MODULE must be a SystemVerilog module name.'
    }
    Write-Host '──────────────────────────────── [bat] Read board'
    $taskBoard = (Resolve-Path -LiteralPath $env:UART_SYN_BOARD).Path
    $taskBoardXml = Join-Path $taskBoard 'board.xml'
    [xml]$taskBoardInfo = Get-Content -LiteralPath $taskBoardXml -Raw
    $taskDevices = @($taskBoardInfo.board.components.component | Where-Object { $_.type -eq 'fpga' })
    if ($taskDevices.Count -ne 1) { throw 'board.xml must describe exactly one FPGA device.' }
    $taskPart = [string]$taskDevices[0].part_name
    if ($taskPart -notmatch '^[A-Za-z0-9_-]+$') { throw 'Invalid FPGA part_name in board.xml.' }
    $taskBoardRoot = Split-Path (Split-Path $taskBoard -Parent) -Parent
    $taskXdc = Join-Path $taskBoardRoot 'master.xdc'
    if (-not (Test-Path -LiteralPath $taskXdc -PathType Leaf)) {
        throw "Board constraints not found: $taskXdc"
    }
    $taskTopFile = Join-Path $taskRoot "UART\rtl\$taskTop.sv"
    if (-not (Test-Path -LiteralPath $taskTopFile -PathType Leaf)) {
        throw "RTL file not found: $taskTopFile"
    }
    $taskVivado = Get-Command vivado.bat -ErrorAction Stop
    $taskOutput = Join-Path $taskRoot ".synth\$taskTop\$taskPart"
    Write-Host '──────────────────────────────── [bat] Setup output directory'
    New-Item -ItemType Directory -Path $taskOutput -Force | Out-Null
    # Vivado reads a temporary copy; the maintained synthesis code is below.
    $taskTcl = Join-Path $taskOutput ('run_' + [guid]::NewGuid().ToString('N') + '.tcl')
    $taskCode = @'
lassign $argv root_dir top_name part_name mode xdc_file
proc synthesize_uart {root_dir top_name part_name xdc_file} {
    set rtl_dir [file join $root_dir UART rtl]
    set sources [list [file join $rtl_dir ${top_name}.sv]]
    if {$top_name eq "UART_rx"} {
        lappend sources [file join $rtl_dir rx_clock_generator.sv]
        lappend sources [file join $rtl_dir rx_controller.sv]
    }
    read_verilog -sv $sources
    puts "\[bat\] Read constraints: $xdc_file"
    read_xdc $xdc_file
    synth_design -top $top_name -part $part_name
    write_checkpoint -force ${top_name}_synth.dcp
    write_verilog -force -mode funcsim ${top_name}_synth.v
    report_utilization -file ${top_name}_utilization.rpt
    report_timing_summary -file ${top_name}_timing.rpt
    report_drc -file ${top_name}_drc.rpt
    puts "\[SYNTH_DONE\] top=$top_name part=$part_name output=[pwd]"
}
if {[catch {synthesize_uart $root_dir $top_name $part_name $xdc_file} message]} {
    puts stderr "\[SYNTH_FAILED\] $message"
    if {$mode eq "batch"} { exit 1 }
    return -code error $message
}
'@
    [System.IO.File]::WriteAllText($taskTcl, $taskCode, [System.Text.UTF8Encoding]::new($false))
    $taskMode = if ($env:UART_SYN_MODE -eq '--gui') { 'gui' } else { 'batch' }
    Write-Host "[BOARD] $($taskBoardInfo.board.display_name)"
    Write-Host "[PART ] $taskPart"
    Write-Host "[TOP  ] $taskTop"
    Write-Host "[XDC  ] $taskXdc"
    Push-Location -LiteralPath $taskOutput
    try {
        Write-Host '──────────────────────────────── [bat] Synthesis'
        # Synthesize and export the functional simulation netlist.
        & $taskVivado.Source -mode $taskMode -source $taskTcl -tclargs $taskRoot $taskTop $taskPart $taskMode $taskXdc
        $taskExit = $LASTEXITCODE
    } finally { Pop-Location }
    if ($taskExit -eq 0) { Write-Host "[RESULT] $taskOutput" }
} catch {
    Write-Host "[SYNTH_FAILED] $($_.Exception.Message)"
    $taskExit = 1
} finally {
    if ($taskTcl -and (Test-Path -LiteralPath $taskTcl)) {
        Remove-Item -LiteralPath $taskTcl -Force
    }
}
exit $taskExit
