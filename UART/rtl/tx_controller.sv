module tx_controller #(
    parameter int unsigned OVERSAMPLING_RATE = 16,
    parameter int unsigned BITWIDTH = 8
) (
    input  logic clk,
    input  logic nrst,
    input  logic wr_en,

    output logic state_bit,
    output logic send,
    output logic shift,
    output logic enable,
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
logic [COUNTER_BITWIDTH+TX_COUNTER_BITWIDTH:0] cnt;
logic cnt_reset_triger;

// ********************************
// assign logic
// ********************************
assign enable = ~cstate[0];
assign shift = ~(cnt == OVERSAMPLING_RATE-1);
assign send = cstate[2];
assign ready = cstate[0] | cstate[3];
assign state_bit = (cstate[0]) ? 1'b1 : cstate[3];       

// ********************************
// counter
// ********************************
assign cnt_reset_triger = nrst & cstate[2];

always_ff @(negedge clk or negedge cnt_reset_triger) begin
    if (!cnt_reset_triger) begin
        cnt <= 0;
    end else begin
        cnt <= cnt + 1;
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
    nstate = cstate;
    case(cstate) 
        IDLE : begin
            if (wr_en) begin
                nstate = IN;
            end
        end
        IN : begin
            if (shift) begin
                nstate = PROC;
            end else begin
                nstate = nstate;
            end
        end
        PROC : begin
            if (cnt == (OVERSAMPLING_RATE << TX_COUNTER_BITWIDTH) - 1) begin
                nstate = OUT;
            end
        end
        OUT : begin
            if (shift) begin
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