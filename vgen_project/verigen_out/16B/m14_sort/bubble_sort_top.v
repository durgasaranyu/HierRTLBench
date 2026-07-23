// Hardware bubble sort top. 8 elements, 8-bit unsigned. FSM IDLE/LOAD/SORT/DONE.
// One compare-swap per clock cycle. done asserts when sorted.
module bubble_sort (
    input        clk, rst, start,
    input  [63:0] data_in_flat,
    output [63:0] data_out_flat,
    output        done
);
    reg [63:0] data_in [0:7];
    reg [63:0] data_out [0:7];
    reg [63:0] data_out_reg [0:7];
    reg [63:0] data_out_next [0:7];
    reg [3:0]  state, next_state;
    reg [63:0] sort0, sort1, sort2, sort3, sort4, sort5, sort6, sort7;
    reg [63:0] sort0_reg, sort1_reg, sort2_reg, sort3_reg, sort4_reg, sort5_reg, sort6_reg, sort7_reg;
    reg [63:0] sort0_next, sort1_next, sort2_next, sort3_next, sort4_next, sort5_next, sort6_next, sort7_next;
    reg [63:0] sort0_reg_next, sort1_reg_next, sort2_reg_next, sort3_reg_next, sort4_reg_next, sort5_reg_next, sort6_reg_next, sort7_reg_next;
    reg [63:0] sort_reg [0:7];
    reg [63:0] sort_next [0:7];
    reg [63:0] sort_reg_next [0:7];
    reg [63:0] data_in_reg [0:7];
    reg [63:0] data_in_next [0:7];
    reg [63:0] data_out_reg [0:7];
    reg [63:0] data_out_next [0:7];
    reg [63:0] data_out_reg_next [0:7];
    reg [63:0] data_out_next_reg [0:7];
    reg [63:0] data_out_reg_next_reg [0:7];
    reg [63:0] data_out_next_reg_next [0:7];
    reg [63:0] data_out_reg_next_reg_next [0:7];
    reg [63:0] data_out_next_reg_next_reg [0:7];
    reg [63:0] data_out_reg_next_reg_next_reg [0:7];
    reg [63:0] data_out_next_reg_next_reg_next [0:7];
    reg [63:0] data_out_reg_next_reg_next_reg_next [0:7];
    reg [63:0] data_out_next_reg_next_reg_next_reg [0:7];
    reg [63:0] data_out_reg_next_reg_next_reg_next_reg [0:7];
    reg [63:0] data_out_next_reg_next_reg_next_reg_next [0:7];
    reg [63:0] data_out_reg_next_reg_next_reg_next_reg_next [0:7];
    reg [63:0] data_out_next_reg_next_reg_next_reg_next_reg [0:7];
    reg [63:0] data_out_reg_next_reg_next_reg_next_reg_next_reg [0:7];
    reg [63:0] data_out_next_reg_next_reg_next_reg_next_reg_next [0:7];
    reg [63:0] data_out_reg_next_reg_next_reg_next_reg_next_reg [0:7];
    reg [63:0] data_out_next_reg_next_reg_next_reg_next_reg_next [0:7];
    reg [63:0] data_out_reg_next_reg_next_reg_next_reg_next_reg [0:7];
    reg [63:0] data_out_next_reg_next_reg_next_reg_next_reg_next [0:7];
    reg [63:0] data_out_reg_next_reg_next_reg_next_reg_next_reg [0:7];
    reg [63:0] data_out_next_reg_next_reg_next_reg_next_reg_next [0:7];
    reg [63:0] data_out_reg_next_reg_next_reg_next_reg_next_reg [0:7];
    reg [63:0] data_out_next_reg_next_reg_next_reg_next_reg_next [0:7];
    reg [63:0] data_out_reg_next_reg_next_reg_next_reg_next_reg [0:7];
    reg [63:0] data_out_next_reg_next_reg_next_reg_next_reg_next [0:7];
    reg [63:0] data_out_reg_next_reg_next_reg_next_reg_next_reg [0:7];
    reg [63:0] data_out_next_reg_next_reg_next_reg_next_reg_next [0:7];
    reg [63:0] data_out_reg_next_reg_next_reg_next_reg_next_reg [0:7];
    reg [63:0] data_out_next_reg_next_reg_next_reg_next_reg_next [0:7];
    reg [63:0] data_out_reg_next_reg_next_reg_next_reg_next_reg [0:7];
    reg [63:0] data_out_next_reg_next_reg_next_reg_next_reg_next [0:7];
    reg [63:0] data_out_reg_next_reg_next_reg_next_reg_next_reg [0:7];
    reg [63:0] data_out_next_reg_next_reg_next_reg_next_reg_next [0:7];
    reg [63:0] data_out_reg_next_reg_next_reg_next_reg_next_reg [0:7];
    reg [63:0] data_out_next_reg_next_reg_next_reg_next_reg_next [0:7];
    reg [63:0] data_out_reg_next_reg_next_reg_next_reg_next_reg [0:7];
    reg [63:0] data_out_next_reg_next_reg_next_reg_next_reg_next [0:7];
    reg [63:0] data_out_reg_next_reg_next_reg_next_reg_next_reg [0:7];
    reg [63:0] data_out_next_reg_next_reg_next_reg_next_reg_next [0:7];
    reg [63:0] data_out_reg_next_reg_next_reg_next_reg_next_reg [0:7];
    reg [63:0] data_out_next_reg_next_reg_next_reg_next_reg_next [0:7];
    reg [63:0] data_out_reg_next_reg_next_reg_next_reg_next_reg [0:7];
    reg [63:0] data_out_next_reg_next_reg_next_reg_next_reg_next [0:7];
    reg [63:0] data_out_reg_next_reg_next_reg_next_reg_next_reg [0:7];
    reg [63:0] data_out_next_reg_next_reg_next_reg_next_reg_next [0:7];
    reg [63:0] data_out_reg_next_reg_next_reg_next_reg_next_reg [0:7];
    reg [63:0] data_out_next_reg_next_reg_next_reg_next_reg_next [0:7];
    reg [63:0] data_out_reg_next_reg_next_reg_next_reg_next_reg [0:7];
endmodule
