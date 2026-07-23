// 32-bit ALU. op: 0=ADD, 1=SUB, 2=AND, 3=OR. Combinational result and zero flag.
module cpu_alu (
    input  [31:0] a, b,
    input  [1:0]  op,
    output [31:0] result,
    output        zero
);

wire [31:0] result_mux;
wire        zero_mux;

mux2 #(32) mux_a (
   .a(a),
   .b(32'b0),
   .s(op[0]),
   .y(result_mux)
);

mux2 #(32) mux_b (
   .a(b),
   .b(32'b0),
   .s(op[0]),
   .y(result_mux)
);

mux2 #(1) mux_zero (
   .a(1'b0),
   .b(1'b0),
   .s(op[1]),
   .y(zero_mux)
);

mux2 #(32) mux_result (
   .a(result_mux),
   .b(32'b0),
   .s(op[1]),
   .y(result)
);

mux2 #(1) mux_zero_mux (
   .a(zero_mux),
   .b(1'b0),
   .s(op[1]),
   .y(zero)
);


endmodule
