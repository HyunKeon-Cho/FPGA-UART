module clock_generator #(
    parameter int unsigned BAUD_DIV_INT_WIDTH  = 16,
    parameter int unsigned BAUD_DIV_FRAC_WIDTH = 16
) (
    input  logic                           clk,
    input  logic                           nrst,

    input  logic [BAUD_DIV_INT_WIDTH-1:0]  div_int,
    input  logic [BAUD_DIV_FRAC_WIDTH-1:0] div_frac,
    output logic                           oclk
);

logic [BAUD_DIV_FRAC_WIDTH-1:0]  frac_acc;
logic [BAUD_DIV_INT_WIDTH-1:0] int_acc;
logic int_acc_buf;
logic int_acc_negedge;

logic [BAUD_DIV_FRAC_WIDTH:0] frac_adder;
logic frac_carry;

assign frac_adder = {1'b0, frac_acc} + {1'b0, div_frac};
assign frac_carry = frac_adder[BAUD_DIV_FRAC_WIDTH]; 
assign int_acc_negedge = int_acc_buf & (int_acc == 0);

always @(negedge clk or negedge nrst) begin
    if (!nrst) begin
        int_acc_buf <= 1'b0;
    end else begin
        int_acc_buf <= (int_acc != 0);
    end
end

always @(negedge clk or negedge nrst) begin
    if (!nrst) begin
        frac_acc <= 0;
    end else begin
        frac_acc <= frac_adder[BAUD_DIV_FRAC_WIDTH-1:0];
    end
end


always @(negedge clk or negedge nrst) begin
    if (!nrst) begin
        int_acc <= 0;
    end else begin
        if (int_acc == 0) begin
            if (frac_carry) begin
                int_acc <= 0;
            end else begin
                int_acc <= div_int;
            end
        end else begin
            int_acc <= int_acc - (!frac_carry);
        end
    end
end

always @(negedge clk or negedge nrst) begin
    if (!nrst) begin
        oclk <= 1'b1;
    end else begin
        if (int_acc_negedge) begin
            oclk <= ~oclk;
        end else begin
            oclk <= oclk;
        end
    end
end

endmodule
