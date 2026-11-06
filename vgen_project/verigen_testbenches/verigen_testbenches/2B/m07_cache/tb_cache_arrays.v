`timescale 1ns/1ps

module tb_cache_arrays;

    // ---------------------------------------------------------------
    // DUT port connections
    // ---------------------------------------------------------------
    reg         clk;
    reg         rst;
    reg  [3:0]  index;
    reg  [23:0] tag_in;
    reg  [31:0] data_in;
    reg         we_tag;
    reg         we_data;
    wire [23:0] tag_out;
    wire [31:0] data_out;
    wire        valid_out;

    // ---------------------------------------------------------------
    // Instantiate DUT
    // ---------------------------------------------------------------
    cache_arrays uut (
        .clk      (clk),
        .rst      (rst),
        .index    (index),
        .tag_in   (tag_in),
        .data_in  (data_in),
        .we_tag   (we_tag),
        .we_data  (we_data),
        .tag_out  (tag_out),
        .data_out (data_out),
        .valid_out(valid_out)
    );

    // ---------------------------------------------------------------
    // Clock generation
    // ---------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // ---------------------------------------------------------------
    // Task: apply a single clock rising-edge tick
    // ---------------------------------------------------------------
    task tick;
        begin
            @(posedge clk);
            #1; // small delay to let outputs settle
        end
    endtask

    // ---------------------------------------------------------------
    // Test stimulus
    // ---------------------------------------------------------------
    integer fail_count;

    initial begin
        fail_count = 0;

        // Initialise inputs
        rst    = 1;
        index  = 4'h0;
        tag_in = 24'h000000;
        data_in= 32'h00000000;
        we_tag = 0;
        we_data= 0;

        // -------------------------------------------------------
        // Requirement 5: hold reset for exactly 5 rising edges
        // -------------------------------------------------------
        repeat (5) @(posedge clk);
        #1;

        // -------------------------------------------------------
        // TEST 1: valid_out must be 0 after reset (all valid bits cleared)
        // -------------------------------------------------------
        rst = 0;
        index   = 4'h0;
        tag_in  = 24'hAAAAAA;
        data_in = 32'hDEADBEEF;
        we_tag  = 0;
        we_data = 0;

        // Read index 0 without writing — valid should still be 0 after rst
        // The module only drives valid_out for the selected index;
        // after reset all valid bits are 0.
        #1;
        if (valid_out === 1'b0)
            $display("PASS: valid_out=0 immediately after reset (index 0)");
        else begin
            $display("FAIL: valid_out should be 0 after reset, got %b", valid_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 2: Write tag+data to index 3
        // -------------------------------------------------------
        index   = 4'h3;
        tag_in  = 24'hCAFE01;
        data_in = 32'h12345678;
        we_tag  = 1;
        we_data = 1;
        tick;
        we_tag  = 0;
        we_data = 0;

        // Read back index 3
        index = 4'h3;
        #1;
        if ((tag_out === 24'hCAFE01) && (data_out === 32'h12345678) && (valid_out === 1'b1))
            $display("PASS: Write and read-back index 3 (tag+data+valid)");
        else begin
            $display("FAIL: Write/read-back index 3: tag=%h data=%h valid=%b",
                     tag_out, data_out, valid_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 3: Read hit simulation — same tag already stored → valid=1
        // -------------------------------------------------------
        // (index 3 now has valid=1, tag=0xCAFE01, data=0x12345678)
        index = 4'h3;
        #1;
        if (valid_out === 1'b1 && tag_out === 24'hCAFE01)
            $display("PASS: Read-hit: valid=1 and correct tag for index 3");
        else begin
            $display("FAIL: Read-hit check failed: valid=%b tag=%h", valid_out, tag_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 4: Read miss simulation — uncached index (e.g. index 7)
        //         should have valid=0 after reset (never written)
        // -------------------------------------------------------
        index = 4'h7;
        #1;
        if (valid_out === 1'b0)
            $display("PASS: Read-miss: valid=0 for unwritten index 7");
        else begin
            $display("FAIL: Read-miss: expected valid=0 for index 7, got %b", valid_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 5: All-zero inputs write to index 0
        // -------------------------------------------------------
        index   = 4'h0;
        tag_in  = 24'h000000;
        data_in = 32'h00000000;
        we_tag  = 1;
        we_data = 1;
        tick;
        we_tag  = 0;
        we_data = 0;

        index = 4'h0;
        #1;
        if ((tag_out === 24'h000000) && (data_out === 32'h00000000) && (valid_out === 1'b1))
            $display("PASS: All-zero write/read index 0");
        else begin
            $display("FAIL: All-zero write/read index 0: tag=%h data=%h valid=%b",
                     tag_out, data_out, valid_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 6: All-ones inputs write to index 15 (max index)
        // -------------------------------------------------------
        index   = 4'hF;
        tag_in  = 24'hFFFFFF;
        data_in = 32'hFFFFFFFF;
        we_tag  = 1;
        we_data = 1;
        tick;
        we_tag  = 0;
        we_data = 0;

        index = 4'hF;
        #1;
        if ((tag_out === 24'hFFFFFF) && (data_out === 32'hFFFFFFFF) && (valid_out === 1'b1))
            $display("PASS: All-ones write/read index 15");
        else begin
            $display("FAIL: All-ones write/read index 15: tag=%h data=%h valid=%b",
                     tag_out, data_out, valid_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 7: Write-through check — write to index 5 with we_tag only
        //         (we_data=0): data should not be updated but tag/valid should
        // -------------------------------------------------------
        // First, write data to index 5 so we know its initial value
        index   = 4'h5;
        tag_in  = 24'h111111;
        data_in = 32'hAABBCCDD;
        we_tag  = 1;
        we_data = 1;
        tick;
        we_tag  = 0;
        we_data = 0;

        // Now write a new tag but NOT new data
        index   = 4'h5;
        tag_in  = 24'h222222;
        data_in = 32'h99887766; // different data — should NOT be written
        we_tag  = 1;
        we_data = 0;
        tick;
        we_tag  = 0;
        we_data = 0;

        index = 4'h5;
        #1;
        // Tag should be updated; data should remain from first write
        if ((tag_out === 24'h222222) && (data_out === 32'hAABBCCDD) && (valid_out === 1'b1))
            $display("PASS: we_tag without we_data: tag updated, data unchanged");
        else begin
            $display("FAIL: we_tag without we_data: tag=%h (exp 222222) data=%h (exp AABBCCDD) valid=%b",
                     tag_out, data_out, valid_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 8: Synchronous reset clears valid bits
        //         (index 5 has valid=1 right now)
        // -------------------------------------------------------
        rst = 1;
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        index = 4'h5;
        #1;
        if (valid_out === 1'b0)
            $display("PASS: valid_out=0 for index 5 after second reset");
        else begin
            $display("FAIL: valid_out should be 0 after reset, got %b (index 5)", valid_out);
            fail_count = fail_count + 1;
        end

        // Also verify index 15 is cleared
        index = 4'hF;
        #1;
        if (valid_out === 1'b0)
            $display("PASS: valid_out=0 for index 15 after second reset");
        else begin
            $display("FAIL: valid_out should be 0 after reset, got %b (index 15)", valid_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 9: Write only data (we_tag=0, we_data=1)
        //         Tag should remain X/0, data updated, valid may update
        // -------------------------------------------------------
        index   = 4'h8;
        tag_in  = 24'h000000;
        data_in = 32'h55AA55AA;
        we_tag  = 0;
        we_data = 1;
        tick;
        we_tag  = 0;
        we_data = 0;

        index = 4'h8;
        #1;
        if (data_out === 32'h55AA55AA)
            $display("PASS: we_data only: data written correctly to index 8");
        else begin
            $display("FAIL: we_data only: data=%h (expected 55AA55AA) for index 8", data_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 10: Overwrite same index with new data/tag
        // -------------------------------------------------------
        index   = 4'h3;
        tag_in  = 24'hBEEF12;
        data_in = 32'hDEADC0DE;
        we_tag  = 1;
        we_data = 1;
        tick;
        we_tag  = 0;
        we_data = 0;

        index = 4'h3;
        #1;
        if ((tag_out === 24'hBEEF12) && (data_out === 32'hDEADC0DE) && (valid_out === 1'b1))
            $display("PASS: Overwrite index 3 with new tag and data");
        else begin
            $display("FAIL: Overwrite index 3: tag=%h data=%h valid=%b",
                     tag_out, data_out, valid_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Summary
        // -------------------------------------------------------
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", fail_count);

        $finish;
    end

endmodule
