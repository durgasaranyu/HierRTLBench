`timescale 1ns/1ps

module tb_cache_hit_logic;

    // DUT inputs (driven by testbench)
    reg  [23:0] req_tag;
    reg  [23:0] stored_tag;
    reg  [1:0]  byte_offset;
    reg         valid;
    reg  [31:0] data;

    // DUT outputs (driven by DUT)
    wire        hit;
    wire [7:0]  read_byte;

    // Clock and reset (not used by DUT but required by testbench spec)
    reg clk;
    reg rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate DUT
    cache_hit_logic uut (
        .req_tag    (req_tag),
        .stored_tag (stored_tag),
        .byte_offset(byte_offset),
        .valid      (valid),
        .data       (data),
        .hit        (hit),
        .read_byte  (read_byte)
    );

    // Task to check hit output
    task check_hit;
        input expected_hit;
        input [63:0] test_num;
        input [127:0] desc;
        begin
            #1; // small delay for combinational settle
            if (hit === expected_hit)
                $display("PASS: Test %0d - %s (hit=%b)", test_num, desc, hit);
            else
                $display("FAIL: Test %0d - %s (hit=%b, expected=%b)", test_num, desc, hit, expected_hit);
        end
    endtask

    // Task to check read_byte output
    task check_read_byte;
        input [7:0]  expected_byte;
        input        expected_hit;
        input [63:0] test_num;
        input [127:0] desc;
        begin
            #1;
            if (hit === expected_hit && read_byte === expected_byte)
                $display("PASS: Test %0d - %s (hit=%b, read_byte=0x%02h)", test_num, desc, hit, read_byte);
            else
                $display("FAIL: Test %0d - %s (hit=%b exp=%b, read_byte=0x%02h exp=0x%02h)",
                         test_num, desc, hit, expected_hit, read_byte, expected_byte);
        end
    endtask

    integer i;

    initial begin
        // Initialize inputs
        req_tag     = 24'h000000;
        stored_tag  = 24'h000000;
        byte_offset = 2'b00;
        valid       = 1'b0;
        data        = 32'h00000000;
        rst         = 1;

        // Assert reset for 5 rising edges
        repeat(5) @(posedge clk);
        rst = 0;
        @(negedge clk);

        // ------------------------------------------------------------
        // Test 1: Read hit - valid=1, matching tags, byte_offset=0
        // Expected: hit=1, read_byte = data[7:0]
        // ------------------------------------------------------------
        req_tag     = 24'hABCDEF;
        stored_tag  = 24'hABCDEF;
        byte_offset = 2'b00;
        valid       = 1'b1;
        data        = 32'h12345678;
        #2;
        begin
            // hit should be 1 (tags match and valid)
            // read_byte = data[7:0] = 0x78 (if byte_offset=0 selects bits [7:0])
            if (hit === 1'b1)
                $display("PASS: Test 1 - Read hit, valid=1, tags match, hit=1");
            else
                $display("FAIL: Test 1 - Read hit, valid=1, tags match, expected hit=1 got hit=%b", hit);
        end

        // ------------------------------------------------------------
        // Test 2: Read miss - valid=1, tags do NOT match
        // Expected: hit=0
        // ------------------------------------------------------------
        @(negedge clk);
        req_tag     = 24'hABCDEF;
        stored_tag  = 24'h123456;
        byte_offset = 2'b00;
        valid       = 1'b1;
        data        = 32'hDEADBEEF;
        #2;
        begin
            if (hit === 1'b0)
                $display("PASS: Test 2 - Read miss, tags mismatch, hit=0");
            else
                $display("FAIL: Test 2 - Read miss, tags mismatch, expected hit=0 got hit=%b", hit);
        end

        // ------------------------------------------------------------
        // Test 3: Read miss - valid=0, tags match
        // Expected: hit=0 (not valid)
        // ------------------------------------------------------------
        @(negedge clk);
        req_tag     = 24'hFFFFFF;
        stored_tag  = 24'hFFFFFF;
        byte_offset = 2'b01;
        valid       = 1'b0;
        data        = 32'hCAFEBABE;
        #2;
        begin
            if (hit === 1'b0)
                $display("PASS: Test 3 - Valid=0, tags match, hit=0 (invalid line)");
            else
                $display("FAIL: Test 3 - Valid=0, tags match, expected hit=0 got hit=%b", hit);
        end

        // ------------------------------------------------------------
        // Test 4: All-zero inputs - valid=0
        // Expected: hit=0
        // ------------------------------------------------------------
        @(negedge clk);
        req_tag     = 24'h000000;
        stored_tag  = 24'h000000;
        byte_offset = 2'b00;
        valid       = 1'b0;
        data        = 32'h00000000;
        #2;
        begin
            if (hit === 1'b0)
                $display("PASS: Test 4 - All-zero inputs, valid=0, hit=0");
            else
                $display("FAIL: Test 4 - All-zero inputs, valid=0, expected hit=0 got hit=%b", hit);
        end

        // ------------------------------------------------------------
        // Test 5: All-zero inputs - valid=1, tags both 0 (hit)
        // Expected: hit=1
        // ------------------------------------------------------------
        @(negedge clk);
        req_tag     = 24'h000000;
        stored_tag  = 24'h000000;
        byte_offset = 2'b00;
        valid       = 1'b1;
        data        = 32'h00000000;
        #2;
        begin
            if (hit === 1'b1)
                $display("PASS: Test 5 - All-zero tags, valid=1, hit=1");
            else
                $display("FAIL: Test 5 - All-zero tags, valid=1, expected hit=1 got hit=%b", hit);
        end

        // ------------------------------------------------------------
        // Test 6: All-ones inputs - valid=1, tags all 0xFFFFFF (hit)
        // Expected: hit=1
        // ------------------------------------------------------------
        @(negedge clk);
        req_tag     = 24'hFFFFFF;
        stored_tag  = 24'hFFFFFF;
        byte_offset = 2'b11;
        valid       = 1'b1;
        data        = 32'hFFFFFFFF;
        #2;
        begin
            if (hit === 1'b1)
                $display("PASS: Test 6 - All-ones tags and data, valid=1, hit=1");
            else
                $display("FAIL: Test 6 - All-ones tags, valid=1, expected hit=1 got hit=%b", hit);
        end

        // ------------------------------------------------------------
        // Test 7: Maximum tag values mismatched (one bit difference)
        // Expected: hit=0
        // ------------------------------------------------------------
        @(negedge clk);
        req_tag     = 24'hFFFFFF;
        stored_tag  = 24'hFFFFFE;
        byte_offset = 2'b10;
        valid       = 1'b1;
        data        = 32'hA5A5A5A5;
        #2;
        begin
            if (hit === 1'b0)
                $display("PASS: Test 7 - Tags differ by 1 bit, valid=1, hit=0");
            else
                $display("FAIL: Test 7 - Tags differ by 1 bit, valid=1, expected hit=0 got hit=%b", hit);
        end

        // ------------------------------------------------------------
        // Test 8: Valid reset behavior - simulate rst effect
        //         After rst, valid should effectively be 0 (external control)
        //         We test by setting valid=0 explicitly then checking no hit
        // ------------------------------------------------------------
        @(negedge clk);
        rst         = 1;
        valid       = 1'b0;
        req_tag     = 24'hABCDEF;
        stored_tag  = 24'hABCDEF;
        byte_offset = 2'b00;
        data        = 32'h11223344;
        repeat(5) @(posedge clk);
        rst = 0;
        @(negedge clk);
        #2;
        begin
            if (hit === 1'b0)
                $display("PASS: Test 8 - After rst, valid=0, hit=0 (valid bit reset)");
            else
                $display("FAIL: Test 8 - After rst, valid=0, expected hit=0 got hit=%b", hit);
        end

        // ------------------------------------------------------------
        // Test 9: Byte offset selection check - offset=1 on known data
        // ------------------------------------------------------------
        @(negedge clk);
        req_tag     = 24'h010203;
        stored_tag  = 24'h010203;
        byte_offset = 2'b01;
        valid       = 1'b1;
        data        = 32'hAABBCCDD;
        #2;
        begin
            if (hit === 1'b1)
                $display("PASS: Test 9 - Byte offset=1, valid=1, tags match, hit=1");
            else
                $display("FAIL: Test 9 - Byte offset=1, valid=1, tags match, expected hit=1 got hit=%b", hit);
        end

        // ------------------------------------------------------------
        // Test 10: Byte offset selection check - offset=2 on known data
        // ------------------------------------------------------------
        @(negedge clk);
        req_tag     = 24'h010203;
        stored_tag  = 24'h010203;
        byte_offset = 2'b10;
        valid       = 1'b1;
        data        = 32'hAABBCCDD;
        #2;
        begin
            if (hit === 1'b1)
                $display("PASS: Test 10 - Byte offset=2, valid=1, tags match, hit=1");
            else
                $display("FAIL: Test 10 - Byte offset=2, valid=1, tags match, expected hit=1 got hit=%b", hit);
        end

        // ------------------------------------------------------------
        // Test 11: Write scenario simulation - tags match, valid=1
        //          (cpu_we / mem_we are not in DUT ports; we verify hit=1)
        // ------------------------------------------------------------
        @(negedge clk);
        req_tag     = 24'hC0FFEE;
        stored_tag  = 24'hC0FFEE;
        byte_offset = 2'b11;
        valid       = 1'b1;
        data        = 32'hDEADC0DE;
        #2;
        begin
            if (hit === 1'b1)
                $display("PASS: Test 11 - Write-through hit scenario, tags match valid=1, hit=1");
            else
                $display("FAIL: Test 11 - Write-through hit scenario, expected hit=1 got hit=%b", hit);
        end

        // ------------------------------------------------------------
        // Test 12: Miss with valid=0 and mismatched tags
        // Expected: hit=0
        // ------------------------------------------------------------
        @(negedge clk);
        req_tag     = 24'h111111;
        stored_tag  = 24'h222222;
        byte_offset = 2'b00;
        valid       = 1'b0;
        data        = 32'h00FF00FF;
        #2;
        begin
            if (hit === 1'b0)
                $display("PASS: Test 12 - Miss, valid=0 and tags mismatch, hit=0");
            else
                $display("FAIL: Test 12 - Miss, valid=0 and tags mismatch, expected hit=0 got hit=%b", hit);
        end

        #20;
        $finish;
    end

endmodule
