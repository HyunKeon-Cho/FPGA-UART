module rx_controller #(
    parameter int unsigned OVERSAMPLING_RATE = 16,
    parameter int unsigned BITWIDTH = 8
)(
    input  logic clk,
    input  logic rx_clk,
    input  logic nrst,

    input  logic start,
    output logic clock_enable,
    output logic rx_valid
);

localparam  int unsigned COUNTER_BITWIDTH = $clog2(BITWIDTH)+1;

typedef enum logic [3:0] {
    IDLE = 4'b0001,
    IN   = 4'b0010,
    PROC = 4'b0100,
    OUT  = 4'b1000
} state_t;

state_t cstate, nstate;

logic [COUNTER_BITWIDTH-1:0] cnt;
logic cnt_reset_triger;

assign cnt_reset_triger = !nrst | cstate[0] | cstate[1];

always_ff @(negedge rx_clk or posedge cnt_reset_triger) begin
    if (cnt_reset_triger) begin
        cnt <= 0;
    end else begin
        cnt <= cnt + 1;
    end
end

always_ff @(negedge clk or negedge nrst) begin
    if (!nrst) begin
        cstate <= IDLE;
    end else begin
        cstate <= nstate;
    end
end

always_ff @(negedge clk or negedge nrst) begin
    if (!nrst) begin     
        clock_enable <= 0;
        rx_valid <= 0;
    end else if (cstate == IN) begin
        clock_enable <= 0;
        rx_valid <= 0;
    end else if (cstate == PROC) begin
        clock_enable <= 1;
        rx_valid <= 0;
    end else if (cstate == OUT) begin
        clock_enable <= 0;
        // OUT lasts one system clock cycle: report one completed receive.
        rx_valid <= 1;
    end else begin
        clock_enable <= 0;
        rx_valid <= 0;
    end
end

always_comb begin
    nstate = cstate;
    case(cstate) 
        IDLE : begin
            if (start == 1) begin
                nstate = IN;
            end
        end
        IN : begin
            nstate = PROC;
        end
        PROC : begin
            if (cnt == BITWIDTH+1) begin
                nstate = OUT;
            end
        end
        OUT : begin
            if (start == 1) begin
                nstate = IN;
            end else begin
                nstate = IDLE;
            end
        end
        default : begin
            nstate = IDLE;
        end
    endcase
end

endmodule
