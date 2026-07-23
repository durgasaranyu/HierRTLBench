// SHA-256 64-round compression function. Input: H[0..7] init hash + W[0..63] schedule.
// Updates a..h each round. Output: H_out = H_in + {a,b,c,d,e,f,g,h}.
module sha256_compress (
    input  [255:0]  H_in,
    input  [2047:0] W,
    output [255:0]  H_out
);
    // input [31:0]  H_in;
    // input [31:0]  W;
    // output [31:0] H_out;
    assign H_out = {H_in, W};
endmodulemodule sha256_test();
    reg clk;
    reg [31:0] in;
    reg [31:0] expected;
    reg [31:0] counter;
    reg [31:0] block_counter;
    reg start;
    reg [31:0] cycles;
    initial begin
        cycles = 32'd10;
        clk = 0;
        in = 0;
        counter = 0;
        block_counter = 0;
        expected = 0;
    end
    always #(cycles/2) clk = ~clk;
    always @(posedge clk) begin
        if (counter == 2) begin
            in <= `rev64(start,1*64);
            counter <= 0;
        end
        if (counter < 2)
            counter <= counter + 1;
        if (counter == 2) begin
            if (block_counter < 2)
                block_counter <= block_counter + 1;
            else
                block_counter <= 0;
        end
        if (counter == 1)
            start <= !start;
        if (counter > 2)
            expected <= expected + 1;
    end
    always @(posedge clk) begin
        if (start) begin
            if (block_counter == 2) begin
                if (counter == 2)
                    $finish();
                else
                    counter <= counter + 1;
            end
            else
                block_counter <= block_counter + 1;
        end
    end
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end
endmodulemodule tb_sha256();
    reg clk;
    reg [31:0] in;
    reg [31:0] expected;
    reg [31:0] counter;
    reg [31:0] block_counter;
    reg start;
    reg [31:0] cycles;
    initial begin
        cycles = 32'd10;
        clk = 0;
        in = 0;
        counter = 0;
        block_counter = 0;
        expected = 0;
    end
    always #(cycles/2) clk = ~clk;
    always @(posedge clk) begin
        if (counter == 2) begin
            in <= `rev64(start,1*64);
            counter <= 0;
        end
        if (counter < 2)
            counter <= counter + 1;
        if (counter == 2) begin
            if (block_counter < 2)
                block_counter <= block_counter + 1;
            else
                block_counter <= 0;
        end
        if (counter == 1)
            start <= !start;
        if (counter > 2)
            expected <= expected + 1;
    end
    always @(posedge clk) begin
        if (start) begin
            if (block_counter == 2) begin
                if (counter == 2)
                    $finish();
                else
                    counter <= counter + 1;
            end
            else
                block_counter <= block_counter + 1;
        end
    end
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end
endmodulemodule tb_sha256_test();
    reg clk;
    reg [31:0] in;
    reg [31:0] expected;
    reg [31:0] counter;
    reg [31:0] block_counter;
    reg start;
    reg [31:0] cycles;
    initial begin
        cycles = 32'd10;
        clk = 0;
        in = 0;
        counter = 0;
        block_counter = 0;
        expected = 0;
    end
    always #(cycles/2) clk = ~clk;
    always @(posedge clk) begin
        if (counter == 2) begin
            in <= `rev64(start,1*64);
            counter <= 0;
        end
        if (counter < 2)
            counter <= counter + 1;
        if (counter == 2) begin
            if (block_counter < 2)
                block_counter <= block_counter + 1;
            else
                block_counter <= 0;
        end
        if (counter == 1)
            start <= !start;
        if (counter > 2)
            expected <= expected + 1;
    end
    always @(posedge clk) begin
        if (start) begin
            if (block_counter == 2) begin
                if (counter == 2)
                    $finish();
                else
                    counter <= counter + 1;
            end
            else
                block_counter <= block_counter + 1;
        end
    end
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end
endmodulemodule tb_sha256_test();
    reg clk;
    reg [31:0] in;
    reg [31:0] expected;
    reg [31:0] counter;
    reg [31:0] block_counter;
    reg start;
    reg [31:0] cycles;
    initial begin
        cycles = 32'd10;
        clk = 0;
        in = 0;
        counter = 0;
        block_counter = 0;
        expected = 0;
    end
    always #(cycles/2) clk = ~clk;
    always @(posedge clk) begin
        if (counter == 2) begin
            in <= `rev64(start,1*64);
            counter <= 0;
        end
        if (counter < 2)
            counter <= counter + 1;
        if (counter == 2) begin
            if (block_counter < 2)
                block_counter <= block_counter + 1;
            else
                block_counter <= 0;
        end
        if (counter == 1)
            start <= !start;
        if (counter > 2)
            expected <= expected + 1;
    end
    always @(posedge clk) begin
        if (start) begin
            if (block_counter == 2) begin
                if (counter == 2)
                    $finish();
                else
                    counter <= counter + 1;
            end
            else
                block_counter <= block_counter + 1;
        end
    end
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end
endmodulemodule tb_sha256();
    reg clk;
    reg [31:0] in;
    reg [31:0] expected;
    reg [31:0] counter;
    reg [31:0] block_counter;
    reg start;
    reg [31:0] cycles;
    initial begin
        cycles = 32'd10;
        clk = 0;
        in = 0;
        counter = 0;
        block_counter = 0;
        expected = 0;
    end
    always #(cycles/2) clk = ~clk;
    always @(posedge clk) begin
        if (counter == 2) begin
            in <= `rev64(start,1*64);
            counter <= 0;
        end
        if (counter < 2)
            counter <= counter + 1;
        if (counter == 2) begin
            if (block_counter < 2)
                block_counter <= block_counter + 1;
            else
                block_counter <= 0;
        end
        if (counter == 1)
            start <= !start;
        if (counter > 2)
            expected <= expected + 1;
    end
    always @(posedge clk) begin
        if (start) begin
            if (block_counter == 2) begin
                if (counter == 2)
                    $finish();
                else
                    counter <= counter + 1;
            end
            else
                block_counter <= block_counter + 1;
        end
    end
    initial begin
        $dumpfile("dump
endmodule
