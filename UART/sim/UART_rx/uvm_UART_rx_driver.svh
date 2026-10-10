// 드라이버: 트랜잭션을 시작 비트·데이터 비트·정지 비트의 UART 입력 파형으로 바꾼다.
class driver extends uvm_driver #(item);

    `uvm_component_utils(driver)

    virtual UART_rx_if vif;

    // 전송 예정 데이터를 스코어보드에 알려 주는 분석 포트이다.
    uvm_analysis_port #(item) expected_ap;

    // 생성자
    function new(string name, uvm_component parent);
        super.new(name, parent);

        expected_ap = new("expected_ap", this);
    endfunction

    // 설정 단계: 인터페이스 또는 하위 컴포넌트 준비
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // TB가 config_db에 등록한 인터페이스 핸들을 받아 실제 신호에 접근한다.
        if (!uvm_config_db#(virtual UART_rx_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "UART interface is missing")
    endfunction

    // UART 한 비트 구동
    task drive_bit(bit value);
        // 한 비트를 구동한 후 bit_cycles개의 클록 이벤트 동안 값을 유지한다.
        vif.cb.indata <= value;
        repeat (vif.bit_cycles) @(vif.cb);
    endtask

    // 실행 단계
    task run_phase(uvm_phase phase);
        item req;

        // 리셋 해제를 확인한 뒤 전송을 시작한다. !==는 X/Z도 해제 상태로 인정하지 않는다.
        do
            @(vif.cb);
        while (vif.cb.nrst !== 1'b1);

        if (vif.bit_cycles == 0)
            `uvm_fatal("TIMING", "bit_cycles must be positive")

        forever begin
            // get_next_item과 item_done이 한 쌍이다. 완료를 알려야 시퀀스가 다음 항목으로 진행한다.
            seq_item_port.get_next_item(req);
            expected_ap.write(req);

            drive_bit(0); // 시작 비트는 0
            // 최하위 비트부터 전송한다.
            for (int i = 0; i < 8; i++)
                drive_bit(req.data[i]);

            drive_bit(1); // 정지 비트 한 개는 1

            repeat (req.gap_bits * vif.bit_cycles) @(vif.cb);

            seq_item_port.item_done();
        end
    endtask

endclass
