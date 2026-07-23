`timescale 1ns/1ps

// Testbench for cache_arrays
// Note: The module under test has undefined macros (TAG_WIDTH, DATA_WIDTH,
// T_ENTRIES, D_ENTRIES) and an incomplete module body. We define those here
// and test the declared interface: index, tag_in, data_in, we_tag, we_data,
// tag_out, data_out, valid_out.

`define TAG_WIDTH  24
`define DATA_WIDTH 32
`define T_ENTRIES  16
`define D_ENTRIES  16

module tb_cache_arrays;

    // Clock and reset
    reg clk;
    reg rst;

    // DUT inputs
    reg  [3:0]  index;
    reg  [23:0] tag_in;
    reg  [31:0] data_in;
    reg         we_tag;
    reg         we_data;

    // DUT outputs
    wire [23:0] tag_out;
    wire [31:0] data_out;
    wire        valid_out;

    // Instantiate DUT
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

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Task: apply one clock rising edge
    task tick;
        begin
            @(posedge clk);
            #1; // small delay after edge to sample outputs
        end
    endtask

    // Task: set all control signals to idle
    task idle_signals;
        begin
            we_tag  = 0;
            we_data = 0;
            tag_in  = 24'h0;
            data_in = 32'h0;
            index   = 4'h0;
        end
    endtask

    integer i;
    integer pass_count;
    integer fail_count;

    initial begin
        pass_count = 0;
        fail_count = 0;

        // Initialize signals
        rst    = 1;
        we_tag = 0;
        we_data= 0;
        tag_in = 0;
        data_in= 0;
        index  = 0;

        // -------------------------------------------------------
        // Assert reset for exactly 5 clock rising edges
        // -------------------------------------------------------
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        // -------------------------------------------------------
        // TEST 1: valid_out should be 0 after reset (all valid bits cleared)
        // -------------------------------------------------------
        index = 4'h0;
        #1;
        if (valid_out === 1'b0) begin
            $display("PASS: After reset, index 0 valid_out=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After reset, index 0 valid_out should be 0, got %b", valid_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 2: valid_out should be 0 for all entries after reset
        // -------------------------------------------------------
        begin : test2_block
            reg all_invalid;
            all_invalid = 1;
            for (i = 0; i < 16; i = i + 1) begin
                index = i[3:0];
                #1;
                if (valid_out !== 1'b0) all_invalid = 0;
            end
            if (all_invalid) begin
                $display("PASS: All 16 entries invalid after reset");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Some entries not invalid after reset");
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // TEST 3: Write tag and data to index 0, then read back
        // -------------------------------------------------------
        idle_signals;
        index   = 4'h0;
        tag_in  = 24'hABCDEF;
        data_in = 32'hDEADBEEF;
        we_tag  = 1;
        we_data = 1;
        tick;
        idle_signals;
        index = 4'h0;
        #1;
        if (tag_out === 24'hABCDEF && data_out === 32'hDEADBEEF) begin
            $display("PASS: Write/read index 0: tag=0xABCDEF, data=0xDEADBEEF");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Write/read index 0: tag=%h data=%h (expected ABCDEF / DEADBEEF)", tag_out, data_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 4: valid_out should be 1 after writing to index 0
        // -------------------------------------------------------
        index = 4'h0;
        #1;
        if (valid_out === 1'b1) begin
            $display("PASS: valid_out=1 after write to index 0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: valid_out=%b after write to index 0 (expected 1)", valid_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 5: Write to index 15 (boundary), verify data
        // -------------------------------------------------------
        idle_signals;
        index   = 4'hF;
        tag_in  = 24'hFFFFFF;
        data_in = 32'hFFFFFFFF;
        we_tag  = 1;
        we_data = 1;
        tick;
        idle_signals;
        index = 4'hF;
        #1;
        if (tag_out === 24'hFFFFFF && data_out === 32'hFFFFFFFF && valid_out === 1'b1) begin
            $display("PASS: Write/read index 15 (max): tag=FFFFFF, data=FFFFFFFF, valid=1");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Write/read index 15: tag=%h data=%h valid=%b", tag_out, data_out, valid_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 6: Write all-zeros to index 7
        // -------------------------------------------------------
        idle_signals;
        index   = 4'h7;
        tag_in  = 24'h000000;
        data_in = 32'h00000000;
        we_tag  = 1;
        we_data = 1;
        tick;
        idle_signals;
        index = 4'h7;
        #1;
        if (tag_out === 24'h0 && data_out === 32'h0 && valid_out === 1'b1) begin
            $display("PASS: Write/read index 7: all-zero tag/data, valid=1");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Write/read index 7: tag=%h data=%h valid=%b (expected 0/0/1)", tag_out, data_out, valid_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 7: Synchronous reset clears valid bits
        //         Write to several entries, then assert rst, verify valid=0
        // -------------------------------------------------------
        // Write a few entries
        idle_signals;
        index   = 4'h3;
        tag_in  = 24'h123456;
        data_in = 32'hCAFEBABE;
        we_tag  = 1;
        we_data = 1;
        tick;
        idle_signals;
        index   = 4'h5;
        tag_in  = 24'h654321;
        data_in = 32'hBEEFCAFE;
        we_tag  = 1;
        we_data = 1;
        tick;
        idle_signals;

        // Assert reset for 5 cycles
        rst = 1;
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        // Check that valid bits are cleared
        begin : test7_block
            reg all_invalid2;
            all_invalid2 = 1;
            for (i = 0; i < 16; i = i + 1) begin
                index = i[3:0];
                #1;
                if (valid_out !== 1'b0) all_invalid2 = 0;
            end
            if (all_invalid2) begin
                $display("PASS: All valid bits cleared after second reset");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Some valid bits not cleared after second reset");
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // TEST 8: Only we_tag asserts - write tag but not data
        // -------------------------------------------------------
        idle_signals;
        index   = 4'h2;
        tag_in  = 24'hA1B2C3;
        data_in = 32'hDEAD1234;
        we_tag  = 1;
        we_data = 0;
        tick;
        idle_signals;
        index = 4'h2;
        #1;
        if (tag_out === 24'hA1B2C3) begin
            $display("PASS: we_tag only: tag_out=0xA1B2C3 as expected");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: we_tag only: tag_out=%h (expected A1B2C3)", tag_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 9: Only we_data asserts - write data but not tag
        // -------------------------------------------------------
        idle_signals;
        index   = 4'h4;
        tag_in  = 24'hFFFFFF;  // should not be written
        data_in = 32'h12345678;
        we_tag  = 0;
        we_data = 1;
        tick;
        idle_signals;
        index = 4'h4;
        #1;
        if (data_out === 32'h12345678) begin
            $display("PASS: we_data only: data_out=0x12345678 as expected");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: we_data only: data_out=%h (expected 12345678)", data_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 10: Multiple writes to same index (override)
        // -------------------------------------------------------
        idle_signals;
        index   = 4'h8;
        tag_in  = 24'h111111;
        data_in = 32'h11111111;
        we_tag  = 1;
        we_data = 1;
        tick;

        idle_signals;
        index   = 4'h8;
        tag_in  = 24'h222222;
        data_in = 32'h22222222;
        we_tag  = 1;
        we_data = 1;
        tick;

        idle_signals;
        index = 4'h8;
        #1;
        if (tag_out === 24'h222222 && data_out === 32'h22222222 && valid_out === 1'b1) begin
            $display("PASS: Override write to index 8: tag=222222, data=22222222, valid=1");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Override write to index 8: tag=%h data=%h valid=%b", tag_out, data_out, valid_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Summary
        // -------------------------------------------------------
        $display("------------------------------------------");
        $display("Tests complete: %0d passed, %0d failed", pass_count, fail_count);
        $display("------------------------------------------");

        $finish;
    end

endmodule
