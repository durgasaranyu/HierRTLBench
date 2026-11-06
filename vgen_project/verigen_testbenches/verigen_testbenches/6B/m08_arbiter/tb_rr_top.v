`timescale 1ns/1ps

module tb_rr_top;

    // Parameters
    parameter N = 4;

    // DUT connections
    reg clk;
    reg rst;
    reg [N-1:0] req;
    wire [N-1:0] grant;

    // Instantiate DUT
    round_robin_arbiter #(.N(N)) uut (
        .clk(clk),
        .rst(rst),
        .req(req),
        .grant(grant)
    );

    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Task: wait for rising edge and small delay
    task wait_clk;
        begin
            @(posedge clk);
            #1; // small delay after edge to sample outputs
        end
    endtask

    // Variables for checking
    integer i;
    integer pass_count;
    integer fail_count;
    integer grant_seen;
    integer all_bits_seen;

    // Timeout watchdog
    initial begin
        #10000;
        $display("TIMEOUT: Simulation exceeded limit");
        $finish;
    end

    initial begin
        // Initialize
        rst = 1;
        req = 4'b0000;
        pass_count = 0;
        fail_count = 0;

        // Assert reset for exactly 5 clock rising edges
        repeat(5) @(posedge clk);
        #1;

        // Deassert reset
        rst = 0;
        @(posedge clk);
        #1;

        // ================================================================
        // TEST 1: After reset, grant should be 0 when req=0
        // ================================================================
        req = 4'b0000;
        @(posedge clk);
        #1;
        @(posedge clk);
        #1;
        if (grant === 4'b0000) begin
            $display("PASS: Test 1 - grant=0 when req=0 after reset");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 1 - grant=0 when req=0 after reset, got grant=%b", grant);
            fail_count = fail_count + 1;
        end

        // ================================================================
        // TEST 2: Reset clears grant register
        // ================================================================
        // Apply some request, then reset, verify grant goes to 0
        req = 4'b1111;
        @(posedge clk);
        #1;
        @(posedge clk);
        #1;
        // Now assert reset
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        rst = 0;
        req = 4'b0000;
        @(posedge clk);
        #1;
        if (grant === 4'b0000) begin
            $display("PASS: Test 2 - Reset clears grant register");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 2 - Reset did not clear grant, got grant=%b", grant);
            fail_count = fail_count + 1;
        end

        // ================================================================
        // TEST 3: Single request on bit 0 - grant bit 0
        // ================================================================
        req = 4'b0001;
        @(posedge clk);
        #1;
        @(posedge clk);
        #1;
        // The arbiter should eventually grant bit 0
        // Wait a few cycles and check
        @(posedge clk);
        #1;
        if (grant[0] === 1'b1) begin
            $display("PASS: Test 3 - Single request bit 0 granted");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 3 - Single request bit 0 not granted, grant=%b", grant);
            fail_count = fail_count + 1;
        end

        // ================================================================
        // TEST 4: Round-robin rotation - grant bit 0 then bit 1
        // ================================================================
        // Reset to known state
        rst = 1;
        req = 4'b0000;
        repeat(5) @(posedge clk);
        #1;
        rst = 0;
        @(posedge clk);
        #1;

        // Request bits 0 and 1
        req = 4'b0011;
        // Wait enough cycles to observe rotation
        // Track which bits were granted
        grant_seen = 0;
        begin : rotation_test
            integer cyc;
            integer bit0_granted;
            integer bit1_granted;
            bit0_granted = 0;
            bit1_granted = 0;
            for (cyc = 0; cyc < 20; cyc = cyc + 1) begin
                @(posedge clk);
                #1;
                if (grant[0]) bit0_granted = 1;
                if (grant[1]) bit1_granted = 1;
            end
            if (bit0_granted && bit1_granted) begin
                $display("PASS: Test 4 - Round-robin: both bit 0 and bit 1 were granted");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Test 4 - Round-robin failed: bit0_granted=%0d bit1_granted=%0d", bit0_granted, bit1_granted);
                fail_count = fail_count + 1;
            end
        end

        // ================================================================
        // TEST 5: Starvation prevention - all bits high, every bit granted
        // ================================================================
        rst = 1;
        req = 4'b0000;
        repeat(5) @(posedge clk);
        #1;
        rst = 0;
        @(posedge clk);
        #1;

        req = 4'b1111;
        begin : starvation_test
            integer cyc2;
            integer b0;
            integer b1;
            integer b2;
            integer b3;
            b0 = 0; b1 = 0; b2 = 0; b3 = 0;
            for (cyc2 = 0; cyc2 < 32; cyc2 = cyc2 + 1) begin
                @(posedge clk);
                #1;
                if (grant[0]) b0 = 1;
                if (grant[1]) b1 = 1;
                if (grant[2]) b2 = 1;
                if (grant[3]) b3 = 1;
            end
            if (b0 && b1 && b2 && b3) begin
                $display("PASS: Test 5 - No starvation: all 4 bits granted with all-ones req");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Test 5 - Starvation detected: b0=%0d b1=%0d b2=%0d b3=%0d", b0, b1, b2, b3);
                fail_count = fail_count + 1;
            end
        end

        // ================================================================
        // TEST 6: All-zero request - grant stays 0
        // ================================================================
        rst = 1;
        req = 4'b0000;
        repeat(5) @(posedge clk);
        #1;
        rst = 0;
        req = 4'b0000;
        @(posedge clk);
        #1;
        @(posedge clk);
        #1;
        @(posedge clk);
        #1;
        if (grant === 4'b0000) begin
            $display("PASS: Test 6 - All-zero req keeps grant=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 6 - All-zero req but grant=%b", grant);
            fail_count = fail_count + 1;
        end

        // ================================================================
        // TEST 7: All-ones request - one-hot grant (only one bit at a time)
        // ================================================================
        rst = 1;
        req = 4'b0000;
        repeat(5) @(posedge clk);
        #1;
        rst = 0;
        req = 4'b1111;
        begin : onehot_test
            integer cyc3;
            integer onehot_ok;
            integer popcount;
            onehot_ok = 1;
            for (cyc3 = 0; cyc3 < 16; cyc3 = cyc3 + 1) begin
                @(posedge clk);
                #1;
                // Count bits in grant
                popcount = grant[0] + grant[1] + grant[2] + grant[3];
                if (grant !== 4'b0000 && popcount !== 1) begin
                    onehot_ok = 0;
                end
            end
            if (onehot_ok) begin
                $display("PASS: Test 7 - All-ones req: grant is always one-hot or zero");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Test 7 - All-ones req: grant was not one-hot");
                fail_count = fail_count + 1;
            end
        end

        // ================================================================
        // TEST 8: Single request on highest bit (bit 3)
        // ================================================================
        rst = 1;
        req = 4'b0000;
        repeat(5) @(posedge clk);
        #1;
        rst = 0;
        req = 4'b1000;
        @(posedge clk);
        #1;
        @(posedge clk);
        #1;
        @(posedge clk);
        #1;
        if (grant[3] === 1'b1) begin
            $display("PASS: Test 8 - Single request bit 3 granted");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 8 - Single request bit 3 not granted, grant=%b", grant);
            fail_count = fail_count + 1;
        end

        // ================================================================
        // TEST 9: Verify reset asserted mid-operation clears grant
        // ================================================================
        rst = 0;
        req = 4'b1111;
        @(posedge clk);
        #1;
        @(posedge clk);
        #1;
        // Assert reset mid-stream
        rst = 1;
        @(posedge clk);
        #1;
        @(posedge clk);
        #1;
        if (grant === 4'b0000) begin
            $display("PASS: Test 9 - Mid-operation reset clears grant");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 9 - Mid-operation reset did not clear grant, got grant=%b", grant);
            fail_count = fail_count + 1;
        end
        rst = 0;

        // ================================================================
        // TEST 10: Alternating requests bit 0 and bit 2 only
        // ================================================================
        rst = 1;
        req = 4'b0000;
        repeat(5) @(posedge clk);
        #1;
        rst = 0;
        req = 4'b0101; // bits 0 and 2
        begin : alt_test
            integer cyc4;
            integer a0;
            integer a2;
            a0 = 0; a2 = 0;
            for (cyc4 = 0; cyc4 < 20; cyc4 = cyc4 + 1) begin
                @(posedge clk);
                #1;
                if (grant[0]) a0 = 1;
                if (grant[2]) a2 = 1;
            end
            if (a0 && a2) begin
                $display("PASS: Test 10 - Bits 0 and 2 both granted in rotation");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Test 10 - Not both bit 0 and bit 2 granted: a0=%0d a2=%0d", a0, a2);
                fail_count = fail_count + 1;
            end
        end

        // ================================================================
        // Summary
        // ================================================================
        $display("========================================");
        $display("Simulation complete: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("========================================");

        $finish;
    end

endmodule
