`timescale 1ns/1ps

// Testbench for rr_grant_logic
module tb_rr_grant_logic;

    // Parameters
    parameter N = 4;

    // DUT ports
    reg  [N-1:0] req;
    reg  [N-1:0] ptr;
    wire [N-1:0] grant;

    // Clock and reset (not used by combinational DUT, but required by spec)
    reg clk;
    reg rst;

    // Instantiate DUT
    rr_grant_logic #(.N(N)) uut (
        .req   (req),
        .ptr   (ptr),
        .grant (grant)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Task for checking
    task check;
        input [N-1:0] expected;
        input [63:0]  test_num;
        input [127:0] desc;
        begin
            if (grant === expected) begin
                $display("PASS: Test %0d - %s | req=%b ptr=%b grant=%b expected=%b",
                         test_num, desc, req, ptr, grant, expected);
            end else begin
                $display("FAIL: Test %0d - %s | req=%b ptr=%b grant=%b expected=%b",
                         test_num, desc, req, ptr, grant, expected);
            end
        end
    endtask

    // Synchronous reset for 5 rising edges (not used by combinational DUT but required)
    integer i;
    initial begin
        rst = 1;
        req = 0;
        ptr = 0;
        // Wait for 5 rising edges
        for (i = 0; i < 5; i = i + 1) begin
            @(posedge clk);
        end
        rst = 0;

        // Small delay after reset
        #2;

        // ----------------------------------------------------------------
        // Test 1: req=0, ptr=0 => grant=0 (no requests)
        // ----------------------------------------------------------------
        req = 4'b0000;
        ptr = 4'b0000;
        #2;
        // grant = req ^ {1'b0, ptr[3:1]} = 0000 ^ {0, 000} = 0000 ^ 0000 = 0000
        check(4'b0000, 1, "grant=0 when req=0");

        // ----------------------------------------------------------------
        // Test 2: All-ones req, ptr=0001 (bit 0 highest priority)
        // grant = 1111 ^ {0, 000} = 1111 ^ 0000 = 1111
        // ----------------------------------------------------------------
        req = 4'b1111;
        ptr = 4'b0001;
        #2;
        // grant = 1111 ^ {0, ptr[3:1]} = 1111 ^ {0, 000} = 1111 ^ 0000 = 1111
        check(4'b1111, 2, "all-ones req, ptr=0001");

        // ----------------------------------------------------------------
        // Test 3: req=0001 (only bit0), ptr=0001
        // grant = 0001 ^ {0, 000} = 0001
        // ----------------------------------------------------------------
        req = 4'b0001;
        ptr = 4'b0001;
        #2;
        check(4'b0001, 3, "req=0001 ptr=0001 => grant=0001");

        // ----------------------------------------------------------------
        // Test 4: req=0010 (only bit1), ptr=0010
        // grant = 0010 ^ {0, ptr[3:1]} = 0010 ^ {0, 001} = 0010 ^ 0001 = 0011
        // ----------------------------------------------------------------
        req = 4'b0010;
        ptr = 4'b0010;
        #2;
        // {1'b0, ptr[3:1]} = {0, 4'b0010[3:1]} = {0, 001} = 4'b0001
        // grant = 0010 ^ 0001 = 0011
        check(4'b0011, 4, "req=0010 ptr=0010 => grant=0011");

        // ----------------------------------------------------------------
        // Test 5: req=0100 (only bit2), ptr=0100
        // {1'b0, ptr[3:1]} = {0, 010} = 0010
        // grant = 0100 ^ 0010 = 0110
        // ----------------------------------------------------------------
        req = 4'b0100;
        ptr = 4'b0100;
        #2;
        check(4'b0110, 5, "req=0100 ptr=0100 => grant=0110");

        // ----------------------------------------------------------------
        // Test 6: req=1000 (only bit3), ptr=1000
        // {1'b0, ptr[3:1]} = {0, 100} = 0100
        // grant = 1000 ^ 0100 = 1100
        // ----------------------------------------------------------------
        req = 4'b1000;
        ptr = 4'b1000;
        #2;
        check(4'b1100, 6, "req=1000 ptr=1000 => grant=1100");

        // ----------------------------------------------------------------
        // Test 7: All-ones req, ptr=1000 (start from bit3)
        // {1'b0, ptr[3:1]} = {0, 100} = 0100
        // grant = 1111 ^ 0100 = 1011
        // ----------------------------------------------------------------
        req = 4'b1111;
        ptr = 4'b1000;
        #2;
        check(4'b1011, 7, "all-ones req, ptr=1000 starvation test");

        // ----------------------------------------------------------------
        // Test 8: All-ones req, ptr=0100 (start from bit2)
        // {1'b0, ptr[3:1]} = {0, 010} = 0010
        // grant = 1111 ^ 0010 = 1101
        // ----------------------------------------------------------------
        req = 4'b1111;
        ptr = 4'b0100;
        #2;
        check(4'b1101, 8, "all-ones req, ptr=0100 rotation");

        // ----------------------------------------------------------------
        // Test 9: All-ones req, ptr=0010
        // {1'b0, ptr[3:1]} = {0, 001} = 0001
        // grant = 1111 ^ 0001 = 1110
        // ----------------------------------------------------------------
        req = 4'b1111;
        ptr = 4'b0010;
        #2;
        check(4'b1110, 9, "all-ones req, ptr=0010 rotation");

        // ----------------------------------------------------------------
        // Test 10: Reset check - after reset (simulated by checking zero input)
        // req=0000, ptr=0000 => grant=0000
        // ----------------------------------------------------------------
        @(posedge clk);
        req = 4'b0000;
        ptr = 4'b0000;
        #2;
        check(4'b0000, 10, "reset clears grant - all zero");

        // ----------------------------------------------------------------
        // Test 11: Max value inputs (all ones for both req and ptr)
        // req=1111, ptr=1111
        // {1'b0, ptr[3:1]} = {0, 111} = 0111
        // grant = 1111 ^ 0111 = 1000
        // ----------------------------------------------------------------
        req = 4'b1111;
        ptr = 4'b1111;
        #2;
        check(4'b1000, 11, "max-value req=1111 ptr=1111");

        // ----------------------------------------------------------------
        // Test 12: Partial requests - req=1010, ptr=0001
        // {1'b0, ptr[3:1]} = {0, 000} = 0000
        // grant = 1010 ^ 0000 = 1010
        // ----------------------------------------------------------------
        req = 4'b1010;
        ptr = 4'b0001;
        #2;
        check(4'b1010, 12, "partial req=1010 ptr=0001");

        // ----------------------------------------------------------------
        // Test 13: Round-robin rotation verify: grant bit0 first, then bit1
        // Step A: req=1111, ptr=0001 => grant=1111^0000=1111 (bit0 granted)
        // Step B: req=1111, ptr=0010 => grant=1111^0001=1110 (bit1 up next)
        // ----------------------------------------------------------------
        req = 4'b1111;
        ptr = 4'b0001;
        #2;
        check(4'b1111, 13, "RR step A: ptr=0001 bit0 priority");

        req = 4'b1111;
        ptr = 4'b0010;
        #2;
        check(4'b1110, 14, "RR step B: ptr=0010 bit1 priority");

        $display("All tests complete.");
        $finish;
    end

endmodule
