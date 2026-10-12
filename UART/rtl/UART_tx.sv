module UART_tx #(
    parameter int unsigned OVERSAMPLING_RATE = 16,
    parameter int unsigned BITWIDTH = 8
) (
    input logic clk,
    input logic nrst,
    input logic [BITWIDTH-1:0] indata,
    input logic wr_en,
    output logic ready,
    output logic outdata
);
    // ********************************
    // define logic
    // ********************************
    // BUF
    logic [BITWIDTH-1:0] buf;

    logic shift;
    logic [BITWIDTH-1:0] sreg;
    
    // ********************************
    // BUF
    // ********************************
    always @(negedge clk or negedge nrst) begin
        if (!nrst) begin
            buf <= 0;
        end else begin
            if (shift) begin
                buf <= {1'b0, buf[BITWIDTH-1:0]};

    end
endmodule