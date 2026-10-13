module top_UART2PS #(
    parameter int unsigned FIFO_DEPTH = 256,
    parameter int unsigned FIFO_DEPTH = 256,
    parameter int unsigned BITWIDTH = 1
) (
    input  logic clk,
    input  logic nrst,

    input  logic [BITWIDTH-1:0] uart_rx,
    

    output logic [BITWIDTH-1:0] uart_tx,
);