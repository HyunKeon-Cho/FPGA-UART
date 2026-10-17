# FPGA UART

<p align="center">
  <img src="./doc/img/device.png" alt="FPGA UART test setup" width="400">
</p>

## Skills

- **VHDL** : SystemVerilog, UVM, Python(testbench)
- **SW** : Xilinx Vivado 2025.2, Vitis 2025.2
- **FPGA** : Cora z7-07s

## Design Result ([specifications](./UART/design-specifications.md))

- UART
    - **Supported Baud Rates**: 9,600 / 19,200 / 38,400 / 57,600 / 115,200 / 230,400 / 460,800 / 921,600 bps
    - **RX Oversampling Rate**: 16×
    - **Baud Rate Generator**: Integer or Fractional Clock Divider
- **clock freqency** : 60Hz

### Resouce utiliation (Synthsis)

| Resource | Estimation | Available | Utilization |
| --- | ---: | ---: | ---: |
| LUT | 107 | 14,400 | 0.74% |
| FF | 192 | 28,800 | 0.67% |
| BUFG | 2 | 32 | 6.25% |
| LUTRAM | 0 | 6,000 | 0.00% |
| BRAM | 0 | 50 | 0.00% |

### Timing

<!-- wave image -->

## Troubleshooting

## AI Usage

- **model** : ChatGPT, GPT6.1 Sol Medium
- Generated files (only AI)

  ```text
  UART/sim/
  ├── UVM                       (AI)
  ├── UART_rx                   (AI)
  ├── UART_tx                   (Human)
  └── rx_controller             (Human) 
  utils/        
  ├── behavior.bat              (Human)
  ├── behavior_sim.bat          (Human)
  ├── synthesis.bat             (AI)
  ├── synthesis_sim.bat         (AI)
  ├── implementation.bat        (AI)
  └── implementation_sim.bat    (AI)
  ```

## Testbench, echo test ([testbench](.\UART\testbench\echo_testbench.md))

### Envirment

- Windows 11
- **Window to FPGA** : CP2102

### Result

- **Baud Rate** : 921,600 bps

<p align="center">
  <img src="./doc/img/testbench_921600.png" alt="UART echo test result at 921,600 bps" width="900">
</p>
