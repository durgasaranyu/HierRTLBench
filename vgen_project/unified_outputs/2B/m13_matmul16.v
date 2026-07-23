// 16x16 matrix multiplier using multiply-accumulate (MAC) units
// Operands: A[16][16] and B[16][16], each element is 16-bit unsigned
// Result:   C[16][16], each element is 32-bit unsigned (sum of 16 products)
// C[i][j] = sum_{k=0}^{15} A[i][k] * B[k][j]
// Computation is pipelined: one row of C computed per clock after startup
// valid_out pulses high when all 256 C elements are ready
// Matrices stored in flat arrays: A[i*16+j] = A_flat[i*16+j]
module matmul16 (
    input  wire          clk,
    input  wire          reset,
    input  wire          start,
    input  wire [4095:0] A_flat,   // 16x16 x 16-bit = 4096 bits
    input  wire [4095:0] B_flat,
    output reg  [8191:0] C_flat,   // 16x16 x 32-bit = 8192 bits
    output reg           valid_out
);
    // Use generate block to instantiate 16 MAC units per output row
    // Each MAC: 16 partial products accumulated in a 32-bit register
    // Row counter drives which row of A is being processed
    reg [4:0] A_index, B_index;
    always @(posedge clk) begin
        if (reset) begin
            A_index <= 0;
            B_index <= 0;
        end else if (start) begin
            A_index <= A_index + 1;
            B_index <= B_index + 1;
        end
    end
    // Output valid signal pulsed for one clock cycle per output row
    // Each MAC produces a partial product of its input, so each output
    // row has a delay of one clock cycle
    reg [8191:0] partial_products;
    always @(posedge clk) begin
        if (reset) begin
            partial_products <= 0;
        end else if (valid_out) begin
            partial_products <= partial_products + A_index * B_index;
        end
    end
    // Output valid signal pulsed for one clock cycle per output row
    // Each MAC produces a partial product of its input, so each output
    // row has a delay of one clock cycle
    reg [8191:0] partial_products_1;
    always @(posedge clk) begin
        if (reset) begin
            partial_products_1 <= 0;
        end else if (valid_out) begin
            partial_products_1 <= partial_products;
        end
    end
    // Output valid signal pulsed for one clock cycle per output row
    // Each MAC produces a partial product of its input, so each output
    // row has a delay of one clock cycle
    reg [8191:0] partial_products_2;
    always @(posedge clk) begin
        if (reset) begin
            partial_products_2 <= 0;
        end else if (valid_out) begin
            partial_products_2 <= partial_products_1;
        end
    end
    // Output valid signal pulsed for one clock cycle per output row
    // Each MAC produces a partial product of its input, so each output
    // row has a delay of one clock cycle
    reg [8191:0] partial_products_3;
    always @(posedge clk) begin
        if (reset) begin
            partial_products_3 <= 0;
        end else if (valid_out) begin
            partial_products_3 <= partial_products_2;
        end
    end
    // Output valid signal pulsed for one clock cycle per output row
    // Each MAC produces a partial product of its input, so each output
    // row has a delay of one clock cycle
    reg [8191:0] partial_products_4;
    always @(posedge clk) begin
        if (reset) begin
            partial_products_4 <= 0;
        end else if (valid_out) begin
            partial_products_4 <= partial_products_3;
        end
    end
    // Output valid signal pulsed for one clock cycle per output row
    // Each MAC produces a partial product of its input, so each output
    // row has a delay of one clock cycle
    reg [8191:0] partial_products_5;
    always @(posedge clk) begin
        if (reset) begin
            partial_products_5 <= 0;
        end else if (valid_out) begin
            partial_products_5 <= partial_products_4;
        end
    end
    // Output valid signal pulsed for one clock cycle per output row
    // Each MAC produces a partial product of its input, so each output
    // row has a delay of one clock cycle
    reg [8191:0] partial_products_6;
    always @(posedge clk) begin
        if (reset) begin
            partial_products_6 <= 0;
        end else if (valid_out) begin
            partial_products_6 <= partial_products_5;
        end
    end
    // Output valid signal pulsed for one clock cycle per output row
    // Each MAC produces a partial product of its input, so each output
    // row has a delay of one clock cycle
    reg [8191:0] partial_products_7;
    always @(posedge clk) begin
        if (reset) begin
            partial_products_7 <= 0;
        end else if (valid_out) begin
            partial_products_7 <= partial_products_6;
        end
    end
    // Output valid signal pulsed for one clock cycle per output row
    // Each MAC produces a partial product of its input, so each output
    // row has a delay of one clock cycle
    reg [8191:0] partial_products_8;
    always @(posedge clk) begin
        if (reset) begin
            partial_products_8 <= 0;
        end else if (valid_out) begin
            partial_products_8 <= partial_products_7;
        end
    end
    // Output valid signal pulsed for one clock cycle per output row
    // Each MAC produces a partial product of its input, so each output
    // row has a delay of one clock cycle
    reg [8191:0] partial_products_9;
    always @(posedge clk) begin
        if (reset) begin
            partial_products_9 <= 0;
        end else if (valid_out) begin
            partial_products_9 <= partial_products_8;
        end
    end
    // Output valid signal pulsed for one clock cycle per output row
    // Each MAC produces a partial product of its input, so each output
    // row has a delay of one clock cycle
    reg [8191:0] partial_products_10;
    always @(posedge clk) begin
        if (reset) begin
            partial_products_10 <= 0;
        end else if (valid_out) begin
            partial_products_10 <= partial_products_9;
        end
    end
    // Output valid signal pulsed for one clock cycle per output row
    // Each MAC produces a partial product of its input, so each output
    // row has a delay of one clock cycle
    reg [8191:0] partial_products_11;
    always @(posedge clk) begin
        if (reset) begin
            partial_products_11 <= 0;
        end else if (valid_out) begin
            partial_products_11 <= partial_products_10;
        end
    end
    // Output valid signal pulsed for one clock cycle per output row
    // Each MAC produces a partial product of its input, so each output
    // row has a delay of one clock cycle
    reg [8191:0] partial_products_12;
    always @(posedge clk) begin
        if (reset) begin
            partial_products_12 <= 0;
        end else if (valid_out) begin
            partial_products_12 <= partial_products_11;
        end
    end
    // Output valid signal pulsed for one clock cycle per output row
    // Each MAC produces a partial product of its input, so each output
    // row has a delay of one clock cycle
    reg [8191:0] partial_products_13;
    always @(posedge clk) begin
        if (reset) begin
            partial_products_13 <= 0;
        end else if (valid_out) begin
            partial_products_13 <= partial_products_12;
        end
    end
    // Output valid signal pulsed for one clock cycle per output row
    // Each MAC produces a partial product of
endmodule
