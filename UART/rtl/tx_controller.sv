module tx_controller #(
    parameter int unsigned OVERSAMPLING_RATE = 16,
    parameter int unsigned BITWIDTH = 8
) (
    input  logic clk,
    input  logic nrst,
    input  logic wr_en,

    output logic state_bit,
    output logic send,
    output logic tx_clk,
    output logic ready
);

localparam  int unsigned COUNTER_BITWIDTH = $clog2(OVERSAMPLING_RATE);
localparam  int unsigned TX_COUNTER_BITWIDTH = $clog2(BITWIDTH);

// ********************************
// logic define
// ********************************
// FSM
typedef enum logic [3:0] {
    IDLE = 4'b0001,
    IN   = 4'b0010,
    PROC = 4'b0100,
    OUT  = 4'b1000
} state_t;

state_t cstate, nstate;

// counter
logic [COUNTER_BITWIDTH-1:0] cnt;
logic [TX_COUNTER_BITWIDTH-1:0] tx_cnt;
logic tx_cnt_reset_triger;
logic cnt_nrst;

// ********************************
// assign logic
// ********************************
assign tx_clk = cnt == 0;
assign send = cstate[2];
assign ready = cstate[0] | cstate[3];
assign state_bit = (cstate[0]) ? 1'b1 : cstate[3];       

// ********************************
// counter
// ********************************

assign cnt_nrst = nrst & (~cstate[0] & ~nstate[1]);

always_ff @(negedge clk or negedge cnt_nrst) begin
    if (!cnt_nrst) begin
        cnt <= 0;
    end else begin
        cnt <= cnt - 1;
    end
end

assign tx_cnt_reset_triger = nrst & cstate[2];

always_ff @(negedge tx_clk or negedge tx_cnt_reset_triger) begin
    if (!tx_cnt_reset_triger) begin
        tx_cnt <= 0;
    end else begin
        tx_cnt <= tx_cnt + 1;
    end
end


// ********************************
// FSM
// ********************************
always_ff @(negedge clk or negedge nrst) begin
    if (!nrst) begin
        cstate <= IDLE;
    end else begin
        cstate <= nstate;
    end
end

always_comb begin
    case(cstate) 
        IDLE : begin
            if (wr_en) begin
                nstate = IN;
            end else begin
                nstate <= IDLE;
            end
        end
        IN : begin
            if (tx_clk) begin
                nstate = PROC;
            end else begin
                nstate = nstate;
            end
        end
        PROC : begin
            if (tx_clk) begin 
                if (tx_cnt == BITWIDTH-1) begin
                    nstate = OUT;
                end else begin
                    nstate = nstate;
                end
            end else begin
                nstate = nstate;
            end
        end
        OUT : begin
            if (tx_clk) begin
                if (wr_en) begin
                    nstate = PROC;
                end else begin
                    nstate = IDLE;
                end
            end else begin
                nstate = nstate;
            end
        end
        default : begin
            nstate = IDLE;
        end
    endcase
end






endmodule