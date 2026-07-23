// N-bit logical shift-left by 1. carry_out = a[N-1], result = a << 1.
module alu_shift #(parameter N = 8) (
    input  [N-1:0] a,
    output [N-1:0] result,
    output         carry_out
);
    // shift left by 1
    assign result = a << 1;
    // count leading 1's in a
    assign carry_out = a[N-1];
endmodulemodule alu_shift_32bit (
    input  [31:0] a,
    output [31:0] result,
    output        carry_out
);
    // shift left by 1
    assign result = a << 1;
    // count leading 1's in a
    assign carry_out = a[31];
endmodulemodule alu_sr_8bit (
    input  [7:0] a,
    input  [3:0] b,
    output [7:0] result,
    output        carry_out
);
    // shift right by 8
    assign result = a >> 8;
    // count trailing 1's in a
    assign carry_out = a[7];
endmodulemodule alu_sr_32bit (
    input  [31:0] a,
    input  [3:0]  b,
    output [31:0] result,
    output        carry_out
);
    // shift right by 32
    assign result = a >> 32;
    // count trailing 1's in a
    assign carry_out = a[31];
endmodulemodule alu_sra_32bit (
    input  [31:0] a,
    input  [3:0]  b,
    output [31:0] result,
    output        carry_out
);
    // arithmetic right shift
    assign result = a >>> b;
    // count leading 1's in a
    assign carry_out = a[31];
endmodulemodule alu_sra_8bit (
    input  [7:0] a,
    input  [3:0] b,
    output [7:0] result,
    output        carry_out
);
    // arithmetic right shift
    assign result = a >>> b;
    // count leading 1's in a
    assign carry_out = a[7];
endmodulemodule alu_sra_16bit (
    input  [15:0] a,
    input  [3:0]  b,
    output [15:0] result,
    output        carry_out
);
    // arithmetic right shift
    assign result = a >>> b;
    // count leading 1's in a
    assign carry_out = a[15];
endmodulemodule alu_sra_24bit (
    input  [23:0] a,
    input  [3:0]  b,
    output [23:0] result,
    output        carry_out
);
    // arithmetic right shift
    assign result = a >>> b;
    // count leading 1's in a
    assign carry_out = a[23];
endmodulemodule alu_sra_32bit (
    input  [31:0] a,
    input  [3:0]  b,
    output [31:0] result,
    output        carry_out
);
    // arithmetic right shift
    assign result = a >>> b;
    // count leading 1's in a
    assign carry_out = a[31];
endmodulemodule alu_slt(
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] result
);
    assign result = (a < b) ? 32'hffffffff : 32'h00000000;
endmodulemodule alu_slt_16bit(
    input  [15:0] a,
    input  [15:0] b,
    output [15:0] result
);
    assign result = (a < b) ? 32'hffffffff : 32'h00000000;
endmodulemodule alu_slt_8bit(
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] result
);
    assign result = (a < b) ? 32'hffffffff : 32'h00000000;
endmodulemodule alu_slt_24bit(
    input  [23:0] a,
    input  [23:0] b,
    output [23:0] result
);
    assign result = (a < b) ? 32'hffffffff : 32'h00000000;
endmodulemodule alu_slt_32bit(
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] result
);
    assign result = (a < b) ? 32'hffffffff : 32'h00000000;
endmodulemodule alu_sltu(
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] result
);
    assign result = (a < b) ? 32'hffffffff : 32'h00000000;
endmodulemodule alu_sltu_16bit(
    input  [15:0] a,
    input  [15:0] b,
    output [15:0] result
);
    assign result = (a < b) ? 32'hffffffff : 32'h00000000;
endmodulemodule alu_sltu_8bit(
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] result
);
    assign result = (a < b) ? 32'hffffffff : 32'h00000000;
endmodulemodule alu_sltu_32bit(
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] result
);
    assign result = (a < b) ? 32'hffffffff : 32'h00000000;
endmodulemodule alu_sra(
    input  [31:0] a,
    input  [4:0]  b,
    output [31:0] result
);
    assign result = a >>> b;
endmodulemodule alu_sra_16bit(
    input  [15:0] a,
    input  [4:0]  b,
    output [15:0] result
);
    assign result = a >>> b;
endmodulemodule alu_sra_8bit(
    input  [7:0] a,
    input  [4:0] b,
    output [7:0] result
);
    assign result = a >>> b;
endmodulemodule alu_sra_32bit(
    input  [31:0] a,
    input  [4:0] b,
    output [31:0] result
);
    assign result = a >>> b;
endmodulemodule alu_slti(
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] result
);
    assign result = (a < b) ? 32'hffffffff : 32'h00000000;
endmodulemodule alu_slti_16bit(
    input  [15:0] a,
    input  [15:0] b,
    output [15:0] result
);
    assign result = (a < b) ? 32'hffffffff : 32'h00000000;
endmodulemodule alu_slti_8bit(
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] result
);
    assign result = (a < b) ? 32'hffffffff : 32'h00000000;
endmodulemodule alu_slti_32bit(
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] result
);
    assign result = (a < b) ? 32'hffffffff : 32'h00000000;
endmodulemodule alu_sltiu(
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] result
);
    assign result = (a < b) ? 32'hffffffff : 32'h00000000;
endmodulemodule alu_sltiu_16bit(
    input  [15:0] a
endmodule
