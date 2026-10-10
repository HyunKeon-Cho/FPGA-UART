module axi_UART #(
    parameter int unsigned BAUD_DIV_INT_WIDTH  = 16,
    parameter int unsigned BAUD_DIV_FRAC_WIDTH = 16,
    parameter int unsigned OVERSAMPLING_RATE = 16
) (
    // ********************************
    // UART Interface
    // ********************************
    input  logic        uart_rxd,
    output logic        uart_txd,

    // ********************************
    // Internal Interface
    // ********************************
    // RX
    output logic        rx_valid,
    output logic [7:0]  rx_data,

    // TX
    output logic        tx_ready,
    input  logic        tx_wr_en,
    input  logic [7:0]  tx_data,

    // ********************************
    // AXI4-Lite Slave Interface
    // ********************************
    // Clock and active-low reset shared by AXI and the UART core
    input  logic        s_axi_aclk,
    input  logic        s_axi_aresetn,
    // AXI4-Lite slave: write address
    input  logic [31:0] s_axi_awaddr,
    input  logic [2:0]  s_axi_awprot,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,

    // Write data
    input  logic [31:0] s_axi_wdata,
    input  logic [3:0]  s_axi_wstrb,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,

    // Write response
    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,

    // Read address
    input  logic [31:0] s_axi_araddr,
    input  logic [2:0]  s_axi_arprot,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,

    // Read data and response
    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready
);

wire [31:0] cfg_data;
wire [BAUD_DIV_INT_WIDTH-1:0] baud_div_int;
wire [BAUD_DIV_FRAC_WIDTH-1:0] baud_div_frac;

// Configuration register block
axi_lite_reg u_regs (
    .s_axi_aclk    (s_axi_aclk),
    .s_axi_aresetn (s_axi_aresetn),
    .s_axi_awaddr  (s_axi_awaddr),
    .s_axi_awprot  (s_axi_awprot),
    .s_axi_awvalid (s_axi_awvalid),
    .s_axi_awready (s_axi_awready),
    .s_axi_wdata   (s_axi_wdata),
    .s_axi_wstrb   (s_axi_wstrb),
    .s_axi_wvalid  (s_axi_wvalid),
    .s_axi_wready  (s_axi_wready),
    .s_axi_bresp   (s_axi_bresp),
    .s_axi_bvalid  (s_axi_bvalid),
    .s_axi_bready  (s_axi_bready),
    .s_axi_araddr  (s_axi_araddr),
    .s_axi_arprot  (s_axi_arprot),
    .s_axi_arvalid (s_axi_arvalid),
    .s_axi_arready (s_axi_arready),
    .s_axi_rdata   (s_axi_rdata),
    .s_axi_rresp   (s_axi_rresp),
    .s_axi_rvalid  (s_axi_rvalid),
    .s_axi_rready  (s_axi_rready),
    .cfg_data      ({baud_div_int, baud_div_frac})
);

top_UART #(
    .BAUD_DIV_INT_WIDTH  (BAUD_DIV_INT_WIDTH),
    .BAUD_DIV_FRAC_WIDTH (BAUD_DIV_FRAC_WIDTH),
    .OVERSAMPLING_RATE   (OVERSAMPLING_RATE)
) uart (
    .clk           (s_axi_aclk),
    .nrst          (s_axi_aresetn),
    .uart_rxd      (uart_rxd),
    .uart_txd      (uart_txd),
    .rx_valid      (rx_valid),
    .rx_data       (rx_data),
    .rx_ready      (rx_ready),
    .tx_wr_en      (tx_wr_en),
    .tx_data       (tx_data)
    .baud_div_int  (baud_div_int),
    .baud_div_frac (baud_div_frac),
);

endmodule
