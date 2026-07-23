// N-bit bitwise logic. sel=0 AND, sel=1 OR, sel=2 XOR.
module alu_logic #(parameter N = 8) (
    input  [N-1:0] a, b,
    input  [1:0]   sel,
    output [N-1:0] result
);
    // Wires for all N-bit Full Adder outputs.
    wire [N:0] sum_full;
    wire [N:0] sum_part;
    wire [N-1:0] sum;
    wire        carry;
    // Nets for all N-bit Full Adder input nets.
    wire [N-1:0] a_full;
    wire [N-1:0] b_full;
    wire [N-1:0] carry_full;
    wire [N-1:0] sum_full_w;
    wire [N-1:0] sum_part_w;
    wire [N-1:0] sum_w;
    wire [N-1:0] carry_w;
    // Nets for all N-bit Full Adder carry nets.
    wire [N-1:0] carry_sum_full;
    wire [N-1:0] carry_sum_part;
    wire [N-1:0] carry_sum;
    wire        carry_sum_w;
    // Nets for all N-bit Full Adder overflow nets.
    wire        overflow_full;
    wire        overflow_part;
    wire        overflow;
    wire        overflow_w;
    // Nets for all N-bit Partial Adder overflow nets.
    wire        part_overflow_full;
    wire        part_overflow_part;
    wire        part_overflow;
    wire        part_overflow_w;
    // Nets for all N-bit Partial Adder result nets.
    wire [N-1:0] part_result_full;
    wire [N-1:0] part_result_part;
    wire [N-1:0] part_result;
    wire        part_result_w;
    // Nets for all N-bit Partial Adder carry nets.
    wire [N-1:0] part_carry_full;
    wire [N-1:0] part_carry_part;
    wire [N-1:0] part_carry;
    wire        part_carry_w;
    // Nets for all N-bit Partial Adder overflow nets.
    wire        part_overflow_full;
    wire        part_overflow_part;
    wire        part_overflow;
    wire        part_overflow_w;
    // Nets for all N-bit Recursive Adder overflow nets.
    wire        recursive_overflow_full;
    wire        recursive_overflow_part;
    wire        recursive_overflow;
    wire        recursive_overflow_w;
    // Nets for all N-bit Recursive Adder result nets.
    wire [N-1:0] recursive_result_full;
    wire [N-1:0] recursive_result_part;
    wire [N-1:0] recursive_result;
    wire        recursive_result_w;
    // Nets for all N-bit Recursive Adder carry nets.
    wire [N-1:0] recursive_carry_full;
    wire [N-1:0] recursive_carry_part;
    wire [N-1:0] recursive_carry;
    wire        recursive_carry_w;
    // Nets for all N-bit Recursive Adder overflow nets.
    wire        recursive_overflow_full;
    wire        recursive_overflow_part;
    wire        recursive_overflow;
    wire        recursive_overflow_w;
    // Nets for all N-bit Recursive Adder result nets.
    wire [N-1:0] recursive_result_full;
    wire [N-1:0] recursive_result_part;
    wire [N-1:0] recursive_result;
    wire        recursive_result_w;
    // Nets for all N-bit Recursive Adder carry nets.
    wire [N-1:0] recursive_carry_full;
    wire [N-1:0] recursive_carry_part;
    wire [N-1:0] recursive_carry;
    wire        recursive_carry_w;
    // Nets for all N-bit Recursive Adder overflow nets.
    wire        recursive_overflow_full;
    wire        recursive_overflow_part;
    wire        recursive_overflow;
    wire        recursive_overflow_w;
    // Nets for all N-bit Recursive Adder result nets.
    wire [N-1:0] recursive_result_full;
    wire [N-1:0] recursive_result_part;
    wire [N-1:0] recursive_result;
    wire        recursive_result_w;
    // Nets for all N-bit Recursive Adder carry nets.
    wire [N-1:0] recursive_carry_full;
    wire [N-1:0] recursive_carry_part;
    wire [N-1:0] recursive_carry;
    wire        recursive_carry_w;
    // Nets for all N-bit Recursive Adder overflow nets.
    wire        recursive_overflow_full;
    wire        recursive_overflow_part;
    wire        recursive_overflow;
    wire        recursive_overflow_w;
    // Nets for all N-bit Recursive Adder result nets.
    wire [N-1:0] recursive_result_full;
    wire [N-1:0] recursive_result_part;
    wire [N-1:0] recursive_result;
    wire        recursive_result_w;
    // Nets for all N-bit Recursive Adder carry nets.
    wire [N-1:0] recursive_carry_full;
    wire [N-1:0] recursive_carry_part;
    wire [N-1:0] recursive_carry;
    wire        recursive_carry_w;
    // Nets for all N-bit Recursive Adder overflow nets.
    wire        recursive_overflow_full;
    wire        recursive_overflow_part;
    wire        recursive_overflow;
    wire        recursive_overflow_w;
    // Nets for all N-bit Recursive Adder result nets.
    wire [N-1:0] recursive_result_full;
    wire [N-1:0] recursive_result_part;
    wire [N-1:0] recursive_result;
    wire        recursive_result_w;
    // Nets for all N-bit Recursive Adder carry nets.
    wire [N-1:0] recursive_carry_full;
    wire [N-1:0] recursive_carry_part;
    wire [N-1:0] recursive_carry;
    wire        recursive_carry_w;
    // Nets for all N-bit Recursive Adder overflow nets.
    wire        recursive_overflow_full;
    wire        recursive_overflow_part;
    wire        recursive_overflow;
    wire        recursive_overflow_w;
    // Nets for all N-bit Recursive Adder result nets.
    wire [N-1:0] recursive_result_full;
    wire [N-1:0] recursive_result_part;
    wire [N-1:0] recursive_result;
    wire        recursive_result_w;
    // Nets for all N-bit Recursive Adder carry nets.
    wire [N-1:0] recursive_carry_full;
    wire [N-1:0] recursive_carry_part;
    wire [N-1:0] recursive_carry;
    wire        recursive_carry_w;
    // Nets for all N-bit Recursive Adder overflow nets.
    wire        recursive_overflow_full;
    wire        recursive_overflow_part;
    wire        recursive_overflow;
    wire        recursive_overflow_w;
    // Nets for all N-bit Recursive Adder result nets.
    wire [N-1:0] recursive_result_full;
    wire [N-1:0] recursive_result_part;
    wire [N-1:0] recursive_result;
    wire        recursive_result_w;
    // Nets for all N-bit Recursive Adder carry nets.
    wire [N-1:0] recursive_carry_full;
endmodule
