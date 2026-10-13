# FPGA-UART

UART RTL과 UVM 검증 환경을 관리하는 프로젝트입니다. 아래 실행 예시는 **UART_rx**, **Cora Z7-07S** 보드를 기준으로 합니다. 보드 디바이스는 `xc7z007sclg400-1`이며, `--board`로 지정한 디렉터리의 `board.xml`에서 자동으로 읽습니다.

## 1. 파일 구조

```text
FPGA-UART/
├── FPGA/
│   └── cora-z7-07s/
│       ├── master.xdc                 # 보드 핀·클록 제약
│       └── board/B.0/
│           ├── board.xml              # 보드 정보와 FPGA 디바이스명
│           ├── part0_pins.xml          # 보드 핀 정보
│           └── preset.xml              # 보드 설정
├── UART/
│   ├── rtl/
│   │   ├── UART_rx.sv                 # RX 최상위 모듈
│   │   ├── rx_clock_generator.sv      # RX 클록 생성
│   │   ├── rx_controller.sv           # RX 제어
│   │   ├── top_UART.sv
│   │   ├── tx_UART.sv
│   │   ├── axi_UART.sv
│   │   └── axi_lite_reg.v
│   └── sim/
│       ├── UART_rx/
│       │   ├── tb_UART_rx.sv          # DUT 연결, 클록·리셋, UVM 실행
│       │   ├── tb_UART_rx_pkg.sv      # RX UVM 패키지
│       │   ├── tb_UART_rx_files.f     # 컴파일 파일 목록
│       │   ├── uvm_UART_rx_if.sv      # RX 인터페이스
│       │   ├── uvm_UART_rx_driver.svh
│       │   ├── uvm_UART_rx_monitor.svh
│       │   └── UART_rx_sim.wcfg       # 파형 표시 설정
│       ├── UVM/
│       │   ├── UART_pkg.sv
│       │   ├── UART_item.svh
│       │   ├── UART_observation.svh
│       │   ├── UART_sequence.svh
│       │   ├── UART_sequencer.svh
│       │   ├── UART_agent.svh
│       │   ├── UART_env.svh
│       │   ├── UART_scoreboard.svh
│       │   └── UART_test.svh
│       └── rx_controller/
│           ├── tb_rx_controller.sv    # 일반 SystemVerilog TB
│           └── rx_controller_sim.wcfg
├── doc/
│   ├── architecture.png
│   └── UART_blockDiagram.png
├── behavior.bat                      # RTL/TB 컴파일 및 snapshot 생성
├── behavior_sim.bat                  # Behavioral 시뮬레이션
├── systhesis.bat                     # 합성 및 기능 netlist 생성
├── systhesis_sim.bat                 # 합성 후 기능 시뮬레이션
├── implementation.bat               # 배치·배선 및 timing netlist/SDF 생성
├── implementation_sim.bat           # 배치·배선 후 타이밍 시뮬레이션
├── .gitignore
└── README.md
```

실행 결과는 아래 폴더에 생성되며 Git 추적에서 제외합니다.

| 단계 | 저장 경로 |
| --- | --- |
| Behavioral 준비·시뮬레이션 | `.behav/UART_rx/` |
| 합성 | `.synth/UART_rx/xc7z007sclg400-1/` |
| 합성 후 시뮬레이션 | `.synth/UART_rx/xc7z007sclg400-1/sim/` |
| Implementation | `.imple/UART_rx/xc7z007sclg400-1/` |
| Implementation 후 시뮬레이션 | `.imple/UART_rx/xc7z007sclg400-1/sim/` |

## 2. 설계 이미지

### 전체 시스템 구성

PC의 PySerial, Cora Z7의 PS, UART 연결과 FIFO·AXI4-Stream·FFT 블록의 연결을 나타낸 구성도입니다. 현재 UART_rx 실행 예시보다 넓은 시스템 설계 범위를 표현합니다.

![전체 시스템 구성](doc/architecture.png)

### UART 블록 구성

AXI4-Lite 제어와 UART RX/TX 내부의 클록 생성기, 제어기, 데이터 경로를 나타낸 블록 구성도입니다.

![UART 블록 구성](doc/UART_blockDiagram.png)

## 3. BAT 실행 방법

Windows에서 Vivado 도구(`vivado`, `xvlog`, `xelab`, `xsim`)가 PATH에 등록된 터미널을 사용합니다. 아래 명령은 프로젝트 루트에서 실행합니다. 기존 검증에는 Vivado 2022.1을 사용했습니다.

### Behavioral 검증

먼저 RTL과 UVM TB를 컴파일하고 simulation snapshot을 생성합니다. 준비 단계에서는 시뮬레이션을 실행하지 않습니다.

```powershell
.\behavior.bat UART_rx
```

준비된 snapshot을 실행합니다. RTL 또는 TB를 수정하면 `behavior.bat`을 다시 실행해야 합니다.

```powershell
.\behavior_sim.bat UART_rx
```

현재 UART_rx TB는 50 MHz 클록, 9600 baud, 8비트 데이터·패리티 없음·정지 비트 1개로 랜덤 32프레임을 전송합니다. scoreboard가 기대값과 수신값을 비교하며 최종 결과는 `RESULT: PASS / FAIL`로 표시합니다.

통신 속도는 `tb_UART_rx.sv`의 `UART_BAUD_RATE`만 변경합니다. 드라이버의 비트 길이와 DUT의 정수·소수 분주값은 이 값에서 자동 계산합니다. 비트 길이는 시스템 클록 단위로 올림하며, 9600 baud에서는 5209클록(104.18 µs)입니다.

프레임 수와 채널 조건도 TB의 `TEST_N`, `CHANNEL_SKEW_RATE`, `CHANNEL_NOISE_RATE`로 설정합니다. 두 rate 값은 0.1% 단위이며, skew는 매 비트에 ±방향으로 적용하고 noise는 매 시스템 클록에서 입력을 반전할 확률입니다. 기본값은 skew `50`(±5%), noise `0`입니다. skew의 허용 범위는 0~999, noise는 기존 범위인 0~100(최대 10%)입니다. TB에서 UVM 설정으로 드라이버에 전달합니다.

전체 제한 시간은 `13 × TEST_N × MAX_BIT_PERIOD + 16 × BIT_PERIOD`입니다. `MAX_BIT_PERIOD`는 최대 양의 skew를 적용한 뒤 시스템 클록 단위로 올린 비트 길이입니다. 프레임당 8N1의 10비트와 최대 idle 3비트, 마지막 수신 대기 및 여유 시간을 포함하며 기본 32프레임·±5% skew의 제한 시간은 약 47.18 ms입니다.

`behavior.bat`은 `tb_<모듈명>_files.f`가 있으면 UVM 방식으로 준비하고, 없으면 해당 RTL과 일반 TB를 사용합니다.

### TX Behavioral 검증

TX 검증은 RX TB와 같은 `top_UART`를 DUT로 연결합니다. TX 인터페이스와 DUT는 50 MHz 기준 클록을 사용하며, baud 분주값은 RX TB와 같은 방식으로 계산해 DUT에 전달합니다. RX 입력은 idle high로 고정합니다. `tb_UART_tx.sv`의 `UART_BAUD_RATE`, `OVERSAMPLING_RATE`, `TEST_N`으로 조건을 설정합니다.

```powershell
.\behavior.bat UART_tx
.\behavior_sim.bat UART_tx
```

드라이버는 `ready=1`을 확인한 뒤 `tx_data`와 `wr_en=1`을 구동하고, DUT가 `ready=0`으로 요청 수락을 알릴 때까지 유지합니다. `ready=0`을 관찰하면 `wr_en`을 내립니다. 12비트 시간 동안 요청이 수락되지 않으면 `TX_ACCEPT_TIMEOUT`으로 실패 처리합니다. 실제 시작 비트를 확인한 뒤 10비트의 프레임 시간과 0~3비트의 랜덤 idle 간격을 기다립니다. 모니터는 `txd`의 시작 에지를 기준으로 각 비트의 중앙을 관찰해 8N1 프레임을 복원하며, DUT 내부 상태는 참조하지 않습니다. RX와 같은 공통 시퀀스로 기본 32프레임의 랜덤 데이터를 전송합니다.

TX 전용 scoreboard는 데이터 불일치와 X/Z를 오류로 처리하고, 누락·중복 수신도 검사합니다. 모니터는 리셋 후 idle, 시작 비트, 정지 비트를 검사합니다. `ready` 대기와 전체 실행에 제한 시간이 있으며, 오류가 없을 때만 `UART_UVM_PASS`를 출력합니다. TX 출력에는 RX 채널의 skew/noise 설정을 적용하지 않습니다.

TB의 설정·클록·UVM·DUT·실행·리셋·timeout 구성은 RX TB 형식을 따릅니다. agent, env, test, 시퀀스는 RX와 같은 공통 클래스를 사용합니다. scoreboard의 큐·집계·누락 검사는 공통 구현을 상속하며, TX 패키지에 정의한 불일치 오류 보고만 factory override로 선택합니다.

`top_UART`의 TX 연결 문법과 baud 클록 경로가 유효해야 실제 DUT 검증을 실행할 수 있습니다. 이 TB 변경에 RTL 수정과 TX 합성 후·배치배선 후 실행 스크립트 정리는 포함하지 않습니다.

### RX 합성 및 합성 후 시뮬레이션

`UART_rx`는 테스트 이름이며 TB의 DUT는 `top_UART`입니다. 합성 시 `top_UART`, `clock_generator`, `UART_rx`, `rx_controller`를 읽고 `top_UART`를 최상위로 합성합니다. 보드 디렉터리의 두 단계 위에 있는 `master.xdc`를 적용하고, 합성 checkpoint(`UART_rx_synth.dcp`), 기능 netlist(`UART_rx_synth.v`)와 자원·타이밍·DRC 보고서를 저장합니다. 기존 `UART_rx` 단독 합성 결과는 현재 TB와 호환되지 않으므로 다시 합성해야 합니다.

```powershell
.\systhesis.bat UART_rx --board FPGA\cora-z7-07s\board\B.0
```

저장된 합성 netlist로 같은 UVM TB를 실행합니다. 이 단계는 합성을 다시 수행하지 않으며 배선 지연을 반영하지 않는 기능 시뮬레이션입니다.

```powershell
.\systhesis_sim.bat UART_rx --board FPGA\cora-z7-07s\board\B.0
```

### Implementation 및 배선 후 시뮬레이션

합성 checkpoint를 입력으로 최적화·배치·물리 최적화·배선을 수행합니다. 배선 완료 checkpoint(`UART_rx_impl.dcp`), timing netlist(`UART_rx_impl.v`), 지연 파일(`UART_rx_impl.sdf`)과 배선 상태·자원·타이밍·DRC 보고서를 저장합니다. Bitstream 생성은 포함하지 않습니다.

```powershell
.\implementation.bat UART_rx --board FPGA\cora-z7-07s\board\B.0
```

배선 netlist와 SDF의 최대 지연을 DUT에 적용해 UVM 타이밍 시뮬레이션을 실행합니다. 이 단계는 합성이나 implementation을 다시 수행하지 않습니다.

```powershell
.\implementation_sim.bat UART_rx --board FPGA\cora-z7-07s\board\B.0
```

RTL 또는 XDC를 수정했다면 합성을 다시 수행하고, 배선 후 검증에는 implementation도 다시 수행해야 합니다. 합성·implementation 코드는 BAT 안에 포함되어 있으며 실행에 사용하는 임시 Tcl 파일은 종료 후 삭제합니다.

### GUI 실행

`behavior.bat`을 제외한 나머지 BAT는 `--gui`를 지원합니다. 합성·implementation은 실행 결과를 Vivado GUI에서 확인하며, 시뮬레이션 GUI는 **Run All**로 실행합니다.

```powershell
.\behavior_sim.bat UART_rx --gui
.\systhesis.bat UART_rx --board FPGA\cora-z7-07s\board\B.0 --gui
.\systhesis_sim.bat UART_rx --board FPGA\cora-z7-07s\board\B.0 --gui
.\implementation.bat UART_rx --board FPGA\cora-z7-07s\board\B.0 --gui
.\implementation_sim.bat UART_rx --board FPGA\cora-z7-07s\board\B.0 --gui
```

### 클록 설정

보드 기본 외부 클록은 125 MHz이며 TB의 50 MHz 클록과는 별도입니다. 현재 `master.xdc`의 활성 `create_clock`은 6 ns 주기로 되어 있습니다. 이 값은 타이밍 분석 목표이며 실제 보드 클록을 변경하지 않습니다. 내부 `rx_clk` 및 나머지 입출력 제약은 별도로 정의해야 합니다.
