`timescale 1ns/1ps
// M14: Hardware bubble sort integration top
// 8 elements, 8-bit unsigned.
// bubble_sort_fsm controls load_en, swap_en, i (compare index), j (pass index).
// compare_swap does one element swap combinationally each cycle swap_en is high.
module bubble_sort_integration (
    input         clk, rst, start,
    input  [63:0] data_in_flat,
    output [63:0] data_out_flat,
    output        done
);
    reg [7:0] arr [0:7];

    wire [1:0] state;
    wire [2:0] i, j;
    wire       swap_en, load_en;

    bubble_sort_fsm u_fsm (
        .clk(clk), .rst(rst), .start(start),
        .state(state), .i(i), .j(j),
        .swap_en(swap_en), .load_en(load_en), .done(done)
    );

    // Compare-swap on arr[i] and arr[i+1]
    wire [7:0] cs_hi, cs_lo;
    compare_swap u_cs (
        .a(arr[i]), .b(arr[i+1]),
        .hi(cs_hi), .lo(cs_lo)
    );

    integer k;
    always @(posedge clk) begin
        if (rst) begin
            for (k = 0; k < 8; k = k+1) arr[k] <= 8'h0;
        end else if (load_en) begin
            for (k = 0; k < 8; k = k+1)
                arr[k] <= data_in_flat[8*k +: 8];
        end else if (swap_en) begin
            arr[i]   <= cs_hi;
            arr[i+1] <= cs_lo;
        end
    end

    genvar gi;
    generate
        for (gi = 0; gi < 8; gi = gi+1) begin : PACK
            assign data_out_flat[8*gi +: 8] = arr[gi];
        end
    endgenerate
endmodule
