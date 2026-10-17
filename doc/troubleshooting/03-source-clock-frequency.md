# Raising the Source Clock for 921,600 bps

[README](../../README.md#troubleshooting) · [한국어](./03-source-clock-frequency.ko.md) · [Previous: fractional carry](./02-fractional-divider-carry.md)

## Problem and cause

After the carry correction, simulation at **50 MHz / 921,600 bps** exposed another limit: the integer divider setting became zero and the oversampling output stopped toggling.

The fixed divider toggles its output when the integer counter transitions from nonzero to zero. With `div_int = 0`, the counter never becomes nonzero, so that event never occurs.

## Clock selection

The existing configuration calculation uses:

```text
T = baud × 16 × 2
I = floor(source_clock / T) - 1
F = floor(((source_clock mod T) / source_clock) × 65536)
```

For this divider, `I ≥ 1` requires `source_clock ≥ 64 × baud`. At 921,600 bps, the calculated boundary is **58.9824 MHz**. The source clock was raised to **60 MHz**, where `I = 1` and `F = 1111`.

> 설계 비교를 위해 작성·측정한 자료. [RTL, conditions and raw results](../../UART/experiments/clock_generator/README.md).

<p align="center">
  <img src="../img/troubleshooting/03-clock-waveforms.png" alt="Aligned fifty and sixty megahertz simulation traces" width="900">
</p>

## Simulation result

The same corrected RTL was tested with recalculated settings at each source frequency. Input UART timing was independent of the DUT, with a real-valued source-clock period and 1 ps simulation precision.

| Source (MHz) | I | F | Mean 16× period (ns) | Frequency error | RX matches | TX matches |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 50 | 0 | 26881 | Stopped | — | 0/72 | 0/72 |
| 55 | 0 | 30395 | Stopped | — | 0/72 | 0/72 |
| 58 | 0 | 32212 | Stopped | — | 0/72 | 0/72 |
| 58.9824 | 1 | 0 | 67.816 | +0.0012% | 72/72 | 72/72 |
| 60 | 1 | 1111 | 67.814 | +0.0049% | 72/72 | 72/72 |

<p align="center">
  <img src="../img/troubleshooting/03-frequency-boundary.png" alt="Measured source clock boundary and matching byte counts" width="900">
</p>

Below the boundary, no oversampling edges were observed: all 72 expected RX bytes were missing and the first TX acceptance timed out. At the boundary and at 60 MHz, both directions matched **72/72 bytes** without missing/extra bytes or timeouts; reset checks passed. Average output-frequency error was within ±0.1% over 10 ms.

This validates the source-clock change **in simulation only**. The calculated boundary belongs to this divider implementation; it is not a general UART clock requirement or an FPGA timing-closure result.
