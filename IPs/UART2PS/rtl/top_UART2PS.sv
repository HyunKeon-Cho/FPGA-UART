module top_UART2PS #(
    parameter int unsigned FIFO_DEPTH = 256,
    parameter int unsigned BITWIDTH = 8
) (
    input  logic clk,
    input  logic nrst,

    input  logic [BITWIDTH-1:0] rx_data,
    output logic rx_wr_rdy,
    //input  logic rx_wr_vld,
    input  logic rx_rd_rdy,
    output logic rx_rd_vld,

    output logic [BITWIDTH-1:0] tx_data
    output logic tx_wr_rdy,
    input  logic tx_wr_vld,
    input  logic tx_rd_rdy,
    output logic tx_rd_vld,
    
);

    // ********************************
    // RX
    // ********************************
    logic rx_FIFO_full;
        output logic rx_wr_rdy,
    input  logic rx_wr_vld,
    input  logic rx_rd_rdy,
    output logic rx_rd_vld,
z

    FIFO #(
        .aclk(clk),
        .rst(!nrst),
        .clr(!nrst)
    )


endmodule