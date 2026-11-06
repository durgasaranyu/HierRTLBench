`timescale 1ns/1ps

module tb_cache_arrays;

    // Parameters matching the DUT's macros
    // TAG_WIDTH=24, DATA_WIDTH=32, T_ENTRIES=16, D_ENTRIES=16
    // We define them here for the testbench

    // DUT ports
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

    // Internal arrays to mirror DUT state for checking
    reg [23:0] exp_tag  [0:15];
    reg [31:0] exp_data [0:15];
    reg        exp_valid[0:15];

    integer i;
    integer pass_count;
    integer fail_count;

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

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

    // Task: apply synchronous reset for 5 rising edges
    task apply_reset;
        integer k;
        begin
            rst    = 1;
            we_tag = 0;
            we_data= 0;
            index  = 0;
            tag_in = 0;
            data_in= 0;
            // Wait 5 rising edges
            @(posedge clk);
            @(posedge clk);
            @(posedge clk);
            @(posedge clk);
            @(posedge clk);
            rst = 0;
            @(negedge clk); // settle
        end
    endtask

    // Task: write tag at given index
    task write_tag;
        input [3:0]  idx;
        input [23:0] tag;
        begin
            @(negedge clk);
            index  = idx;
            tag_in = tag;
            we_tag = 1;
            we_data= 0;
            @(posedge clk); // rising edge latches
            #1;
            we_tag = 0;
        end
    endtask

    // Task: write data at given index
    task write_data;
        input [3:0]  idx;
        input [31:0] dat;
        begin
            @(negedge clk);
            index   = idx;
            data_in = dat;
            we_tag  = 0;
            we_data = 1;
            @(posedge clk);
            #1;
            we_data = 0;
        end
    endtask

    // Task: write both tag and data at given index
    task write_entry;
        input [3:0]  idx;
        input [23:0] tag;
        input [31:0] dat;
        begin
            @(negedge clk);
            index   = idx;
            tag_in  = tag;
            data_in = dat;
            we_tag  = 1;
            we_data = 1;
            @(posedge clk);
            #1;
            we_tag  = 0;
            we_data = 0;
        end
    endtask

    // Task: read at given index (combinational read, just set index)
    task read_index;
        input [3:0] idx;
        begin
            @(negedge clk);
            index   = idx;
            we_tag  = 0;
            we_data = 0;
            #1; // let combinational settle
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        // Initialize inputs
        rst     = 0;
        we_tag  = 0;
        we_data = 0;
        index   = 0;
        tag_in  = 0;
        data_in = 0;

        // Initialize expected arrays
        for (i = 0; i < 16; i = i + 1) begin
            exp_tag[i]   = 0;
            exp_data[i]  = 0;
            exp_valid[i] = 0;
        end

        //----------------------------------------------------------
        // TEST 1: Reset clears valid bits
        //----------------------------------------------------------
        apply_reset;
        // After reset, all valid bits should be 0
        // Check index 0
        read_index(4'd0);
        #2;
        if (valid_out === 1'b0) begin
            $display("PASS: Reset clears valid bit at index 0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Reset should clear valid bit at index 0, got valid_out=%b", valid_out);
            fail_count = fail_count + 1;
        end

        // Check index 15
        read_index(4'd15);
        #2;
        if (valid_out === 1'b0) begin
            $display("PASS: Reset clears valid bit at index 15");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Reset should clear valid bit at index 15, got valid_out=%b", valid_out);
            fail_count = fail_count + 1;
        end

        //----------------------------------------------------------
        // TEST 2: Write tag and data to index 3, then read back
        //----------------------------------------------------------
        write_entry(4'd3, 24'hABCDEF, 32'h12345678);
        read_index(4'd3);
        #2;
        if (tag_out === 24'hABCDEF && data_out === 32'h12345678 && valid_out === 1'b1) begin
            $display("PASS: Write/Read entry at index 3: tag=0xABCDEF, data=0x12345678, valid=1");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Write/Read entry at index 3: tag_out=%h data_out=%h valid_out=%b",
                     tag_out, data_out, valid_out);
            fail_count = fail_count + 1;
        end

        //----------------------------------------------------------
        // TEST 3: After writing, valid bit is 1
        //----------------------------------------------------------
        // Already checked above; write another entry to confirm
        write_entry(4'd7, 24'h111111, 32'hDEADBEEF);
        read_index(4'd7);
        #2;
        if (valid_out === 1'b1) begin
            $display("PASS: Valid bit set to 1 after write at index 7");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Valid bit not set after write at index 7, valid_out=%b", valid_out);
            fail_count = fail_count + 1;
        end

        //----------------------------------------------------------
        // TEST 4: All-zero inputs: write zeros to index 0
        //----------------------------------------------------------
        write_entry(4'd0, 24'h000000, 32'h00000000);
        read_index(4'd0);
        #2;
        if (tag_out === 24'h000000 && data_out === 32'h00000000 && valid_out === 1'b1) begin
            $display("PASS: All-zero tag/data write at index 0, valid=1");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: All-zero write at index 0: tag_out=%h data_out=%h valid_out=%b",
                     tag_out, data_out, valid_out);
            fail_count = fail_count + 1;
        end

        //----------------------------------------------------------
        // TEST 5: All-ones inputs: write to index 15
        //----------------------------------------------------------
        write_entry(4'd15, 24'hFFFFFF, 32'hFFFFFFFF);
        read_index(4'd15);
        #2;
        if (tag_out === 24'hFFFFFF && data_out === 32'hFFFFFFFF && valid_out === 1'b1) begin
            $display("PASS: All-ones tag/data write at index 15");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: All-ones write at index 15: tag_out=%h data_out=%h valid_out=%b",
                     tag_out, data_out, valid_out);
            fail_count = fail_count + 1;
        end

        //----------------------------------------------------------
        // TEST 6: Write only tag (we_tag=1, we_data=0) at index 5
        //----------------------------------------------------------
        // First write a data value to index 5
        write_entry(4'd5, 24'h000000, 32'hCAFEBABE);
        // Now update only the tag
        write_tag(4'd5, 24'h555555);
        read_index(4'd5);
        #2;
        if (tag_out === 24'h555555 && data_out === 32'hCAFEBABE) begin
            $display("PASS: Write-tag-only at index 5: tag updated, data preserved");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Write-tag-only at index 5: tag_out=%h data_out=%h", tag_out, data_out);
            fail_count = fail_count + 1;
        end

        //----------------------------------------------------------
        // TEST 7: Write only data (we_tag=0, we_data=1) at index 5
        //----------------------------------------------------------
        write_data(4'd5, 32'hBEEFCAFE);
        read_index(4'd5);
        #2;
        if (tag_out === 24'h555555 && data_out === 32'hBEEFCAFE) begin
            $display("PASS: Write-data-only at index 5: data updated, tag preserved");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Write-data-only at index 5: tag_out=%h data_out=%h", tag_out, data_out);
            fail_count = fail_count + 1;
        end

        //----------------------------------------------------------
        // TEST 8: Second reset clears valid bits (including newly written entries)
        //----------------------------------------------------------
        apply_reset;
        // Check that valid bits are cleared
        read_index(4'd3);
        #2;
        if (valid_out === 1'b0) begin
            $display("PASS: Second reset clears valid bit at index 3");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Second reset did not clear valid bit at index 3, got %b", valid_out);
            fail_count = fail_count + 1;
        end

        //----------------------------------------------------------
        // TEST 9: Read unwritten index after reset (no we) — valid must be 0
        //----------------------------------------------------------
        read_index(4'd8);
        #2;
        if (valid_out === 1'b0) begin
            $display("PASS: Unwritten index 8 after reset has valid=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Unwritten index 8 after reset has valid=%b (expected 0)", valid_out);
            fail_count = fail_count + 1;
        end

        //----------------------------------------------------------
        // TEST 10: Maximum-value index (4'd15) write/read
        //----------------------------------------------------------
        write_entry(4'd15, 24'hA5A5A5, 32'h5A5A5A5A);
        read_index(4'd15);
        #2;
        if (tag_out === 24'hA5A5A5 && data_out === 32'h5A5A5A5A && valid_out === 1'b1) begin
            $display("PASS: Max index (15) write/read: tag=0xA5A5A5 data=0x5A5A5A5A valid=1");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Max index (15): tag_out=%h data_out=%h valid_out=%b",
                     tag_out, data_out, valid_out);
            fail_count = fail_count + 1;
        end

        //----------------------------------------------------------
        // TEST 11: Verify index independence — write different entries
        //----------------------------------------------------------
        write_entry(4'd1,  24'h111111, 32'h11111111);
        write_entry(4'd2,  24'h222222, 32'h22222222);
        write_entry(4'd14, 24'hEEEEEE, 32'hEEEEEEEE);

        read_index(4'd1);
        #2;
        if (tag_out === 24'h111111 && data_out === 32'h11111111 && valid_out === 1'b1) begin
            $display("PASS: Index independence check for index 1");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Index independence check for index 1: tag=%h data=%h valid=%b",
                     tag_out, data_out, valid_out);
            fail_count = fail_count + 1;
        end

        read_index(4'd2);
        #2;
        if (tag_out === 24'h222222 && data_out === 32'h22222222 && valid_out === 1'b1) begin
            $display("PASS: Index independence check for index 2");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Index independence check for index 2: tag=%h data=%h valid=%b",
                     tag_out, data_out, valid_out);
            fail_count = fail_count + 1;
        end

        read_index(4'd14);
        #2;
        if (tag_out === 24'hEEEEEE && data_out === 32'hEEEEEEEE && valid_out === 1'b1) begin
            $display("PASS: Index independence check for index 14");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Index independence check for index 14: tag=%h data=%h valid=%b",
                     tag_out, data_out, valid_out);
            fail_count = fail_count + 1;
        end

        //----------------------------------------------------------
        // TEST 12: Overwrite existing entry
        //----------------------------------------------------------
        write_entry(4'd1, 24'hAAAAAA, 32'hAAAAAAAA);
        read_index(4'd1);
        #2;
        if (tag_out === 24'hAAAAAA && data_out === 32'hAAAAAAAA && valid_out === 1'b1) begin
            $display("PASS: Overwrite index 1: new tag=0xAAAAAA data=0xAAAAAAAA");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Overwrite index 1: tag_out=%h data_out=%h valid_out=%b",
                     tag_out, data_out, valid_out);
            fail_count = fail_count + 1;
        end

        //----------------------------------------------------------
        // Summary
