module UART_rx #(
    parameter int unsigned BAUD_DIV_INT_WIDTH  = 16,
    parameter int unsigned BAUD_DIV_FRAC_WIDTH = 16,
    parameter int unsigned OVERSAMPLING_RATE = 16,
    parameter int unsigned BITWIDTH = 8
) (
    input  logic                           clk,
    input  logic                           nrst,

    input  logic                           indata,
    output logic [7:0]                     outdata,
    output logic                           valid,

    input  logic [BAUD_DIV_INT_WIDTH-1:0]  baud_div_int,
    input  logic [BAUD_DIV_FRAC_WIDTH-1:0] baud_div_frac
);

// wires for clock generator & controller
logic rx_clk;
logic clocK_enable;

// ********************************
// 1 to 0 Transition detector
// ********************************
logic td_reg;
logic is_start;

assign is_start = td_reg & (!indata);

always_ff @(negedge clk or negedge nrst) begin
    if (!nrst) begin
        td_reg <= 1'b0;
    end else begin        
        td_reg <= indata;
    end
end

// ********************************
// bit detector
// ********************************
localparam bd_bitwidth = OVERSAMPLING_RATE/2;
logic [bd_bitwidth-1:0] bd_fifo;
logic bd_detected_data;

assign bd_detected_data =   (bd_fifo[bd_bitwidth-1] & bd_fifo[bd_bitwidth-2])
                          | (bd_fifo[bd_bitwidth-2] & bd_fifo[bd_bitwidth-3])
                          | (bd_fifo[bd_bitwidth-3] & bd_fifo[bd_bitwidth-1]);

always_ff @(negedge clk or negedge nrst) begin
    if (!nrst) begin
        bd_fifo <= 0;
    end else begin
        bd_fifo <= {bd_fifo[bd_bitwidth-2:0], indata};
    end
end

// ********************************
// FIFO
// ********************************
logic [BITWIDTH-1:0] fifo;

always_ff @(negedge rx_clk or negedge nrst) begin
    if (!nrst) begin
        fifo <= 0;
    end else begin
        fifo <= {bd_detected_data, fifo[BITWIDTH-1:1]};
    end
end

// ********************************
// BUF
// ********************************
logic [BITWIDTH-1:0] rx_buf;

assign outdata = rx_buf;

always_ff @(negedge clk or negedge nrst) begin
    if (!nrst) begin
        rx_buf <= 0;
    end else begin
        rx_buf <= fifo;
    end
end

// ********************************
// Clcok generator
// ********************************
rx_clock_generator #(
    .BAUD_DIV_INT_WIDTH  (BAUD_DIV_INT_WIDTH),
    .BAUD_DIV_FRAC_WIDTH (BAUD_DIV_FRAC_WIDTH)
) clock_gen (
    .clk        (clk),
    .nrst       (clocK_enable),
    .div_int    (baud_div_int),
    .div_frac   (baud_div_frac),
    .oclk       (rx_clk)
);

// ********************************
// Controller
// ********************************
rx_controller #(
    .OVERSAMPLING_RATE(OVERSAMPLING_RATE),
    .BITWIDTH(BITWIDTH)
) controller (
    .clk          (clk),
    .nrst         (nrst),
    .rx_clk       (rx_clk),
    .start        (is_start),
    .clock_enable (clocK_enable),
    .rx_valid     (valid)
);

endmodule
