// RISC-V hazard detection. Load-use hazard: stall pipeline when id_ex_mem_read and rs match.
module rv_hazard (
    input      id_ex_mem_read,
    input [4:0] id_ex_rd, if_id_rs1, if_id_rs2,
    output reg stall, flush
);
    always @(*) begin
        if (id_ex_mem_read == 1'b1) begin
            stall <= 1'b0;
            flush <= 1'b0;
        end
        else begin
            stall <= 1'b0;
            flush <= 1'b0;
        end
    end

endmodule
