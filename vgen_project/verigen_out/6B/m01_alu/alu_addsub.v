// Parameterized N-bit adder-subtractor. op=0: result=a+b carry_out. op=1: result=a-b borrow.
module alu_addsub #(parameter N = 8) (
    input  [N-1:0] a, b,
    input          op,
    output [N-1:0] result,
    output         carry_out
);
    // a+b if op=0, else a-b
    assign result = op ? ~a+1 : a+b;
    assign carry_out = op ? (a[N-1] ^ b[N-1]) : (a[N-1] ^ ~b[N-1]);
endmodule

module alu_addsub_8bit (
    input  [7:0] a, b,
    input          op,
    output [7:0]  result,
    output         carry_out
);
    // a+b if op=0, else a-b
    assign result = op ? ~a+1 : a+b;
    assign carry_out = op ? (a[7] ^ b[7]) : (a[7] ^ ~b[7]);
endmodule

module alu_addsub_16bit (
    input  [15:0] a, b,
    input          op,
    output [15:0] result,
    output         carry_out
);
    // a+b if op=0, else a-b
    assign result = op ? ~a+1 : a+b;
    assign carry_out = op ? (a[15] ^ b[15]) : (a[15] ^ ~b[15]);
endmodule

module alu_addsub_32bit (
    input  [31:0] a, b,
    input          op,
    output [31:0] result,
    output         carry_out
);
    // a+b if op=0, else a-b
    assign result = op ? ~a+1 : a+b;
    assign carry_out = op ? (a[31] ^ b[31]) : (a[31] ^ ~b[31]);
endmodule

module alu_slt (
    input  [31:0] a, b,
    output [31:0] result,
    output c
);
    assign result = (a < b) ? 32'd1 : 32'd0;
    assign c = result[31];
endmodule

module alu_slt_16bit (
    input  [15:0] a, b,
    output [15:0] result,
    output c
);
    assign result = (a < b) ? 16'd1 : 16'd0;
    assign c = result[15];
endmodule

module alu_slt_8bit (
    input  [7:0] a, b,
    output [7:0] result,
    output c
);
    assign result = (a < b) ? 8'd1 : 8'd0;
    assign c = result[7];
endmodule

module alu_slt_32bit (
    input  [31:0] a, b,
    output [31:0] result,
    output c
);
    assign result = (a < b) ? 32'd1 : 32'd0;
    assign c = result[31];
endmodule

module alu_sr_16bit (
    input  [15:0] a, b,
    output [15:0] result,
    output c
);
    assign result = a >> b;
    assign c = result[15];
endmodule

module alu_sr_8bit (
    input  [7:0] a, b,
    output [7:0] result,
    output c
);
    assign result = a >> b;
    assign c = result[7];
endmodule

module alu_sr_32bit (
    input  [31:0] a, b,
    output [31:0] result,
    output c
);
    assign result = a >> b;
    assign c = result[31];
endmodule

module alu_sra (
    input  [31:0] a, b,
    output [31:0] result,
    output c
);
    assign result = a >>> b;
    assign c = result[31];
endmodule

module alu_srai (
    input  [31:0] a, b,
    output [31:0] result,
    output c
);
    assign result = a >>> b;
    assign c = result[31];
endmodule

module alu_sra_16bit (
    input  [15:0] a, b,
    output [15:0] result,
    output c
);
    assign result = a >>> b;
    assign c = result[15];
endmodule

module alu_sra_8bit (
    input  [7:0] a, b,
    output [7:0] result,
    output c
);
    assign result = a >>> b;
    assign c = result[7];
endmodule

module alu_sra_32bit (
    input  [31:0] a, b,
    output [31:0] result,
    output c
);
    assign result = a >>> b;
    assign c = result[31];
endmodule

module alu_slti (
    input  [31:0] a, b,
    output [31:0] result,
    output c
);
    assign result = (a < b) ? 32'd1 : 32'd0;
    assign c = result[31];
endmodule

module alu_sltiu (
    input  [31:0] a, b,
    output [31:0] result,
    output c
);
    assign result = (a < b) ? 32'd1 : 32'd0;
    assign c = result[31];
endmodule

module alu_slti_16bit (
    input  [15:0] a, b,
    output [15:0] result,
    output c
);
    assign result = (a < b) ? 16'd1 : 16'd0;
    assign c = result[15];
endmodule

module alu_slti_8bit (
    input  [7:0] a, b,
    output [7:0] result,
    output c
);
    assign result = (a < b) ? 8'd1 : 8'd0;
    assign c = result[7];
endmodule

module alu_slti_32bit (
    input  [31:0] a, b,
    output [31:0] result,
    output c
);
    assign result = (a < b) ? 32'd1 : 32'd0;
    assign c = result[31];
endmodule

module alu_sltiu (
    input  [31:0] a, b,
    output [31:0] result,
    output c
);
    assign result = (a < b) ? 32'd1 : 32'd0;
    assign c = result[31];
endmodule

module alu_sltiu_16bit (
    input  [15:0] a, b,
    output [15:0] result,
    output c
);
    assign result = (a < b) ? 16'd1 : 16'd0;
    assign c = result[15];
endmodule

module alu_sltiu_8bit (
    input  [7:0] a, b,
    output [7:0] result,
    output c
);
    assign result = (a < b) ? 8'd1 : 8'd0;
    assign c = result[7];
endmodule

module alu_sltiu_32bit (
    input  [31:0] a, b,
    output [31:0] result,
    output c
);
    assign result = (a < b) ? 32'd1 : 32'd0;
    assign c = result[31];
endmodule

module alu_slt_16bit (
    input  [15:0] a, b,
    output [15:0] result,
    output c
);
    assign result = (a < b) ? 16'd1 : 16'd0;

endmodule
