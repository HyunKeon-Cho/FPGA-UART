`timescale 1ns/1ps

module tb_UART_rx;
    import uvm_pkg::*;
    import tb_UART_rx_pkg::*;

    // ********************************
    // hyperparameters
    // ********************************
    // clock
    localparam int CLK_PERIOD = 20;

    // DUT
    localparam int BAUD_DIV_INT_WIDTH = 16;
    localparam int BAUD_DIV_FRAC_WIDTH = 16;
    localparam int OVERSAMPLING_RATE = 16;
    localparam int BITWIDTH = 8;
    
    // UART
    localparam int UART_BAUD_RATE = 9600;
    localparam int INTERNAL_CLK_RATE = 50_000_000;
    localparam int BAUD_DIV_INT = INTERNAL_CLK_RATE / UART_BAUD_RATE;
    localparam int BAUD_DIV_FRAC = int'(real'(INTERNAL_CLK_RATE % UART_BAUD_RATE) / real'(INTERNAL_CLK_RATE) * (2.0 ** BAUD_DIV_FRAC_WIDTH)) * 2;
    localparam int TEST_N = 8;
    localparam time BIT_PERIOD = BAUD_DIV_INT * CLK_PERIOD * 1ns;
    localparam time TEST_TIMEOUT = (13 * TEST_N + 16) * BIT_PERIOD;

    // ********************************
    // clock
    // ********************************
    bit clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;
    
    // ********************************
    // UVM
    // ********************************
    UART_rx_if uart_if(clk);
    
    // ********************************
    // DUT
    // ********************************
    UART_rx
`ifndef UART_SYNTH_NETLIST
    #(
        .BAUD_DIV_INT_WIDTH(BAUD_DIV_INT_WIDTH), 
        .BAUD_DIV_FRAC_WIDTH(BAUD_DIV_FRAC_WIDTH),
        .OVERSAMPLING_RATE(OVERSAMPLING_RATE), 
        .BITWIDTH(BITWIDTH)
    )
`endif
    dut (
        .clk(clk), 
        .nrst(uart_if.nrst), 
        .indata(uart_if.indata),
        .outdata(uart_if.outdata), 
        .valid(uart_if.valid),
        .baud_div_int(uart_if.baud_div_int), 
        .baud_div_frac(uart_if.baud_div_frac)
    );

    // ********************************
    // main
    // ********************************
    initial begin
        uvm_report_server server;
        uvm_root root;

        // UVM setup
        uart_if.bit_cycles = BAUD_DIV_INT;
        uart_if.baud_div_int = BAUD_DIV_INT;
        uart_if.baud_div_frac = BAUD_DIV_FRAC;

        uvm_config_db#(virtual UART_rx_if)::set(null, "uvm_test_top*", "vif", uart_if);
        uvm_config_db#(time)::set(null, "uvm_test_top", "bit_period", BIT_PERIOD);
        uvm_config_db#(int)::set(null, "uvm_test_top", "test_N", TEST_N);

        root = uvm_root::get();
        root.finish_on_completion = 0;
        
        // run
        run_test("test");

        // scoreboard check
        server = uvm_report_server::get_server();
        if (server.get_severity_count(UVM_ERROR) != 0 || server.get_severity_count(UVM_FATAL) != 0) begin
            $display("RESULT: FAIL");
            $fatal(1, "UART UVM test failed; inspect the UVM report");
        end
            
        $display("RESULT: PASS");
        $display("UART_UVM_PASS");
        $finish;
    end

    // UVM reset
    initial begin
        repeat (8) @(posedge clk);
        uart_if.nrst <= 1;
    end
    
    // UVM timeout
    initial begin
        wait (uart_if.nrst === 1'b1);

        #(TEST_TIMEOUT);
        $display("RESULT: FAIL");
        $fatal(1, "UART UVM simulation timeout");
    end
endmodule
