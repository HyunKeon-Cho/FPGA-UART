module rx_clock_generator #(
    parameter int unsigned BAUD_DIV_INT_WIDTH  = 16,
    parameter int unsigned BAUD_DIV_FRAC_WIDTH = 16
) (
    input  logic                           clk,
    input  logic                           nrst,

    input  logic [BAUD_DIV_INT_WIDTH-1:0]  div_int,
    input  logic [BAUD_DIV_FRAC_WIDTH-1:0] div_frac,
    output logic                           oclk
);

logic [BAUD_DIV_FRAC_WIDTH:0]  frac_acc;
logic [BAUD_DIV_INT_WIDTH-1:0] int_acc;
logic tic;
logic [BAUD_DIV_INT_WIDTH-1:0] iteration_target;
logic [BAUD_DIV_INT_WIDTH-1:0] iteration_target_1;

assign iteration_target = div_int-1;
assign iteration_target_1 = div_int;
assign tic = frac_acc[BAUD_DIV_FRAC_WIDTH];

always @(negedge clk or negedge nrst) begin
    if (!nrst) begin
        frac_acc <= 0;
    end else begin
        if (oclk == 0) begin
            frac_acc <= {1'b0, frac_acc[BAUD_DIV_FRAC_WIDTH-1:0]} + div_frac;
        end else begin
            frac_acc <= frac_acc + div_frac;
        end
    end
end

always @(negedge clk or negedge nrst) begin
    if (!nrst) begin
        int_acc <= 0;
    end else begin
        if (tic == 0 && int_acc == iteration_target) begin
            int_acc <= 0;
        end else if (tic == 1 && int_acc == iteration_target_1) begin
            int_acc <= 0;
        end else begin
            int_acc <= int_acc + 1;
        end
    end
end

always @(negedge clk or negedge nrst) begin
    if (!nrst) begin
        oclk <= 1'b1;
    end else begin
        if (oclk == 0) begin
            oclk <= 1'b1;
        end else if (int_acc == (div_int >> 1)) begin
            oclk <= 1'b0;
        end else begin
            oclk <= oclk;
        end
    end
end

endmodule
