// RISC-V IF stage. PC register with stall and branch mux. Outputs PC+4 and next PC.
module rv_if_stage (
    input        clk, rst, stall, pc_src,
    input [31:0] branch_target,
    output reg [31:0] pc,
    output [31:0] pc_plus4
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 0;
            pc_plus4 <= 0;
        end else begin
            if (stall) begin
                pc <= branch_target;
                pc_plus4 <= branch_target + 4;
            end else begin
                pc <= pc_plus4;
                pc_plus4 <= pc_plus4 + 4;
            end
        end
    end

endmodule
