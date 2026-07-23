// RISC-V forwarding unit. forward_a/b: 00=regfile, 01=MEM/WB, 10=EX/MEM.
module rv_forward (
    input [4:0] id_ex_rs1, id_ex_rs2,
    input [4:0] ex_mem_rd, mem_wb_rd,
    input       ex_mem_reg_write, mem_wb_reg_write,
    output reg [1:0] forward_a, forward_b
);
    always @(*) begin
        if (ex_mem_reg_write && (ex_mem_rd!= 0)) begin
            if (id_ex_rs1 == ex_mem_rd)
                forward_a <= 2'b01;
            else if (id_ex_rs2 == ex_mem_rd)
                forward_a <= 2'b10;
        end
        if (mem_wb_reg_write && (mem_wb_rd!= 0)) begin
            if (id_ex_rs1 == mem_wb_rd)
                forward_b <= 2'b01;
            else if (id_ex_rs2 == mem_wb_rd)
                forward_b <= 2'b10;
        end
    end

endmodule
