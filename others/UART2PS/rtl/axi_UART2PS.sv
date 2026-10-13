// Integrated UART + two independent DMA stream interfaces.
// DMA TX M_AXIS_MM2S -> s_axis; m_axis -> DMA RX S_AXIS_S2MM.
// Both DMA stream clocks and UART AXI-Lite clock must share s_axi_aclk.
module axi_UART2PS #(
    parameter int unsigned BAUD_DIV_INT_WIDTH = 16,
    parameter int unsigned BAUD_DIV_FRAC_WIDTH = 16,
    parameter int unsigned OVERSAMPLING_RATE = 16,
    parameter int unsigned TX_FIFO_DEPTH = 256,
    parameter int unsigned RX_FIFO_DEPTH = 256,
    parameter int unsigned RX_PACKET_WORDS = 1
) (
    input  logic uart_rxd,
    output logic uart_txd,
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axi_aclk CLK",
       X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axi:s_axis:m_axis, ASSOCIATED_RESET s_axi_aresetn" *)
    input  logic s_axi_aclk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axi_aresetn RST",
       X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
    input  logic s_axi_aresetn,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis TDATA" *)
    input  logic [31:0] s_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis TKEEP" *)
    input  logic [3:0] s_axis_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis TLAST" *)
    input  logic s_axis_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis TVALID" *)
    input  logic s_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis TREADY" *)
    output logic s_axis_tready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TDATA" *)
    output logic [31:0] m_axis_tdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TKEEP" *)
    output logic [3:0] m_axis_tkeep,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TLAST" *)
    output logic m_axis_tlast,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TVALID" *)
    output logic m_axis_tvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis TREADY" *)
    input  logic m_axis_tready,
    input  logic [31:0] s_axi_awaddr,
    input  logic [2:0] s_axi_awprot,
    input  logic s_axi_awvalid,
    output logic s_axi_awready,
    input  logic [31:0] s_axi_wdata,
    input  logic [3:0] s_axi_wstrb,
    input  logic s_axi_wvalid,
    output logic s_axi_wready,
    output logic [1:0] s_axi_bresp,
    output logic s_axi_bvalid,
    input  logic s_axi_bready,
    input  logic [31:0] s_axi_araddr,
    input  logic [2:0] s_axi_arprot,
    input  logic s_axi_arvalid,
    output logic s_axi_arready,
    output logic [31:0] s_axi_rdata,
    output logic [1:0] s_axi_rresp,
    output logic s_axi_rvalid,
    input  logic s_axi_rready,
    output logic rx_overflow,
    output logic [$clog2(TX_FIFO_DEPTH+1)-1:0] tx_fifo_count,
    output logic [$clog2(RX_FIFO_DEPTH+1)-1:0] rx_fifo_count
);
    logic rx_valid, tx_ready, tx_wr_en;
    logic [7:0] rx_data, tx_data;

    axi_UART #(
        .BAUD_DIV_INT_WIDTH(BAUD_DIV_INT_WIDTH),
        .BAUD_DIV_FRAC_WIDTH(BAUD_DIV_FRAC_WIDTH),
        .OVERSAMPLING_RATE(OVERSAMPLING_RATE)
    ) uart (
        .uart_rxd(uart_rxd), .uart_txd(uart_txd),
        .rx_valid(rx_valid), .rx_data(rx_data),
        .tx_ready(tx_ready), .tx_wr_en(tx_wr_en), .tx_data(tx_data),
        .s_axi_aclk(s_axi_aclk), .s_axi_aresetn(s_axi_aresetn),
        .s_axi_awaddr(s_axi_awaddr), .s_axi_awprot(s_axi_awprot),
        .s_axi_awvalid(s_axi_awvalid), .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata), .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid), .s_axi_wready(s_axi_wready),
        .s_axi_bresp(s_axi_bresp), .s_axi_bvalid(s_axi_bvalid), .s_axi_bready(s_axi_bready),
        .s_axi_araddr(s_axi_araddr), .s_axi_arprot(s_axi_arprot),
        .s_axi_arvalid(s_axi_arvalid), .s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata), .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid), .s_axi_rready(s_axi_rready)
    );

    top_UART2PS #(
        .TX_FIFO_DEPTH(TX_FIFO_DEPTH), .RX_FIFO_DEPTH(RX_FIFO_DEPTH),
        .RX_PACKET_WORDS(RX_PACKET_WORDS)
    ) bridge (
        .clk(s_axi_aclk), .nrst(s_axi_aresetn),
        .s_axis_tdata(s_axis_tdata), .s_axis_tkeep(s_axis_tkeep),
        .s_axis_tlast(s_axis_tlast), .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .m_axis_tdata(m_axis_tdata), .m_axis_tkeep(m_axis_tkeep),
        .m_axis_tlast(m_axis_tlast), .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .uart_rx_valid(rx_valid), .uart_rx_data(rx_data),
        .uart_tx_ready(tx_ready), .uart_tx_wr_en(tx_wr_en), .uart_tx_data(tx_data),
        .rx_overflow(rx_overflow), .tx_fifo_count(tx_fifo_count), .rx_fifo_count(rx_fifo_count)
    );

    initial begin
        if (BAUD_DIV_INT_WIDTH + BAUD_DIV_FRAC_WIDTH != 32)
            $fatal(1, "Existing axi_UART configuration register requires a 32-bit divider");
    end
endmodule
