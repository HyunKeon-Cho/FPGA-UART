`timescale 1ns/1ps
module tb_UART2PS;
    logic clk = 0;
    always #10 clk = ~clk;
    logic nrst = 0;
    logic rxd = 1, txd;
    logic [31:0] sdata = 0, mdata;
    logic [3:0] skeep = 15, mkeep;
    logic slast = 0, svalid = 0, sready, mlast, mvalid, mready = 0;
    logic [31:0] awaddr = 0, wdata = 0, araddr = 0, rdata;
    logic awvalid = 0, awready, wvalid = 0, wready, bvalid;
    logic arvalid = 0, arready, rvalid;
    logic [1:0] bresp, rresp;
    logic overflow;
    logic [2:0] tx_count, rx_count;
    localparam time BIT_TIME = 21120ns; // 50MHz / (2 * (32+1) * 16)
    byte tx_expected[$];
    byte rx_expected[$];
    int tx_seen = 0, rx_seen = 0;

    axi_UART2PS #(.TX_FIFO_DEPTH(5), .RX_FIFO_DEPTH(5), .RX_PACKET_WORDS(3)) dut (
        .uart_rxd(rxd), .uart_txd(txd), .s_axi_aclk(clk), .s_axi_aresetn(nrst),
        .s_axis_tdata(sdata), .s_axis_tkeep(skeep), .s_axis_tlast(slast),
        .s_axis_tvalid(svalid), .s_axis_tready(sready),
        .m_axis_tdata(mdata), .m_axis_tkeep(mkeep), .m_axis_tlast(mlast),
        .m_axis_tvalid(mvalid), .m_axis_tready(mready),
        .s_axi_awaddr(awaddr), .s_axi_awprot(3'b0), .s_axi_awvalid(awvalid), .s_axi_awready(awready),
        .s_axi_wdata(wdata), .s_axi_wstrb(4'hf), .s_axi_wvalid(wvalid), .s_axi_wready(wready),
        .s_axi_bresp(bresp), .s_axi_bvalid(bvalid), .s_axi_bready(1'b1),
        .s_axi_araddr(araddr), .s_axi_arprot(3'b0), .s_axi_arvalid(arvalid), .s_axi_arready(arready),
        .s_axi_rdata(rdata), .s_axi_rresp(rresp), .s_axi_rvalid(rvalid), .s_axi_rready(1'b1),
        .rx_overflow(overflow), .tx_fifo_count(tx_count), .rx_fifo_count(rx_count)
    );

    task configure_baud;
        @(negedge clk); awaddr = 32'h60000000; awvalid = 1;
        do @(posedge clk); while (!awready);
        @(negedge clk); awvalid = 0; wdata = 32'h00200000; wvalid = 1;
        do @(posedge clk); while (!wready);
        @(negedge clk); wvalid = 0;
        wait(bvalid); @(negedge clk);
        araddr = 32'h60000000; arvalid = 1;
        do @(posedge clk); while (!arready);
        @(negedge clk); arvalid = 0;
        wait(rvalid);
        if (rdata !== 32'h00200000 || rresp !== 0) $fatal(1, "baud readback");
    endtask

    task send_dma(input logic [31:0] word_data, input logic [3:0] keep, input bit last);
        @(negedge clk); sdata = word_data; skeep = keep; slast = last; svalid = 1;
        do @(posedge clk); while (!sready);
        @(negedge clk); svalid = 0;
    endtask

    task send_uart(input byte data);
        rxd = 0; #(BIT_TIME);
        for (int i=0; i<8; i++) begin rxd = data[i]; #(BIT_TIME); end
        rxd = 1; #(BIT_TIME); #(BIT_TIME/2);
    endtask

    // Decode serial output independently of DUT state, including start/stop.
    initial forever begin
        byte actual, expected;
        @(negedge txd);
        if (nrst) begin
            #(BIT_TIME/2);
            if (txd !== 0) $fatal(1, "TX start bit");
            for (int i=0; i<8; i++) begin #(BIT_TIME); actual[i] = txd; end
            #(BIT_TIME);
            if (txd !== 1) $fatal(1, "TX stop bit actual=%h",actual);
            if (tx_expected.size() == 0) $fatal(1, "Unexpected TX byte");
            expected = tx_expected.pop_front();
            if (actual !== expected) $fatal(1, "TX expected=%h actual=%h", expected, actual);
            tx_seen++;
        end
    end

    always @(dut.uart.uart.tx.u_tx_controller.cstate or txd)
        if (nrst && tx_seen < 2) $display("TRACE t=%0t state=%h cnt=%0d bit=%0d txd=%b wr=%b",$time,
            dut.uart.uart.tx.u_tx_controller.cstate,dut.uart.uart.tx.u_tx_controller.cnt,
            dut.uart.uart.tx.u_tx_controller.tx_cnt,txd,dut.bridge.uart_tx_wr_en);

    // Random S2MM backpressure after initially accumulating RX bytes.
    bit enable_sink = 0;
    always @(negedge clk) if (enable_sink) mready = ($urandom_range(0,3) != 0);
    logic stalled = 0;
    logic [37:0] stalled_word;
    always @(posedge clk) begin
        if (nrst) begin
            if (stalled && {mvalid,mlast,mkeep,mdata} !== stalled_word)
                $fatal(1, "AXIS output changed under backpressure");
            stalled = mvalid && !mready;
            stalled_word = {mvalid,mlast,mkeep,mdata};
            if (mvalid && mready) begin
                byte expected;
                if (rx_expected.size() == 0) $fatal(1, "Unexpected RX word %h", mdata);
                expected = rx_expected.pop_front();
                if (mdata !== {24'b0,expected} || mkeep !== 15 || mlast !== ((rx_seen%3)==2))
                    $fatal(1, "RX word/keep/last mismatch at %0d: %h %h %b",rx_seen,mdata,mkeep,mlast);
                rx_seen++;
            end
        end else stalled = 0;
    end

    initial begin
        repeat(10) @(negedge clk); nrst = 1;
        configure_baud();
        // Idle must not generate a phantom RX frame.
        #(12*BIT_TIME);
        if (mvalid || rx_count != 0) $fatal(1, "RX frame appeared during idle after reset");
        for(int i=0;i<18;i++) begin
            tx_expected.push_back(byte'(i*13+7));
            rx_expected.push_back(byte'(i*17+3));
        end
        fork
            begin
                for(int i=0;i<18;i++) send_dma({24'habcd89,byte'(i*13+7)},15,(i%3)==2);
                // A word with an invalid low byte must not create a UART byte.
                send_dma(32'hffffffff,14,1);
            end
            begin
                for(int i=0;i<5;i++) send_uart(byte'(i*17+3));
                enable_sink = 1;
                for(int i=5;i<18;i++) send_uart(byte'(i*17+3));
            end
        join
        wait(tx_seen==18 && rx_seen==18);
        #(12*BIT_TIME);
        if (overflow || tx_count != 0 || rx_count != 0 || mvalid || tx_expected.size() || rx_expected.size())
            $fatal(1, "Final queues/overflow check");
        $display("UART2PS_INTEGRATION_PASS tx=%0d rx=%0d",tx_seen,rx_seen);
        $finish;
    end
    initial begin #20ms; $fatal(1,"Integration timeout tx=%0d rx=%0d",tx_seen,rx_seen); end
endmodule
