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
set "UART_IMPL_SELF=%~f0"
set "UART_IMPL_ROOT=%~dp0"
set "UART_IMPL_TOP=%~1"
set "UART_IMPL_BOARD=%~3"
set "UART_IMPL_MODE=%~4"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$taskBody = (Get-Content -LiteralPath $env:UART_IMPL_SELF -Raw -Encoding UTF8) -split '(?m)^# POWERSHELL_PAYLOAD\r?\n', 2; & ([scriptblock]::Create($taskBody[1]))"
exit /b %errorlevel%

:usage
echo Usage: implementation.bat MODULE --board BOARD_DIRECTORY [--gui]
echo Example: implementation.bat UART_rx --board FPGA\cora-z7-07s\board\B.0
exit /b 1

# POWERSHELL_PAYLOAD
$ErrorActionPreference = 'Stop'
$taskExit = 1
$taskTcl = $null
try {
    $taskRoot = (Resolve-Path -LiteralPath $env:UART_IMPL_ROOT).Path
    $taskTop = $env:UART_IMPL_TOP
    if ($taskTop -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
        throw 'MODULE must be a SystemVerilog module name.'
    }
    Write-Host '──────────────────────────────── [bat] Read board'
    $taskBoard = (Resolve-Path -LiteralPath $env:UART_IMPL_BOARD).Path
    $taskBoardXml = Join-Path $taskBoard 'board.xml'
    [xml]$taskBoardInfo = Get-Content -LiteralPath $taskBoardXml -Raw
    $taskDevices = @($taskBoardInfo.board.components.component | Where-Object { $_.type -eq 'fpga' })
    if ($taskDevices.Count -ne 1) { throw 'board.xml must describe exactly one FPGA device.' }
    $taskPart = [string]$taskDevices[0].part_name
    if ($taskPart -notmatch '^[A-Za-z0-9_-]+$') { throw 'Invalid FPGA part_name in board.xml.' }
    $taskCheckpoint = Join-Path $taskRoot ".synth\$taskTop\$taskPart\${taskTop}_synth.dcp"
    if (-not (Test-Path -LiteralPath $taskCheckpoint -PathType Leaf)) {
        throw "Synthesis checkpoint not found. Run systhesis.bat $taskTop --board `"$taskBoard`" first."
    }
    $taskVivado = Get-Command vivado.bat -ErrorAction Stop
    $taskOutput = Join-Path $taskRoot ".imple\$taskTop\$taskPart"
    Write-Host '──────────────────────────────── [bat] Setup output directory'
    New-Item -ItemType Directory -Path $taskOutput -Force | Out-Null
    # Vivado reads a temporary copy; implementation code is maintained below.
    $taskTcl = Join-Path $taskOutput ('run_' + [guid]::NewGuid().ToString('N') + '.tcl')
    $taskCode = @'
lassign $argv root_dir top_name part_name mode
proc impl_step {label} {
    puts "[string repeat \u2500 32] \[bat\] $label"
}
proc implement_uart {root_dir top_name part_name} {
    impl_step "Open checkpoint"
    open_checkpoint [file join $root_dir .synth $top_name $part_name ${top_name}_synth.dcp]
    if {[get_property PART [current_design]] ne $part_name} {
        error "Checkpoint FPGA part does not match board.xml"
    }
    # Preserve constraints from synthesis; do not assign board pins implicitly.
    impl_step "Optimization"
    opt_design
    impl_step "Placement"
    place_design
    write_checkpoint -force ${top_name}_placed.dcp
    impl_step "Physical optimization"
    phys_opt_design
    impl_step "Routing"
    route_design
    impl_step "Reports"
    write_checkpoint -force ${top_name}_impl.dcp
    # Export routed timing models; the simulation script applies SDF explicitly.
    write_verilog -force -mode timesim -sdf_anno false ${top_name}_impl.v
    write_sdf -force ${top_name}_impl.sdf
    report_route_status -file ${top_name}_route_status.rpt
    report_utilization -file ${top_name}_impl_utilization.rpt
    report_timing_summary -report_unconstrained -file ${top_name}_impl_timing.rpt
    report_drc -file ${top_name}_impl_drc.rpt
    puts "\[IMPL_DONE\] top=$top_name part=$part_name output=[pwd]"
}
if {[catch {implement_uart $root_dir $top_name $part_name} message]} {
    puts stderr "\[IMPL_FAILED\] $message"
    if {$mode eq "batch"} { exit 1 }
    return -code error $message
}
'@
    [System.IO.File]::WriteAllText($taskTcl, $taskCode, [System.Text.UTF8Encoding]::new($false))
    $taskMode = if ($env:UART_IMPL_MODE -eq '--gui') { 'gui' } else { 'batch' }
    Write-Host "[BOARD] $($taskBoardInfo.board.display_name)"
    Write-Host "[PART ] $taskPart"
    Write-Host "[TOP  ] $taskTop"
    Write-Host "[DCP  ] $taskCheckpoint"
    Push-Location -LiteralPath $taskOutput
    try {
        Write-Host '──────────────────────────────── [bat] Implementation'
        # Optimize, place and route the existing synthesis checkpoint.
        & $taskVivado.Source -mode $taskMode -source $taskTcl -tclargs $taskRoot $taskTop $taskPart $taskMode
        $taskExit = $LASTEXITCODE
    } finally { Pop-Location }
    if ($taskExit -eq 0) { Write-Host "[RESULT] $taskOutput" }
} catch {
    Write-Host "[IMPL_FAILED] $($_.Exception.Message)"
    $taskExit = 1
} finally {
    if ($taskTcl -and (Test-Path -LiteralPath $taskTcl)) {
        Remove-Item -LiteralPath $taskTcl -Force
    }
}
exit $taskExit
