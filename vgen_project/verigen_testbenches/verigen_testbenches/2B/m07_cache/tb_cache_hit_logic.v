`timescale 1ns/1ps

module tb_cache_hit_logic;

    // DUT connections
    reg  [23:0] req_tag;
    reg  [23:0] stored_tag;
    reg  [1:0]  byte_offset;
    reg         valid;
    reg  [31:0] data;
    wire        hit;
    wire [7:0]  read_byte;

    // Clock and reset (kept for completeness per requirements, though DUT is combinational)
    reg clk;
    reg rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // Synchronous reset: assert for 5 rising edges then deassert
    integer i;
    initial begin
        rst = 1;
        for (i = 0; i < 5; i = i + 1)
            @(posedge clk);
        rst = 0;
    end

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

    // Tracking variables
    reg test_pass;

    initial begin
        // Initialize all inputs
        req_tag    = 24'h000000;
        stored_tag = 24'h000000;
        byte_offset= 2'b00;
        valid      = 1'b0;
        data       = 32'h00000000;

        // Wait for reset to deassert
        @(negedge rst);
        @(posedge clk); #1;

        //------------------------------------------------------------------
        // Test 1: Read hit - valid=1, tags match, byte_offset=0 (data[15:8])
        //------------------------------------------------------------------
        req_tag    = 24'hABCDEF;
        stored_tag = 24'hABCDEF;
        valid      = 1'b1;
        data       = 32'hDEADBEEF;
        byte_offset= 2'b00;
        #1;
        test_pass = (hit == 1'b1) && (read_byte == data[15:8]);
        if (test_pass)
            $display("PASS: Test1 - Read hit, tags match, offset=0, hit=1, read_byte=data[15:8]=0x%02h", read_byte);
        else
            $display("FAIL: Test1 - Read hit expected hit=1 read_byte=%02h, got hit=%b read_byte=%02h", data[15:8], hit, read_byte);

        //------------------------------------------------------------------
        // Test 2: Read hit - valid=1, tags match, byte_offset=1 (data[15:8])
        //------------------------------------------------------------------
        req_tag    = 24'hABCDEF;
        stored_tag = 24'hABCDEF;
        valid      = 1'b1;
        data       = 32'hDEADBEEF;
        byte_offset= 2'b01;
        #1;
        // byte_offset[1]=0 -> data[15:8]
        test_pass = (hit == 1'b1) && (read_byte == data[15:8]);
        if (test_pass)
            $display("PASS: Test2 - Read hit, offset=1 (byte_offset[1]=0), read_byte=data[15:8]=0x%02h", read_byte);
        else
            $display("FAIL: Test2 - hit=%b read_byte=%02h expected hit=1 read_byte=%02h", hit, read_byte, data[15:8]);

        //------------------------------------------------------------------
        // Test 3: Read hit - valid=1, tags match, byte_offset=2 (data[7:0])
        //------------------------------------------------------------------
        req_tag    = 24'hABCDEF;
        stored_tag = 24'hABCDEF;
        valid      = 1'b1;
        data       = 32'hDEADBEEF;
        byte_offset= 2'b10;
        #1;
        // byte_offset[1]=1 -> data[7:0]
        test_pass = (hit == 1'b1) && (read_byte == data[7:0]);
        if (test_pass)
            $display("PASS: Test3 - Read hit, offset=2 (byte_offset[1]=1), read_byte=data[7:0]=0x%02h", read_byte);
        else
            $display("FAIL: Test3 - hit=%b read_byte=%02h expected hit=1 read_byte=%02h", hit, read_byte, data[7:0]);

        //------------------------------------------------------------------
        // Test 4: Read miss - valid=1 but tags do not match
        //------------------------------------------------------------------
        req_tag    = 24'h123456;
        stored_tag = 24'hABCDEF;
        valid      = 1'b1;
        data       = 32'hDEADBEEF;
        byte_offset= 2'b00;
        #1;
        test_pass = (hit == 1'b0);
        if (test_pass)
            $display("PASS: Test4 - Read miss (tag mismatch), hit=0");
        else
            $display("FAIL: Test4 - Expected hit=0 on tag mismatch, got hit=%b", hit);

        //------------------------------------------------------------------
        // Test 5: Read miss - valid=0 even though tags match
        //------------------------------------------------------------------
        req_tag    = 24'hABCDEF;
        stored_tag = 24'hABCDEF;
        valid      = 1'b0;
        data       = 32'hDEADBEEF;
        byte_offset= 2'b00;
        #1;
        test_pass = (hit == 1'b0);
        if (test_pass)
            $display("PASS: Test5 - Read miss (valid=0 with matching tags), hit=0");
        else
            $display("FAIL: Test5 - Expected hit=0 when valid=0, got hit=%b", hit);

        //------------------------------------------------------------------
        // Test 6: All-zero inputs
        //------------------------------------------------------------------
        req_tag    = 24'h000000;
        stored_tag = 24'h000000;
        valid      = 1'b1;
        data       = 32'h00000000;
        byte_offset= 2'b00;
        #1;
        test_pass = (hit == 1'b1) && (read_byte == 8'h00);
        if (test_pass)
            $display("PASS: Test6 - All-zero inputs, hit=1, read_byte=0x00");
        else
            $display("FAIL: Test6 - All-zero: hit=%b read_byte=%02h", hit, read_byte);

        //------------------------------------------------------------------
        // Test 7: All-ones inputs
        //------------------------------------------------------------------
        req_tag    = 24'hFFFFFF;
        stored_tag = 24'hFFFFFF;
        valid      = 1'b1;
        data       = 32'hFFFFFFFF;
        byte_offset= 2'b11;
        #1;
        // byte_offset[1]=1 -> data[7:0] = 8'hFF
        test_pass = (hit == 1'b1) && (read_byte == 8'hFF);
        if (test_pass)
            $display("PASS: Test7 - All-ones inputs, hit=1, read_byte=0xFF");
        else
            $display("FAIL: Test7 - All-ones: hit=%b read_byte=%02h", hit, read_byte);

        //------------------------------------------------------------------
        // Test 8: Valid-bit effectively reset (valid=0) with all-ones tags
        //------------------------------------------------------------------
        req_tag    = 24'hFFFFFF;
        stored_tag = 24'hFFFFFF;
        valid      = 1'b0;
        data       = 32'hFFFFFFFF;
        byte_offset= 2'b11;
        #1;
        test_pass = (hit == 1'b0);
        if (test_pass)
            $display("PASS: Test8 - Valid=0 (simulates rst clearing valid bit), hit=0");
        else
            $display("FAIL: Test8 - Expected hit=0 when valid=0, got hit=%b", hit);

        //------------------------------------------------------------------
        // Test 9: Maximum tag value mismatch
        //------------------------------------------------------------------
        req_tag    = 24'hFFFFFF;
        stored_tag = 24'hFFFFFE;
        valid      = 1'b1;
        data       = 32'hCAFEBABE;
        byte_offset= 2'b10;
        #1;
        // tags differ by 1 bit, should miss
        test_pass = (hit == 1'b0);
        if (test_pass)
            $display("PASS: Test9 - Near-maximum tag mismatch, hit=0");
        else
            $display("FAIL: Test9 - Expected hit=0 for near-max tag mismatch, got hit=%b", hit);

        //------------------------------------------------------------------
        // Test 10: Write-through scenario - tags match valid=1, verify hit asserted
        //          (cpu_we concept: when hit, data available; no separate cpu_we pin in DUT)
        //------------------------------------------------------------------
        req_tag    = 24'h5A5A5A;
        stored_tag = 24'h5A5A5A;
        valid      = 1'b1;
        data       = 32'h12345678;
        byte_offset= 2'b10;
        #1;
        // byte_offset[1]=1 -> data[7:0] = 8'h78
        test_pass = (hit == 1'b1) && (read_byte == 8'h78);
        if (test_pass)
            $display("PASS: Test10 - Write-through read: hit=1, read_byte=0x78 (data[7:0])");
        else
            $display("FAIL: Test10 - hit=%b read_byte=%02h expected hit=1 read_byte=0x78", hit, read_byte);

        @(posedge clk);
        $finish;
    end

endmodule
