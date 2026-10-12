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

    // controller
    logic start_end_data;
    logic send;
    logic shift;
    logic enable;
    logic [BITWIDTH:0] fifo;

    // ********************************
    // cotroller
    // ********************************
    tx_controller #(
        .OVERSAMPLING_RATE(OVERSAMPLING_RATE),
        .BITWIDTH(BITWIDTH)
    ) u_tx_controller (
        .clk(clk),
        .nrst(nrst),
        .wr_en(wr_en),
        .start_end_data(start_end_data),
        .send(send),
        .shift(shift),
        .enable(enable),
        .ready(ready)
    );

    // ********************************
    // BUF
    // ********************************
    always @(negedge enable or negedge nrst) begin
        if (!nrst) begin
            buf <= 0;
        end else begin
            if (enable) begin
                if (shift) begin
                    buf <= {1'b0, buf[BITWIDTH-1:0]};
                end else begin
                    buf <= buf;
                end
            end else if (wr_en) begin
                buf <= indata;
            end else begin
                buf <= buf;
            end
        end
    end


endmodule