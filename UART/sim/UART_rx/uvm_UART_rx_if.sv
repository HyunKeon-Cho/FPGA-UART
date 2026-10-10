`timescale 1ns/1ps

interface UART_rx_if(input logic clk);
    // parameters
    int unsigned bit_cycles   = 64;
    logic [15:0] baud_div_int  = 16'd4;
    logic [15:0] baud_div_frac = 0;
    // input
    logic nrst = 0;
    logic indata = 1;
    // output
    logic [7:0] outdata;
    logic valid;

    // 클록 기준으로 입력을 구동하고 출력을 관찰한다.
    clocking cb @(posedge clk);
        // input #1step: 에지 직전 값을 관찰한다. output #0: 해당 에지에 출력을 구동한다.
        default input #1step output #0;

        input nrst, outdata, valid;
        output indata;
    endclocking
endinterface
