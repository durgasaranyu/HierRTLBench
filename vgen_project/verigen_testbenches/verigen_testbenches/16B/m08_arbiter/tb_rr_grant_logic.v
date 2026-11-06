// Testbench for rr_grant_logic
`timescale 1ns/1ps

module tb_rr_grant_logic;

    // Parameters
    parameter N = 4;

    // DUT connections
    reg  [N-1:0] req;
    reg  [N-1:0] ptr;
    wire [N-1:0] grant;

    // Clock and reset (kept for structural compliance; this module is combinational)
    reg clk;
    reg rst;

    // Instantiate DUT
    rr_grant_logic #(.N(N)) uut (
        .req(req),
        .ptr(ptr),
        .grant(grant)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Task for checking
    task check;
        input [N-1:0] expected_grant;
        input [63:0]  test_num;
        input [127:0] description;
        begin
            #1; // small propagation delay
            if (grant === expected_grant) begin
                $display("PASS: Test %0d - %s | req=%b ptr=%b grant=%b (expected %b)",
                         test_num, description, req, ptr, grant, expected_grant);
            end else begin
                $display("FAIL: Test %0d - %s | req=%b ptr=%b grant=%b (expected %b)",
                         test_num, description, req, ptr, grant, expected_grant);
            end
        end
    endtask

    integer i;
    reg [N-1:0] ptr_rot;
    reg [N-1:0] prev_grant;

    initial begin
        // Initialize
        req = 0;
        ptr = 0;
        rst = 1;

        // Assert synchronous reset for 5 rising edges (structural compliance)
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        rst = 0;
        #2;

        // -----------------------------------------------------------------
        // Test 1: req=0, ptr=0 -> grant should be 0 (no requests)
        // -----------------------------------------------------------------
        req = 4'b0000;
        ptr = 4'b0001;
        check(4'b0000, 1, "grant=0 when req=0, ptr=0001");

        // -----------------------------------------------------------------
        // Test 2: req=0001, ptr=0001 -> grant bit 0 (ptr and req both bit0)
        // -----------------------------------------------------------------
        req = 4'b0001;
        ptr = 4'b0001;
        check(4'b0001, 2, "grant bit 0 when req=0001 ptr=0001");

        // -----------------------------------------------------------------
        // Test 3: req=0010, ptr=0010 -> grant bit 1
        // -----------------------------------------------------------------
        req = 4'b0010;
        ptr = 4'b0010;
        check(4'b0010, 3, "grant bit 1 when req=0010 ptr=0010");

        // -----------------------------------------------------------------
        // Test 4: req=1111 (all ones), ptr=0001 -> grant=0001
        // (ptr points to bit0, only bit0 in req&ptr overlap -> grant=0001)
        // -----------------------------------------------------------------
        req = 4'b1111;
        ptr = 4'b0001;
        check(4'b0001, 4, "all req high ptr=0001 grants bit0");

        // -----------------------------------------------------------------
        // Test 5: req=1111, ptr=0010 -> grant=0010 (ptr rotated to bit1)
        // -----------------------------------------------------------------
        req = 4'b1111;
        ptr = 4'b0010;
        check(4'b0010, 5, "all req high ptr=0010 grants bit1");

        // -----------------------------------------------------------------
        // Test 6: req=1111, ptr=0100 -> grant=0100 (ptr points to bit2)
        // -----------------------------------------------------------------
        req = 4'b1111;
        ptr = 4'b0100;
        check(4'b0100, 6, "all req high ptr=0100 grants bit2");

        // -----------------------------------------------------------------
        // Test 7: req=1111, ptr=1000 -> grant=1000 (ptr points to bit3)
        // -----------------------------------------------------------------
        req = 4'b1111;
        ptr = 4'b1000;
        check(4'b1000, 7, "all req high ptr=1000 grants bit3");

        // -----------------------------------------------------------------
        // Test 8: Round-robin rotation: grant bit 0 then verify bit 1
        // Simulate: start ptr=0001, req=1111, grant=0001
        //           advance ptr to 0010, grant=0010
        // -----------------------------------------------------------------
        req = 4'b1111;
        ptr = 4'b0001;
        #1;
        if (grant === 4'b0001) begin
            $display("PASS: Test 8a - RR grant bit0: grant=%b", grant);
        end else begin
            $display("FAIL: Test 8a - RR grant bit0: grant=%b (expected 0001)", grant);
        end
        // Now advance ptr to next bit (bit1)
        ptr = 4'b0010;
        #1;
        if (grant === 4'b0010) begin
            $display("PASS: Test 8b - RR next grant bit1: grant=%b", grant);
        end else begin
            $display("FAIL: Test 8b - RR next grant bit1: grant=%b (expected 0010)", grant);
        end

        // -----------------------------------------------------------------
        // Test 9: Starvation test - all bits high, rotate ptr through all positions
        // Verify no bit is skipped (all are granted in rotation)
        // -----------------------------------------------------------------
        req = 4'b1111;
        ptr_rot = 4'b0001;
        begin : starvation_test
            integer j;
            reg pass_all;
            reg [N-1:0] expected;
            pass_all = 1;
            for (j = 0; j < N; j = j + 1) begin
                ptr = ptr_rot;
                expected = ptr_rot;
                #1;
                if (grant !== expected) begin
                    $display("FAIL: Test 9 starvation rotate j=%0d ptr=%b grant=%b expected=%b",
                             j, ptr_rot, grant, expected);
                    pass_all = 0;
                end
                // rotate ptr left (one-hot)
                ptr_rot = {ptr_rot[N-2:0], ptr_rot[N-1]};
            end
            if (pass_all)
                $display("PASS: Test 9 - Starvation test, all bits granted in rotation");
        end

        // -----------------------------------------------------------------
        // Test 10: All-ones req, all-ones ptr -> grant = all-ones
        // (every bit has ptr set and req set, so grant = req & ptr = all-ones)
        // -----------------------------------------------------------------
        req = 4'b1111;
        ptr = 4'b1111;
        check(4'b1111, 10, "all-ones req and ptr grants all-ones");

        // -----------------------------------------------------------------
        // Test 11: req=1010, ptr=1010 -> grant=1010 (bits 1 and 3)
        // -----------------------------------------------------------------
        req = 4'b1010;
        ptr = 4'b1010;
        check(4'b1010, 11, "req=1010 ptr=1010 grants 1010");

        // -----------------------------------------------------------------
        // Test 12: req=0101, ptr=0101 -> grant=0101 (bits 0 and 2)
        // -----------------------------------------------------------------
        req = 4'b0101;
        ptr = 4'b0101;
        check(4'b0101, 12, "req=0101 ptr=0101 grants 0101");

        // -----------------------------------------------------------------
        // Test 13: req=1111, ptr=0000 -> grant=0000 (ptr all zero)
        // -----------------------------------------------------------------
        req = 4'b1111;
        ptr = 4'b0000;
        check(4'b0000, 13, "all req high ptr=0000 grants nothing");

        // -----------------------------------------------------------------
        // Test 14: Reset verification - combinational module, no state to reset
        //          but verify that after rst=1, module still outputs correctly
        // -----------------------------------------------------------------
        rst = 1;
        req = 4'b0011;
        ptr = 4'b0011;
        #1;
        if (grant === 4'b0011) begin
            $display("PASS: Test 14 - Reset asserted, combinational output still correct: grant=%b", grant);
        end else begin
            $display("FAIL: Test 14 - Reset asserted, grant=%b expected 0011", grant);
        end
        rst = 0;

        #10;
        $display("All tests completed.");
        $finish;
    end

endmodule
