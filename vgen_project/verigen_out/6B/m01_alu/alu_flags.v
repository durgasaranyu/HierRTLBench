// Zero and carry flag generator. zero=1 when result==0.
module alu_flags #(parameter N = 8) (
    input  [N-1:0] result,
    input          carry_in,
    output         zero_flag,
    output         carry_flag
);
    assign carry_flag = carry_in;
    assign zero_flag = (result == 0) ? 1 : 0;
endmodule
`timescale 1ns / 1ps

module alu_flags_tb;

    reg [7:0] result;
    reg carry_in;
    wire zero_flag, carry_flag;

    alu_flags #(8) uut (
        .result(result),
        .carry_in(carry_in),
        .zero_flag(zero_flag),
        .carry_flag(carry_flag)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(1);
        $monitor("result=%b, carry_in=%b, zero_flag=%b, carry_flag=%b", result, carry_in, zero_flag, carry_flag);
        result = 8'b11111111;
        carry_in = 1;
        #
endmodule
