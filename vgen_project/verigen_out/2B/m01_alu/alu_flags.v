// Zero and carry flag generator. zero=1 when result==0.
module alu_flags #(parameter N = 8) (
    input  [N-1:0] result,
    input          carry_in,
    output         zero_flag,
    output         carry_flag
);
    assign zero_flag = (result == 0);
    assign carry_flag = carry_in | (result[N-1] & ~zero_flag);

endmodule
