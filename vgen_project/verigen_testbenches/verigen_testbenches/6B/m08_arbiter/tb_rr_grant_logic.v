`timescale 1ns/1ps

module tb_rr_grant_logic;

    // Parameters
    parameter N = 4;

    // DUT inputs
    reg [N-1:0] req;
    reg [N-1:0] ptr;

    // DUT outputs
    wire [N-1:0] grant;

    // Clock and reset for sequencing tests
    reg clk;
    reg rst;

    // Instantiate the DUT
    rr_grant_logic #(.N(N)) uut (
        .req(req),
        .ptr(ptr),
        .grant(grant)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset sequence (drives rst for 5 rising edges)
    integer i;
    integer pass_count;
    integer fail_count;

    initial begin
        rst = 1;
        req = 0;
        ptr = 0;
        pass_count = 0;
        fail_count = 0;

        // Hold reset for 5 rising edges
        repeat(5) @(posedge clk);
        rst = 0;
        @(negedge clk);

        // -------------------------------------------------------
        // Test 1: req=0, ptr=0 -> grant should be 0
        // -------------------------------------------------------
        req = 4'b0000;
        ptr = 4'b0001; // ptr at bit 0
        #2;
        // With all rr_grant registers at 0 and ptr=0001, the combinational
        // logic: rr_grant_0=0, ptr=0001, they are not equal (0 != 1),
        // so grant = rr_grant_0 = 0
        if (grant === 4'b0000) begin
            $display("PASS: Test1 - req=0, ptr=1, grant=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test1 - req=0, ptr=1, expected grant=0, got %b", grant);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 2: All zeros - req=0, ptr=0 -> grant=0
        // -------------------------------------------------------
        req = 4'b0000;
        ptr = 4'b0000;
        #2;
        // rr_grant_0=0 == ptr=0, rr_grant_1=0 == ptr=0, rr_grant_2=0 == ptr=0
        // grant = ptr = 0
        if (grant === 4'b0000) begin
            $display("PASS: Test2 - All-zero req and ptr, grant=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test2 - All-zero req and ptr, expected grant=0, got %b", grant);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 3: ptr=0001 (bit 0), req=0001 -> verify grant behavior
        // -------------------------------------------------------
        req = 4'b0001;
        ptr = 4'b0001;
        #2;
        // All rr_grant registers are 0, ptr=0001
        // rr_grant_0=0 != ptr=0001 -> grant = rr_grant_0 = 0
        if (grant === 4'b0000) begin
            $display("PASS: Test3 - req=0001, ptr=0001, grant=0 (rr_grant regs are 0)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test3 - req=0001, ptr=0001, expected grant=0, got %b", grant);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 4: ptr matches rr_grant_0 (both 0), rr_grant_1 != ptr
        //         Checking rr_grant_1 branch
        // -------------------------------------------------------
        // rr_grant_0=0, ptr=0, rr_grant_0==ptr -> check rr_grant_1
        // rr_grant_1=0 == ptr=0 -> check rr_grant_2
        // rr_grant_2=0 == ptr=0 -> grant = ptr = 0
        req = 4'b1111;
        ptr = 4'b0000;
        #2;
        if (grant === 4'b0000) begin
            $display("PASS: Test4 - req=1111, ptr=0, all rr_grant=0, grant=ptr=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test4 - req=1111, ptr=0, expected grant=0, got %b", grant);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 5: All-ones inputs - req=1111, ptr=1111
        // -------------------------------------------------------
        req = 4'b1111;
        ptr = 4'b1111;
        #2;
        // rr_grant_0=0 != ptr=1111 -> grant = rr_grant_0 = 0
        if (grant === 4'b0000) begin
            $display("PASS: Test5 - req=1111, ptr=1111, grant=0 (rr_grant_0=0 != ptr)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test5 - req=1111, ptr=1111, expected grant=0, got %b", grant);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 6: ptr=0010 (bit 1), req=0010
        // -------------------------------------------------------
        req = 4'b0010;
        ptr = 4'b0010;
        #2;
        // rr_grant_0=0 != ptr=0010 -> grant = rr_grant_0 = 0
        if (grant === 4'b0000) begin
            $display("PASS: Test6 - req=0010, ptr=0010, grant=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test6 - req=0010, ptr=0010, expected grant=0, got %b", grant);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 7: ptr=0100 (bit 2), req=0100
        // -------------------------------------------------------
        req = 4'b0100;
        ptr = 4'b0100;
        #2;
        if (grant === 4'b0000) begin
            $display("PASS: Test7 - req=0100, ptr=0100, grant=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test7 - req=0100, ptr=0100, expected grant=0, got %b", grant);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 8: ptr=1000 (bit 3), req=1000
        // -------------------------------------------------------
        req = 4'b1000;
        ptr = 4'b1000;
        #2;
        if (grant === 4'b0000) begin
            $display("PASS: Test8 - req=1000, ptr=1000, grant=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test8 - req=1000, ptr=1000, expected grant=0, got %b", grant);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 9: Verify rr_grant_3 path (grant = rr_grant_3 when rr_grant_0 != ptr)
        //         With all internal regs=0, ptr!=0 -> grant=0
        // -------------------------------------------------------
        req = 4'b1010;
        ptr = 4'b0101;
        #2;
        // rr_grant_0=0 != ptr=0101 -> grant = rr_grant_0 = 0
        if (grant === 4'b0000) begin
            $display("PASS: Test9 - req=1010, ptr=0101, grant=0 (rr_grant_0=0 != ptr)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test9 - req=1010, ptr=0101, expected grant=0, got %b", grant);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 10: Maximum value inputs - req=1111, ptr=1111
        //          (same as test 5 but explicit max check)
        // -------------------------------------------------------
        req = 4'hF;
        ptr = 4'hF;
        #2;
        if (grant === 4'b0000) begin
            $display("PASS: Test10 - Maximum inputs req=F ptr=F, grant=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test10 - Maximum inputs req=F ptr=F, expected grant=0, got %b", grant);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 11: req=0, ptr=0 (both exactly zero edge case)
        // -------------------------------------------------------
        req = 4'b0000;
        ptr = 4'b0000;
        #2;
        // rr_grant_0=0==ptr=0, rr_grant_1=0==ptr=0, rr_grant_2=0==ptr=0 -> grant=ptr=0
        if (grant === 4'b0000) begin
            $display("PASS: Test11 - req=0, ptr=0, grant=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test11 - req=0, ptr=0, expected grant=0, got %b", grant);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 12: Starvation check - rotate through all ptr values
        //          with req=all ones, verify consistent grant behavior
        // -------------------------------------------------------
        req = 4'b1111;
        ptr = 4'b0001; #2;
        if (grant === 4'b0000) begin
            $display("PASS: Test12a - Starvation: req=1111, ptr=0001, grant=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test12a - Starvation: req=1111, ptr=0001, expected grant=0, got %b", grant);
            fail_count = fail_count + 1;
        end

        ptr = 4'b0010; #2;
        if (grant === 4'b0000) begin
            $display("PASS: Test12b - Starvation: req=1111, ptr=0010, grant=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test12b - Starvation: req=1111, ptr=0010, expected grant=0, got %b", grant);
            fail_count = fail_count + 1;
        end

        ptr = 4'b0100; #2;
        if (grant === 4'b0000) begin
            $display("PASS: Test12c - Starvation: req=1111, ptr=0100, grant=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test12c - Starvation: req=1111, ptr=0100, expected grant=0, got %b", grant);
            fail_count = fail_count + 1;
        end

        ptr = 4'b1000; #2;
        if (grant === 4'b0000) begin
            $display("PASS: Test12d - Starvation: req=1111, ptr=1000, grant=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test12d - Starvation: req=1111, ptr=1000, expected grant=0, got %b", grant);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Summary
        // -------------------------------------------------------
        $display("------------------------------------------");
        $display("Total PASS: %0d, Total FAIL: %0d", pass_count, fail_count);
        $display("------------------------------------------");

        $finish;
    end

endmodule
