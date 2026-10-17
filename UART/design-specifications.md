# Target UART specifications

[README](../README.md) · [Echo testbench](./testbench/echo_testbench.md)

- UART
    - **Supported Baud Rates**: 9,600 / 19,200 / 38,400 / 57,600 / 115,200 / 230,400 / 460,800 / 921,600 bps
    - **Frame Format**: 8-N-1 (8 data bits, no parity, 1 stop bit)
    - **Bit Order**: LSB First
    - **RX Oversampling Rate**: 16×
    - **Baud Rate Generator**: Integer or Fractional Clock Divider
- **FPGA**: Cora Z7-07S (`xc7z007sclg400-1`)
- **SW**: Xilinx Vivado 2025.2, Vitis 2025.2
- **Board application clock frequency**: 60 MHz

## DUT

### Design

- **AXI4-Lite**: Baud rate configuration
- **TX**: Parallel-to-serial conversion with start and stop bits
- **RX**: Serial-to-parallel conversion with three-sample majority voting
- TX and RX share one baud rate generator.

#### Design choices

- **16× oversampling**: Provides finer timing steps to sample RX near the center of each bit.
- **Three-sample majority voting**: Reduces sensitivity to a single erroneous sample caused by a short input glitch.
- **Fractional divider**: Allows finer baud rate adjustment when an integer divider cannot represent the target rate.

<p align="center">
  <img src="../doc/img/block-diagram.png" alt="UART conceptual block diagram" width="800">
</p>

<!-- Timing diagram: add a TX/RX waveform to ../doc/img/ when available. -->

### Resource utilization (Synthesis)

- **Target**: `axi_UART` IP, including AXI4-Lite registers, baud rate generator, TX, and RX
- **Method**: Out-of-context synthesis, Vivado 2025.2

| Resource | Estimation | Available | Utilization |
| --- | ---: | ---: | ---: |
| LUT | 107 | 14,400 | 0.74% |
| FF | 192 | 28,800 | 0.67% |
| BUFG | 0 | 32 | 0.00% |
| LUTRAM | 0 | 6,000 | 0.00% |
| BRAM | 0 | 50 | 0.00% |

<!-- Source: .synth/axi_UART_documentation/axi_UART_utilization_synth.rpt (2026-10-17). -->

### Timing (Synthesis)

- **Source clock constraint**: 16.667 ns (approximately 60 MHz)

| WNS | TNS | WHS | THS |
| ---: | ---: | ---: | ---: |
| 3.301 ns | 0.000 ns | 0.185 ns | 0.000 ns |

Values cover constrained paths; unconstrained paths remain in the report.

<!-- Source: .synth/axi_UART_documentation/axi_UART_timing_synth.rpt (2026-10-17). -->

### Hardware verification

- **Test**: PC ↔ FPGA UART echo
- **Baud rate**: 921,600 bps
- **Result**: PASS in the saved [echo test](./testbench/echo_testbench.md#result) capture
