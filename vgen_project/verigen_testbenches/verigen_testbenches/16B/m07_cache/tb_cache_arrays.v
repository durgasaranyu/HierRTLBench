`timescale 1ns/1ps

module tb_cache_arrays;

    // DUT connections
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

    // Helper task: apply one clock
    task tick;
        begin
            @(posedge clk);
            #1; // small delay to let outputs settle
        end
    endtask

    integer i;
    integer pass_count;
    integer fail_count;

    initial begin
        pass_count = 0;
        fail_count = 0;

        // Initialize inputs
        rst    = 1;
        index  = 4'd0;
        tag_in = 24'd0;
        data_in= 32'd0;
        we_tag = 0;
        we_data= 0;

        // Assert synchronous reset for exactly 5 rising edges
        repeat (5) @(posedge clk);
        #1;

        // De-assert reset
        rst = 0;

        // ==================================================================
        // Test 1: After reset, valid_out should be 0
        // (index_tag_sel was cleared to 0, valid_out_reg = 0 after rst)
        // ==================================================================
        // Let one cycle pass with no write to confirm valid = 0
        we_tag  = 0;
        we_data = 0;
        data_in = 32'hDEADBEEF;
        tick;
        // After this clock: we_tag=0, so valid_out_reg <= 0
        if (valid_out === 1'b0) begin
            $display("PASS: Test1 - valid_out=0 after reset with no write");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test1 - valid_out should be 0 after reset, got %b", valid_out);
            fail_count = fail_count + 1;
        end

        // ==================================================================
        // Test 2: Write with we_tag=1, index_tag_sel=0 (after reset, starts
        // at 0). data_in goes to data_out_reg, valid_out_reg=1
        // ==================================================================
        rst    = 1;
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        // Now index_tag_sel = 0 (after reset)
        we_tag  = 1;
        we_data = 0;
        data_in = 32'hAABBCCDD;
        tick;
        // After posedge: index_tag_sel was 0 -> data_out_reg <= data_in, valid=1
        // index_tag_sel becomes 1
        if (valid_out === 1'b1 && data_out === 32'hAABBCCDD) begin
            $display("PASS: Test2 - we_tag write at sel=0: data_out=0x%08X valid=1", data_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test2 - expected data_out=0xAABBCCDD valid=1, got data_out=0x%08X valid=%b",
                     data_out, valid_out);
            fail_count = fail_count + 1;
        end

        // ==================================================================
        // Test 3: No write cycle (we_tag=0, we_data=0) -> valid_out goes 0
        // ==================================================================
        we_tag  = 0;
        we_data = 0;
        data_in = 32'h12345678;
        tick;
        // valid_out_reg <= 0 because we_tag=0
        if (valid_out === 1'b0) begin
            $display("PASS: Test3 - valid_out=0 when no write");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test3 - expected valid_out=0 when no write, got %b", valid_out);
            fail_count = fail_count + 1;
        end

        // ==================================================================
        // Test 4: we_data=1, index_tag_sel=2 (currently 2 after previous ticks)
        // At sel=2: data_out_reg[7:0] <= data_in[15:8], data_out_reg[15:8] <= data_in[7:0]
        // We drive data_in=32'hAABBCCDD
        // ==================================================================
        // After reset we did: tick (sel 0->1), tick (sel 1->2), tick (sel 2->3)
        // Let's re-synchronize by resetting again
        rst = 1;
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        // sel=0 now
        // Advance to sel=2: do 2 idle ticks
        we_tag  = 0;
        we_data = 0;
        data_in = 32'h0;
        tick; // sel: 0->1
        tick; // sel: 1->2

        // Now sel=2, apply we_data
        we_data = 1;
        we_tag  = 0;
        data_in = 32'hAABBCCDD;
        tick; // sel=2 -> data_out_reg[7:0]<=data_in[15:8]=0xCC, [15:8]<=data_in[7:0]=0xDD
        // data_out_reg after: [7:0]=0xCC, [15:8]=0xDD, [23:16]=0x00, [31:24]=0x00
        // (upper bytes were 0 from reset)
        if (data_out[7:0] === 8'hCC && data_out[15:8] === 8'hDD) begin
            $display("PASS: Test4 - we_data at sel=2: data_out[15:0]=0x%04X", data_out[15:0]);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test4 - we_data at sel=2: expected [7:0]=0xCC [15:8]=0xDD, got 0x%08X",
                     data_out);
            fail_count = fail_count + 1;
        end

        // ==================================================================
        // Test 5: All-zero inputs with we_tag=1
        // Reset, sel=0, we_tag=1, data_in=0 -> data_out=0, valid=1
        // ==================================================================
        rst = 1;
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        we_tag  = 1;
        we_data = 0;
        data_in = 32'h00000000;
        tick;
        if (valid_out === 1'b1 && data_out === 32'h00000000) begin
            $display("PASS: Test5 - all-zero data_in with we_tag at sel=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test5 - expected data_out=0x00000000 valid=1, got data_out=0x%08X valid=%b",
                     data_out, valid_out);
            fail_count = fail_count + 1;
        end

        // ==================================================================
        // Test 6: All-ones inputs with we_tag=1 at sel=0
        // ==================================================================
        rst = 1;
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        we_tag  = 1;
        we_data = 0;
        data_in = 32'hFFFFFFFF;
        tick;
        if (valid_out === 1'b1 && data_out === 32'hFFFFFFFF) begin
            $display("PASS: Test6 - all-ones data_in with we_tag at sel=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test6 - expected data_out=0xFFFFFFFF valid=1, got data_out=0x%08X valid=%b",
                     data_out, valid_out);
            fail_count = fail_count + 1;
        end

        // ==================================================================
        // Test 7: we_data=1 at sel=1 (byte-swap)
        // sel=0->tick->sel=1, then we_data=1
        // At sel=1: [7:0]<=din[31:24], [15:8]<=din[23:16], [23:16]<=din[15:8], [31:24]<=din[7:0]
        // data_in=0x12345678 -> [7:0]=0x12, [15:8]=0x34, [23:16]=0x56, [31:24]=0x78
        // ==================================================================
        rst = 1;
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        // Advance sel to 1
        we_tag  = 0;
        we_data = 0;
        data_in = 32'h0;
        tick; // sel: 0->1

        we_data = 1;
        we_tag  = 0;
        data_in = 32'h12345678;
        tick; // sel=1, byte-swap
        if (data_out[7:0]  === 8'h12 &&
            data_out[15:8] === 8'h34 &&
            data_out[23:16]=== 8'h56 &&
            data_out[31:24]=== 8'h78) begin
            $display("PASS: Test7 - we_data at sel=1 byte-swap: data_out=0x%08X", data_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test7 - expected 0x12345678 (reversed), got 0x%08X", data_out);
            fail_count = fail_count + 1;
        end

        // ==================================================================
        // Test 8: Counter wraps at 10 back to 0
        // After reset sel=0. Do 10 idle ticks to advance sel 0..9 then wrap to 0
        // Then check we_tag=1 at sel=0 works again
        // ==================================================================
        rst = 1;
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        we_tag  = 0;
        we_data = 0;
        data_in = 32'h0;
        // Advance sel through 0..9 (10 ticks), wraps back to 0 on 10th tick end
        repeat (10) begin
            tick;
        end
        // sel should be 0 again now
        we_tag  = 1;
        we_data = 0;
        data_in = 32'hCAFEBABE;
        tick; // sel=0 -> data_out_reg <= 0xCAFEBABE, valid=1
        if (valid_out === 1'b1 && data_out === 32'hCAFEBABE) begin
            $display("PASS: Test8 - counter wrap, we_tag at sel=0 after wrap: data_out=0x%08X", data_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test8 - counter wrap test: expected 0xCAFEBABE valid=1, got 0x%08X valid=%b",
                     data_out, valid_out);
            fail_count = fail_count + 1;
        end

        // ==================================================================
        // Test 9: Synchronous reset clears valid_out
        // Write something, confirm valid=1, then assert rst, confirm valid=0
        // ==================================================================
        rst = 1;
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        we_tag  = 1;
        we_data = 0;
        data_in = 32'h5A5A5A5A;
        tick; // write at sel=0 -> valid=1, data_out=5A5A5A5A

        if (valid_out !== 1'b1) begin
            $display("FAIL: Test9 setup - expected valid=1 before reset, got %b", valid_out);
            fail_count = fail_count + 1;
        end

        // Now assert reset
        rst = 1;
        we_tag = 0;
        tick; // rst asserted -> valid_out_reg=0
        #1;
        if (valid_out === 1'b0) begin
            $display("PASS: Test9 - synchronous reset clears valid_out");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test9 - expected valid_out=0 after reset, got %b", valid_out);
            fail_count = fail_count + 1;
        end
        rst = 0;

        // ==================================================================
        // Test 10: we_tag at sel=1 writes data_in[31:0] to tag_out
        // ==================================================================
        rst = 1;
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        // Advance to sel=1
        we_tag  = 0;
        we_data = 0;
        tick; // sel: 0->1

        we_tag  = 1;
        we_data = 0;
        data_in = 32'hABCDEF01;
        tick; // sel=1: tag_out <= data_in[31:0] = 0xABCDEF01 (lower 24 bits: 0xCDEF01)
        // valid=1
        if (valid_out === 1'b1 && tag_out === data_in[23:0]) begin
            $display("PASS: Test10 - we_tag at sel=1: tag_out=0x%06X valid=1", tag_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test10 - we_tag at sel=1: expected tag_out=0x%06X valid=1, got tag_out=0x%06X valid=%b",
                     data_in[23:0], tag_out, valid_out);
            fail_count = fail_count + 1;
        end

        // ==================================================================
        // Summary
        // ==================================================================
        $display("-----------------------------------");
        $display("Total PASS: %0d  Total FAIL: %0d", pass_count, fail_count);
        $display("-----------------------------------");

        $finish;
    end

endmodule
