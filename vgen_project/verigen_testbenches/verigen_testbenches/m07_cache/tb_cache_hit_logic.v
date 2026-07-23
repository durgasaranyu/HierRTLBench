`timescale 1ns/1ps

module tb_cache_hit_logic;

    // DUT inputs
    reg  [23:0] req_tag;
    reg  [23:0] stored_tag;
    reg  [1:0]  byte_offset;
    reg         valid;
    reg  [31:0] data;

    // DUT outputs
    wire        hit;
    wire [7:0]  read_byte;

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

    // Clock
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (synchronous style - count 5 rising edges)
    reg rst;
    integer i;
    integer pass_count;
    integer fail_count;

    // Expected values
    reg        exp_hit;
    reg [7:0]  exp_byte;

    task check_hit;
        input        expected_hit;
        input [127:0] desc;
        begin
            if (hit === expected_hit) begin
                $display("PASS: %s - hit=%b", desc, hit);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: %s - expected hit=%b got hit=%b", desc, expected_hit, hit);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_read_byte;
        input [7:0]   expected_byte;
        input [127:0] desc;
        begin
            if (read_byte === expected_byte) begin
                $display("PASS: %s - read_byte=%h", desc, read_byte);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: %s - expected read_byte=%h got read_byte=%h", desc, expected_byte, read_byte);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_hit_and_byte;
        input        expected_hit;
        input [7:0]  expected_byte;
        input [127:0] desc;
        begin
            if (hit === expected_hit && read_byte === expected_byte) begin
                $display("PASS: %s - hit=%b read_byte=%h", desc, hit, read_byte);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: %s - expected hit=%b read_byte=%h, got hit=%b read_byte=%h",
                         desc, expected_hit, expected_byte, hit, read_byte);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        rst = 1;

        // Initialize inputs
        req_tag     = 24'h000000;
        stored_tag  = 24'h000000;
        byte_offset = 2'b00;
        valid       = 1'b0;
        data        = 32'h00000000;

        // Assert reset for 5 rising edges
        for (i = 0; i < 5; i = i + 1) begin
            @(posedge clk);
        end
        rst = 0;
        @(negedge clk);

        // ---------------------------------------------------------------
        // Test 1: Valid=0, tags match -> should be MISS (hit=0)
        // ---------------------------------------------------------------
        req_tag     = 24'hABCDEF;
        stored_tag  = 24'hABCDEF;
        valid       = 1'b0;
        byte_offset = 2'b00;
        data        = 32'hDEADBEEF;
        #1;
        check_hit(1'b0, "Miss when valid=0 even if tags match");

        // ---------------------------------------------------------------
        // Test 2: Valid=1, tags match -> HIT, byte_offset=0 -> data[7:0]
        // ---------------------------------------------------------------
        req_tag     = 24'hABCDEF;
        stored_tag  = 24'hABCDEF;
        valid       = 1'b1;
        byte_offset = 2'b00;
        data        = 32'hDEADBEEF;
        #1;
        // hit expected = 1
        // read_byte = data[7:0] = 8'hEF
        check_hit_and_byte(1'b1, 8'hEF, "Hit valid=1 tags match offset=0");

        // ---------------------------------------------------------------
        // Test 3: Valid=1, tags match, byte_offset=1 -> data[15:8]
        // ---------------------------------------------------------------
        req_tag     = 24'hABCDEF;
        stored_tag  = 24'hABCDEF;
        valid       = 1'b1;
        byte_offset = 2'b01;
        data        = 32'hDEADBEEF;
        #1;
        // read_byte = data[15:8] = 8'hBE
        check_hit_and_byte(1'b1, 8'hBE, "Hit valid=1 tags match offset=1");

        // ---------------------------------------------------------------
        // Test 4: Valid=1, tags match, byte_offset=2 -> data[23:16]
        // ---------------------------------------------------------------
        req_tag     = 24'hABCDEF;
        stored_tag  = 24'hABCDEF;
        valid       = 1'b1;
        byte_offset = 2'b10;
        data        = 32'hDEADBEEF;
        #1;
        // read_byte = data[23:16] = 8'hAD
        check_hit_and_byte(1'b1, 8'hAD, "Hit valid=1 tags match offset=2");

        // ---------------------------------------------------------------
        // Test 5: Valid=1, tags match, byte_offset=3 -> data[31:24]
        // ---------------------------------------------------------------
        req_tag     = 24'hABCDEF;
        stored_tag  = 24'hABCDEF;
        valid       = 1'b1;
        byte_offset = 2'b11;
        data        = 32'hDEADBEEF;
        #1;
        // read_byte = data[31:24] = 8'hDE
        check_hit_and_byte(1'b1, 8'hDE, "Hit valid=1 tags match offset=3");

        // ---------------------------------------------------------------
        // Test 6: Valid=1, tags DIFFERENT -> MISS (hit=0)
        // ---------------------------------------------------------------
        req_tag     = 24'hABCDEF;
        stored_tag  = 24'h123456;
        valid       = 1'b1;
        byte_offset = 2'b00;
        data        = 32'hDEADBEEF;
        #1;
        check_hit(1'b0, "Miss when valid=1 but tags differ");

        // ---------------------------------------------------------------
        // Test 7: All-zero inputs: req_tag=0, stored_tag=0, valid=0
        // ---------------------------------------------------------------
        req_tag     = 24'h000000;
        stored_tag  = 24'h000000;
        valid       = 1'b0;
        byte_offset = 2'b00;
        data        = 32'h00000000;
        #1;
        check_hit(1'b0, "All-zero inputs valid=0 -> miss");

        // ---------------------------------------------------------------
        // Test 8: All-zero inputs: req_tag=0, stored_tag=0, valid=1
        // ---------------------------------------------------------------
        req_tag     = 24'h000000;
        stored_tag  = 24'h000000;
        valid       = 1'b1;
        byte_offset = 2'b00;
        data        = 32'h00000000;
        #1;
        check_hit_and_byte(1'b1, 8'h00, "All-zero inputs valid=1 -> hit, byte=0");

        // ---------------------------------------------------------------
        // Test 9: All-ones inputs: req_tag=max, stored_tag=max, valid=1
        // ---------------------------------------------------------------
        req_tag     = 24'hFFFFFF;
        stored_tag  = 24'hFFFFFF;
        valid       = 1'b1;
        byte_offset = 2'b11;
        data        = 32'hFFFFFFFF;
        #1;
        check_hit_and_byte(1'b1, 8'hFF, "All-ones inputs valid=1 offset=3 -> hit, byte=FF");

        // ---------------------------------------------------------------
        // Test 10: All-ones tags mismatch one bit -> MISS
        // ---------------------------------------------------------------
        req_tag     = 24'hFFFFFF;
        stored_tag  = 24'hFFFFFE;
        valid       = 1'b1;
        byte_offset = 2'b00;
        data        = 32'hFFFFFFFF;
        #1;
        check_hit(1'b0, "All-ones tags differ by 1 bit -> miss");

        // ---------------------------------------------------------------
        // Test 11: Simulate valid-bit reset effect: after rst, valid should be 0
        //          (Module is combinational; test with valid=0 to mimic reset)
        // ---------------------------------------------------------------
        req_tag     = 24'h112233;
        stored_tag  = 24'h112233;
        valid       = 1'b0;  // mimic reset clearing valid
        byte_offset = 2'b00;
        data        = 32'hAABBCCDD;
        #1;
        check_hit(1'b0, "Valid-bit reset simulation: valid=0 -> miss");

        // ---------------------------------------------------------------
        // Test 12: Write-through check concept: tags match, valid, check hit
        // ---------------------------------------------------------------
        req_tag     = 24'hC0FFEE;
        stored_tag  = 24'hC0FFEE;
        valid       = 1'b1;
        byte_offset = 2'b01;
        data        = 32'h11223344;
        #1;
        // read_byte = data[15:8] = 8'h33
        check_hit_and_byte(1'b1, 8'h33, "Write-through hit check: offset=1 data=0x11223344");

        // ---------------------------------------------------------------
        // Summary
        // ---------------------------------------------------------------
        $display("--------------------------------------");
        $display("Testbench complete: PASS=%0d FAIL=%0d", pass_count, fail_count);
        $display("--------------------------------------");

        $finish;
    end

endmodule
