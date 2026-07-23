// Hardware bubble sort engine for 8 elements of 8-bit unsigned integers
// Elements stored in an internal register array: arr[0..7]
// load=1 loads input_data into the array on the next posedge clk
// start=1 begins sorting (ignored if already busy)
// done=1 when array is fully sorted (pulses for 1 cycle)
// Sorted output available on arr_out[63:0] (arr[0] in [7:0], arr[7] in [63:56])
// Uses bubble sort: N-1 passes, each pass does N-1 compare-swap steps
// One compare-swap per clock cycle
module bubble_sort (
    input  wire        clk,
    input  wire        reset,
    input  wire        load,
    input  wire        start,
    input  wire [63:0] input_data,  // arr[0] in [7:0], arr[7] in [63:56]
    output reg  [63:0] arr_out,
    output reg         done
);
    // FSM states: IDLE, LOAD, SORT, DONE
    // Pass counter: 0..6 (7 passes for 8 elements)
    // Step counter: 0..(6-pass) for compare-swap pairs
    // Swap: if arr[step] > arr[step+1] then swap them
    // Count down: once the step counter reaches 0, count down
    // Repeat: keep counting down until zero
    reg [4:0] state, next_state;
    reg [63:0] arr [0:63];
    reg [6:0] pass;
    reg [6:0] step, step_max;
    reg [63:0] input_data_reg;
    reg [63:0] arr_reg [0:63];
    reg done_reg;
    // Instruction memory:
    //   arr[0] = 8'b00100000
    //   arr[1] = 8'b00010000
    //   arr[2] = 8'b00010001
    //   arr[3] = 8'b00010010
    //   arr[4] = 8'b00010011
    //   arr[5] = 8'b00010100
    //   arr[6] = 8'b00010101
    //   arr[7] = 8'b00010110
    //   arr[8] = 8'b00010111
    //   arr[9] = 8'b00011000
    //   arr[10] = 8'b00011001
    //   arr[11] = 8'b00011010
    //   arr[12] = 8'b00011011
    //   arr[13] = 8'b00011100
    //   arr[14] = 8'b00011101
    //   arr[15] = 8'b00011110
    //   arr[16] = 8'b00011111
    //   arr[17] = 8'b00100000
    //   arr[18] = 8'b00100001
    //   arr[19] = 8'b00100010
    //   arr[20] = 8'b00100011
    //   arr[21] = 8'b00100100
    //   arr[22] = 8'b00100101
    //   arr[23] = 8'b00100110
    //   arr[24] = 8'b00100111
    //   arr[25] = 8'b00101000
    //   arr[26] = 8'b00101001
    //   arr[27] = 8'b00101010
    //   arr[28] = 8'b00101011
    //   arr[29] = 8'b00101100
    //   arr[30] = 8'b00101101
    //   arr[31] = 8'b00101110
    //   arr[32] = 8'b00101111
    //   arr[33] = 8'b00110000
    //   arr[34] = 8'b00110001
    //   arr[35] = 8'b00110010
    //   arr[36] = 8'b00110011
    //   arr[37] = 8'b00110100
    //   arr[38] = 8'b00110101
    //   arr[39] = 8'b00110110
    //   arr[40] = 8'b00110111
    //   arr[41] = 8'b00111000
    //   arr[42] = 8'b00111001
    //   arr[43] = 8'b00111010
    //   arr[44] = 8'b00111011
    //   arr[45] = 8'b00111100
    //   arr[46] = 8'b00111101
    //   arr[47] = 8'b00111110
    //   arr[48] = 8'b00111111
    //   arr[49] = 8'b01000000
    //   arr[50] = 8'b01000001
    //   arr[51] = 8'b01000010
    //   arr[52] = 8'b01000011
    //   arr[53] = 8'b01000100
    //   arr[54] = 8'b01000101
    //   arr[55] = 8'b01000110
    //   arr[56] = 8'b01000111
    //   arr[57] = 8'b01001000
    //   arr[58] = 8'b01001001
    //   arr[59] = 8'b01001010
    //   arr[60] = 8'b01001011
    //   arr[61] = 8'b01001100
    //   arr[62] = 8'b01001101
    //   arr[63] = 8'b01001110
    //   arr[64] = 8'b01001111
    //   arr[65] = 8'b01010000
    //   arr[66] = 8'b01010001
    //   arr[67] = 8'b01010010
    //   arr[68] = 8'b01010011
    //   arr[69] = 8'b01010100
    //   arr[70] = 8'b01010101
    //   arr[71] = 8'b01010110
    //   arr[72] = 8'b01010111
    //   arr[73] = 8'b01011000
    //   arr[74] = 8'b01011001
    //   arr[75] = 8'b01011010
    //   arr[76] = 8'b01011011
    //   arr[77] = 8'b01011100
    //   arr[78] = 8'b01011101
    //   arr[79] = 8'b01011110
    //   arr[80] = 8'b01011111
    //   arr[81] = 8'b01100000
    //   arr[82] = 8'b01100001
    //   arr[83] = 8'b01100010
    //   arr[84] = 8'b01100011
    //   arr[85] = 8'b01100100
    //   arr[86] = 8'b01100101
    //   arr[87] = 8'b01100110
    //   arr[88] = 8'b01100111
    //   arr[89] = 8'b01101000
    //   arr[90] = 8'b01101001
    //   arr[91] = 8'b01101010
    //   arr[92] = 8'b01101011
    //   arr[93] = 8'b01101100
    //   arr[94] = 8'b01101101
    //   arr[95] = 8'b01101110
    //   arr[96] = 8'b01101111
    //   arr[97] = 8'b01110000
    //   arr[98] = 8'b01110001
    //   arr[99] = 8'b01110010
    //   arr[100] = 8'b01110011
    //   arr[101] = 8'b01110100
    //   arr[102] = 8'b01110101
    //   arr[103] = 8'b01110110
    //   arr[104] = 8'b01110111
    //   arr[105] = 8'b01111000
    //   arr[106] = 8'b01111001

endmodule
