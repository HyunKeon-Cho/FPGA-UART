module uart_core #(
    parameter int unsigned BAUD_DIV_INT_WIDTH  = 16,
    parameter int unsigned BAUD_DIV_FRAC_WIDTH = 16
    parameter int unsigned OVERSAMPLING_RATE   = 16;
) (
    input  logic                           clk,
    input  logic                           nrst,
    // UART Interfacce                     
    input  logic                           rxd,
    output logic                           txd,
    // RX                      
    output logic                           rx_valid,
    output logic [7:0]                     rx_data,
    // TX                      
    output logic                           tx_ready,
    input  logic                           tx_wr_en,
    input  logic [7:0]                     tx_data,
    // baud_div_parameter
    input  logic [BAUD_DIV_INT_WIDTH-1:0]  baud_div_int,
    input  logic [BAUD_DIV_FRAC_WIDTH-1:0] baud_div_frac
);

RX_UART #(
    .BAUD_DIV_INT_WIDTH  (BAUD_DIV_INT_WIDTH),
    .BAUD_DIV_FRAC_WIDTH (BAUD_DIV_FRAC_WIDTH),
    .OVERSAMPLING_RATE   (OVERSAMPLING_RATE)
) rx (
    .clk            (clk),
    .nrst           (nrst),
    .indata         (rxd),
    .outdata        (rx_data)
    .valid          (rx_valid),
    .baud_div_int   (baud_div_int),
    .baud_div_frac  (baud_div_frac)
);

endmodule
