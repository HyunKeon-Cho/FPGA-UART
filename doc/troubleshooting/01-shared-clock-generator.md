# Sharing the Clock Generator

[README](../../README.md#troubleshooting) · [한국어](./01-shared-clock-generator.ko.md) · [Next: fractional carry](./02-fractional-divider-carry.md)

## Design decision

The initial idea was to give RX and TX separate timing generators and assert a trigger only when sampling or shifting was needed. RX and TX could operate independently, and fewer timing-output transitions were intended to reduce switching activity. Concern about duplicated resources led to the current shared generator, which supplies a complete 16× oversampling clock.

<p align="center">
  <img src="../img/troubleshooting/01-architectures.png" alt="Three UART timing architectures" width="900">
</p>

## Comparison

> 설계 비교를 위해 작성·측정한 자료. [RTL, conditions and raw results](../../UART/experiments/clock_generator/README.md).

Three core-only implementations were compared on `xc7z007sclg400-1`: 50 MHz input, 115,200 bps, identical 16-bit integer/fractional settings and Vivado 2025.2 OOC synthesis. Baud settings remain programmable. AXI registers and board peripherals are excluded.

The new enable model uses separate active timing engines, three-sample RX voting and source-clock enables. Its control logic differs from the existing generated-clock implementation; its resource difference therefore covers the whole architecture.

| Architecture | LUT | FF | BUFG |
| --- | ---: | ---: | ---: |
| Shared 16x | 91 | 88 | 0 |
| Independent 16x | 91 | 88 | 0 |
| Independent enables | 197 | 117 | 0 |

Vivado merged the two identical 16× generators into **one 34-FF timing bank**. Explicit sharing and duplicated RTL consequently produced the same utilization. The comparison does **not** establish an area reduction from sharing alone. The enable model used more resources in this implementation.

<p align="center">
  <img src="../img/troubleshooting/01-timing.png" alt="Measured clock and enable timing outputs" width="900">
</p>

## Activity and result

All three architectures matched **72/72 bytes in each active direction**, with no missing/extra bytes or timeouts, across RX-only, TX-only and full-duplex tests. Idle and reset checks also passed.

| 10 ms condition | Shared clock: RX / TX transitions | Enables: RX / TX transitions |
| --- | ---: | ---: |
| Idle | 36,864 / 36,864 | 0 / 0 |
| RX only | 36,864 / 36,864 | 5,760 / 0 |
| TX only | 36,864 / 36,864 | 0 / 1,584 |
| Full duplex | 36,864 / 36,864 | 5,760 / 1,584 |

<p align="center">
  <img src="../img/troubleshooting/01-activity.png" alt="Selected timing output transitions over ten milliseconds" width="900">
</p>

RX/TX columns count each consumer's timing signal. They refer to the same physical net in the shared design and must not be added as two clock nets. Independent 16× RTL produced the same per-consumer counts. The enable model stops inactive timing engines and emits one-source-cycle pulses at RX sampling/decision and TX bit-boundary events.

These are **selected RTL signal transitions, not power measurements**. Source-clock distribution, internal arithmetic, routing and physical implementation are outside this metric. The shared structure remains a compact implementation; the enable model demonstrates a resource/activity tradeoff rather than a proven power saving. Synthesis reports contain unconstrained paths, so no timing-closure claim is made.
