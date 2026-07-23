// Parameterized N-bit adder-subtractor. op=0: result=a+b carry_out. op=1: result=a-b borrow.
module alu_addsub #(parameter N = 8) (
    input  [N-1:0] a, b,
    input          op,
    output [N-1:0] result,
    output         carry_out
);
    genvar i;
    wire [N-1:0] carry;
    assign carry_out = carry[N-1];
    generate
        for (i = 0; i < N; i = i+1) begin
            if (i == 0)
                half_adder #(.N(N)) U_adder (
                   .a(a[i]),
                   .b(b[i]),
                   .sum(result[i]),
                   .carry(carry[i])
                );
            else
                full_adder #(.N(N)) U_adder (
                   .a(a[i]),
                   .b(b[i]),
                   .sum(result[i]),
                   .carry(carry[i])
                );
        end
    endgenerate

endmodule
