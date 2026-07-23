// Direct-mapped write-through cache: 16 sets, 4-byte lines. 32-bit address.
// tag[31:6]=24b, index[5:2]=4b, offset[1:0]=2b. Valid array reset on rst.
module cache (
    input         clk, rst, cpu_req, cpu_we,
    input  [31:0] cpu_addr, cpu_wdata,
    output [31:0] cpu_rdata,
    output        stall,
    output [31:0] mem_addr,
    input  [31:0] mem_rdata,
    output        mem_req
);
    parameter WIDTH=32;
    parameter DEPTH=256;
    parameter ASSOC=4;
    parameter TAG_SZ=8;
    parameter INDEX_SZ=8;
    parameter OFFSET=2;
    parameter LINE_SZ=WIDTH+ASSOC+OFFSET;
    parameter W_R_I=1'b0, R_W_I=1'b1;
    parameter S_I=2'b00, S_R=2'b01, S_W=2'b10, S_C=2'b11;
    parameter I_D=3'b000, I_C=3'b001, I_R=3'b010, I_W=3'b011, I_S=3'b100;
    parameter D_D=3'b000, D_C=3'b001, D_R=3'b010, D_W=3'b011, D_S=3'b100;
    parameter D_I=3'b000, D_C=3'b001, D_R=3'b010, D_W=3'b011, D_S=3'b100;
    parameter D_I_S=3'b000, D_C_S=3'b001, D_R_S=3'b010, D_W_S=3'b011, D_S_S=3'b100;
    parameter D_I_C=3'b000, D_C_C=3'b001, D_R_C=3'b010, D_W_C=3'b011, D_S_C=3'b100;
    parameter D_I_R=3'b000, D_C_R=3'b001, D_R_R=3'b010, D_W_R=3'b011, D_S_R=3'b100;
    parameter D_I_W=3'b000, D_C_W=3'b001, D_R_W=3'b010, D_W_W=3'b011, D_S_W=3'b100;
    parameter D_I_S_C=3'b000, D_C_S_C=3'b001, D_R_S_C=3'b010, D_W_S_C=3'b011, D_S_S_C=3'b100;
    parameter D_I_C_C=3'b000, D_C_C_C=3'b001, D_R_C_C=3'b010, D_W_C_C=3'b011, D_S_C_C=3'b100;
    parameter D_I_R_C=3'b000, D_C_R_C=3'b001, D_R_R_C=3'b010, D_W_R_C=3'b011, D_S_R_C=3'b100;
    parameter D_I_W_C=3'b000, D_C_W_C=3'b001, D_R_W_C=3'b010, D_W_W_C=3'b011, D_S_W_C=3'b100;
    parameter D_I_S_R=3'b000, D_C_S_R=3'b001, D_R_S_R=3'b010, D_W_S_R=3'b011, D_S_S_R=3'b100;
    parameter D_I_C_R=3'b000, D_C_C_R=3'b001, D_R_C_R=3'b010, D_W_C_R=3'b011, D_S_C_R=3'b100;
    parameter D_I_R_R=3'b000, D_C_R_R=3'b001, D_R_R_R=3'b010, D_W_R_R=3'b011, D_S_R_R=3'b100;
    parameter D_I_W_R=3'b000, D_C_W_R=3'b001, D_R_W_R=3'b010, D_W_W_R=3'b011, D_S_W_R=3'b100;
    parameter D_I_S_W=3'b000, D_C_S_W=3'b001, D_R_S_W=3'b010, D_W_S_W=3'b011, D_S_S_W=3'b100;
    parameter D_I_C_W=3'b000, D_C_C_W=3'b001, D_R_C_W=3'b010, D_W_C_W=3'b011, D_S_C_W=3'b100;
    parameter D_I_R_W=3'b000, D_C_R_W=3'b001, D_R_R_W=3'b010, D_W_R_W=3'b011, D_S_R_W=3'b100;
    parameter D_I_W_S=3'b000, D_C_W_S=3'b001, D_R_W_S=3'b010, D_W_W_S=3'b011, D_S_W_S=3'b100;
    parameter D_I_C_S=3'b000, D_C_C_S=3'b001, D_R_C_S=3'b010, D_W_C_S=3'b011, D_S_C_S=3'b100;
    parameter D_I_R_S=3'b000, D_C_R_S=3'b001, D_R_R_S=3'b010, D_W_R_S=3'b011, D_S_R_S=3'b100;
    parameter D_I_W_S_C=3'b000, D_C_W_S_C=3'b001, D_R_W_S_C=3'b010, D_W_W_S_C=3'b011, D_S_W_S_C=3'b100;
    parameter D_I_W_S_R=3'b000, D_C_W_S_R=3'b001, D_R_W_S_R=3'b010, D_W_W_S_R=3'b011, D_S_W_S_R=3'b100;
    parameter D_I_W_S_W=3'b000, D_C_W_S_W=3'b001, D_R_W_S_W=3'b010, D_W_W_S_W=3'b011, D_S_W_S_W=3'b100;
    parameter D_I_C_S_C=3'b000, D_C_C_S_C=3'b001, D_R_C_S_C=3'b010, D_W_C_S_C=3'b011, D_S_C_S_C=3'b100;
    parameter D_I_C_S_R=3'b000, D_C_C_S_R=3'b001, D_R_C_S_R=3'b010, D_W_C_S_R=3'b011, D_S_C_S_R=3'b100;
    parameter
endmodule
