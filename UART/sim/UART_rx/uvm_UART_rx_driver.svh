// 드라이버: 트랜잭션을 시작 비트·데이터 비트·정지 비트의 UART 입력 파형으로 바꾼다.
class driver extends uvm_driver #(item);

    `uvm_component_utils(driver)

    virtual UART_rx_if vif;

    uvm_analysis_port #(item) expected_ap;

    int channel_skew_rate = 0;    // 비트 길이 최대 +5%
    int channel_noise_rate = 1; // 클록당 입력 반전 확률 10%
    bit indata = 1'b1;           // UART idle 상태

    // 생성자
    function new(string name, uvm_component parent);
        super.new(name, parent);
        expected_ap = new("expected_ap", this);
    endfunction

    // 설정 단계: 인터페이스 핸들을 가져온다.
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual UART_rx_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "UART interface is missing")

        if (channel_skew_rate < 0)
            `uvm_fatal("SKEW", "channel_skew_rate must be non-negative")

        if (channel_noise_rate < 0 || channel_noise_rate > 100)
            `uvm_fatal("NOISE", "channel_noise_rate must be between 0 and 100")
    endfunction

    // 지정된 비트 수만큼 구동하며 skew와 noise를 적용한다.
    task clock(int cycles);
        for (int i = 0; i < cycles; i++) begin
            real channel_skew;
            int channel_noise;

            // 0%, 1%, ..., channel_skew_rate% 중 하나를 선택한다.
            channel_skew =
                $urandom_range(channel_skew_rate, 0) / 100.0;

            for (int j = 0;
                 j < vif.bit_cycles * (1.0 + channel_skew);
                 j++) begin

                channel_noise = $urandom_range(999, 0);

                // 내부 기준값은 유지하고 실제 입력만 확률적으로 반전한다.
                vif.cb.indata <=
                    (channel_noise < channel_noise_rate)
                    ? ~indata : indata;

                @(vif.cb);
            end
        end
    endtask

    // UART 한 비트 구동
    task drive_bit(bit value);
        indata = value;
        clock(1);
    endtask

    // 실행 단계
    task run_phase(uvm_phase phase);
        item req;

        // 리셋 중에는 UART 입력을 idle 상태로 유지한다.
        indata = 1'b1;
        vif.cb.indata <= indata;

        // X/Z를 리셋 해제 상태로 인정하지 않는다.
        do
            @(vif.cb);
        while (vif.cb.nrst !== 1'b1);

        if (vif.bit_cycles == 0)
            `uvm_fatal("TIMING", "bit_cycles must be positive")

        forever begin
            seq_item_port.get_next_item(req);
            expected_ap.write(req);

            // 시작 비트
            drive_bit(1'b0);

            // 데이터: 최하위 비트부터 전송
            for (int i = 0; i < 8; i++)
                drive_bit(req.data[i]);

            // 정지 비트
            drive_bit(1'b1);

            // 프레임 사이 idle 구간에도 skew와 noise를 적용한다.
            clock(req.gap_bits);

            seq_item_port.item_done();
        end
    endtask

endclass