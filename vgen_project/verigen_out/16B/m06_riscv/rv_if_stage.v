// RISC-V IF stage. PC register with stall and branch mux. Outputs PC+4 and next PC.
module rv_if_stage (
    input        clk, rst, stall, pc_src,
    input [31:0] branch_target,
    output reg [31:0] pc,
    output [31:0] pc_plus4
);
    always @(posedge clk) begin
        if (rst) begin
            pc <= 0;
        end else begin
            if (stall) begin
                pc <= pc;
            end else begin
                if (pc_src) begin
                    pc <= branch_target;
                end else begin
                    pc <= pc + 4;
                end
            end
        end
    end
    assign pc_plus4 = pc + 4;

endmodule
