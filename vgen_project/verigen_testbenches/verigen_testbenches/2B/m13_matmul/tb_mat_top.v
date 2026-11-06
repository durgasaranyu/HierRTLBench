`timescale 1ns/1ps

module tb_mat_top;

    // Clock and reset
    reg clk;
    reg rst;
    reg start;

    // Matrix inputs and outputs
    reg  [4095:0] A_flat;
    reg  [4095:0] B_flat;
    wire [8191:0] C_flat;
    wire          done;

    // DUT instantiation
    matrix_mult uut (
        .clk    (clk),
        .rst    (rst),
        .start  (start),
        .A_flat (A_flat),
        .B_flat (B_flat),
        .C_flat (C_flat),
        .done   (done)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Integer variables for loops
    integer i, j, k;
    integer pass_count, fail_count;
    integer timeout;

    // Helpers: 16-bit element from flat matrix (row-major, 16x16)
    // A_flat[16*16*16-1 : 0], element [i][j] is bits [(i*16+j)*16+15 : (i*16+j)*16]

    // Task: set identity matrix into a flat register
    task set_identity;
        input [4095:0] dummy; // unused, just for syntax
        output [4095:0] mat;
        integer r, c;
        begin
            mat = 0;
            for (r = 0; r < 16; r = r + 1) begin
                for (c = 0; c < 16; c = c + 1) begin
                    if (r == c)
                        mat[(r*16+c)*16 +: 16] = 16'd1;
                    else
                        mat[(r*16+c)*16 +: 16] = 16'd0;
                end
            end
        end
    endtask

    // Task: set zero matrix
    task set_zero_matrix;
        output [4095:0] mat;
        begin
            mat = 0;
        end
    endtask

    // Task: wait for done with timeout
    task wait_for_done;
        input integer max_cycles;
        output timed_out;
        reg timed_out;
        integer cnt;
        begin
            timed_out = 0;
            cnt = 0;
            while (!done && cnt < max_cycles) begin
                @(posedge clk);
                cnt = cnt + 1;
            end
            if (cnt >= max_cycles) timed_out = 1;
        end
    endtask

    // Temporary variables
    reg [4095:0] identity_mat;
    reg [4095:0] A_test, B_test;
    reg [8191:0] C_expected;
    reg [15:0] a_elem, b_elem;
    reg [31:0] c_elem, c_expected_elem;
    reg timed_out;
    reg test_pass;
    integer row, col, kk;

    initial begin
        pass_count = 0;
        fail_count = 0;
        rst   = 1;
        start = 0;
        A_flat = 0;
        B_flat = 0;

        // Assert reset for exactly 5 rising edges
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 0;

        // Wait a couple of cycles after reset
        @(posedge clk);
        @(posedge clk);

        // =====================================================================
        // Test 1: Zero matrix * Zero matrix = Zero matrix
        // =====================================================================
        A_flat = 0;
        B_flat = 0;
        @(negedge clk);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        wait_for_done(500, timed_out);

        if (timed_out) begin
            $display("FAIL: Test1 Zero*Zero - timed out waiting for done");
            fail_count = fail_count + 1;
        end else begin
            test_pass = 1;
            if (C_flat !== 8192'b0) begin
                test_pass = 0;
            end
            if (test_pass) begin
                $display("PASS: Test1 Zero*Zero = Zero");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Test1 Zero*Zero != Zero");
                fail_count = fail_count + 1;
            end
        end

        @(posedge clk);
        @(posedge clk);

        // =====================================================================
        // Test 2: Identity * Identity = Identity
        // =====================================================================
        // Build identity matrix
        identity_mat = 0;
        for (i = 0; i < 16; i = i + 1)
            identity_mat[(i*16+i)*16 +: 16] = 16'd1;

        A_flat = identity_mat;
        B_flat = identity_mat;

        @(negedge clk);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        wait_for_done(500, timed_out);

        if (timed_out) begin
            $display("FAIL: Test2 Identity*Identity - timed out");
            fail_count = fail_count + 1;
        end else begin
            // Expected: identity matrix (32-bit elements)
            test_pass = 1;
            for (row = 0; row < 16; row = row + 1) begin
                for (col = 0; col < 16; col = col + 1) begin
                    c_elem = C_flat[(row*16+col)*32 +: 32];
                    if (row == col)
                        c_expected_elem = 32'd1;
                    else
                        c_expected_elem = 32'd0;
                    if (c_elem !== c_expected_elem)
                        test_pass = 0;
                end
            end
            if (test_pass) begin
                $display("PASS: Test2 Identity*Identity = Identity");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Test2 Identity*Identity != Identity");
                fail_count = fail_count + 1;
            end
        end

        @(posedge clk);
        @(posedge clk);

        // =====================================================================
        // Test 3: A * Identity = A (A has sequential values 1..256)
        // =====================================================================
        A_test = 0;
        for (i = 0; i < 256; i = i + 1)
            A_test[i*16 +: 16] = i[15:0] + 16'd1;

        B_flat = identity_mat;
        A_flat = A_test;

        @(negedge clk);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        wait_for_done(500, timed_out);

        if (timed_out) begin
            $display("FAIL: Test3 A*Identity - timed out");
            fail_count = fail_count + 1;
        end else begin
            test_pass = 1;
            for (row = 0; row < 16; row = row + 1) begin
                for (col = 0; col < 16; col = col + 1) begin
                    c_elem = C_flat[(row*16+col)*32 +: 32];
                    a_elem = A_test[(row*16+col)*16 +: 16];
                    c_expected_elem = {16'd0, a_elem};
                    if (c_elem !== c_expected_elem)
                        test_pass = 0;
                end
            end
            if (test_pass) begin
                $display("PASS: Test3 A*Identity = A");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Test3 A*Identity != A");
                fail_count = fail_count + 1;
            end
        end

        @(posedge clk);
        @(posedge clk);

        // =====================================================================
        // Test 4: Identity * B = B (B has sequential values)
        // =====================================================================
        B_test = 0;
        for (i = 0; i < 256; i = i + 1)
            B_test[i*16 +: 16] = (16'd256 - i[15:0]);

        A_flat = identity_mat;
        B_flat = B_test;

        @(negedge clk);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        wait_for_done(500, timed_out);

        if (timed_out) begin
            $display("FAIL: Test4 Identity*B - timed out");
            fail_count = fail_count + 1;
        end else begin
            test_pass = 1;
            for (row = 0; row < 16; row = row + 1) begin
                for (col = 0; col < 16; col = col + 1) begin
                    c_elem = C_flat[(row*16+col)*32 +: 32];
                    b_elem = B_test[(row*16+col)*16 +: 16];
                    c_expected_elem = {16'd0, b_elem};
                    if (c_elem !== c_expected_elem)
                        test_pass = 0;
                end
            end
            if (test_pass) begin
                $display("PASS: Test4 Identity*B = B");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Test4 Identity*B != B");
                fail_count = fail_count + 1;
            end
        end

        @(posedge clk);
        @(posedge clk);

        // =====================================================================
        // Test 5: All-ones A * All-ones B
        // Each element of C[i][j] = sum over k of A[i][k]*B[k][j] = 16*1*1 = 16
        // =====================================================================
        A_flat = {4096{1'b1}}; // All 16-bit elements = 0xFFFF = 65535
        B_flat = {4096{1'b1}};

        @(negedge clk);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        wait_for_done(500, timed_out);

        if (timed_out) begin
            $display("FAIL: Test5 AllOnes*AllOnes - timed out");
            fail_count = fail_count + 1;
        end else begin
            // Each element = 16 * 65535 * 65535 = 16 * 4294836225 = overflow in 32 bits
            // 65535*65535 = 4294836225 > 2^32, so we check lower 32 bits
            // Actually 65535*65535 = (2^16-1)^2 = 2^32 - 2^17 + 1 = 4294836225
            // 16 * 4294836225 = 68717379600 which overflows 32 bits
            // Lower 32 bits: 68717379600 mod 2^32 = 68717379600 - 16*2^32 = 68717379600 - 68719476736 = -2097136
            // = 2^32 - 2097136 = 4292870160
            c_expected_elem = 32'd4292870160;
            test_pass = 1;
            for (row = 0; row < 16; row = row + 1) begin
                for (col = 0; col < 16; col = col + 1) begin
                    c_elem = C_flat[(row*16+col)*32 +: 32];
                    if (c_elem !== c_expected_elem)
                        test_pass = 0;
                end
            end
            if (test_pass) begin
                $display("PASS: Test5 AllOnes*AllOnes = expected overflow result");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Test5 AllOnes*AllOnes unexpected result (C[0][0]=%0d, expected=%0d)",
                         C_flat[31:0], c_expected_elem);
                fail_count = fail_count + 1;
            end
        end

        @(posedge clk);
        @(posedge clk);

        // =====================================================================
        // Test 6: Single non-zero element: A[0][0]=1, rest 0; B=identity -> C=A
        // =====================================================================
        A_test = 0;
        A_test[0 +: 16] = 16'd5; // A[0][0] = 5

        A_flat = A_test;
        B_flat = identity_mat;

        @(negedge clk);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        wait_for_done(500, timed_out);

        if (timed_out) begin
            $display("FAIL: Test6 Sparse*Identity - timed out");
            fail_count = fail_count + 1;
        end else begin
            test_pass = 1;
            for (row = 0; row < 16; row = row + 1) begin
                for (col = 0; col < 16; col = col + 1) begin
                    c_elem = C_flat[(row*16+col)*32 +: 32];
                    a_elem = A_test[(row*16+col)*16 +: 16];
                    c_expected_elem = {16'd0, a_elem};
                    if (c_elem !== c_expected_elem)
                        test_pass = 0;
                end
            end
            if (test_pass) begin
                $display("PASS: Test6 Sparse*Identity = Sparse");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Test6 Sparse*Identity != expected");
                fail_count = fail_count + 1;
            end
        end

        @(posedge clk);
        @(posedge clk);

        // =====================================================================
        // Test 7: Done signal deasserts after being asserted (check pulse behavior)
        // Re-apply reset and run again
        // =====================================================================
        rst = 1;
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 0;
        @(posedge clk);
        @(posedge clk);

        A_flat = identity_mat;
        B_flat = identity_mat;

        @(negedge clk);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        wait_for_done(500, timed_out);

        if (timed_out) begin
            $display("FAIL: Test7 Done after reset - timed out");
            fail_count = fail_count + 1;
        end else begin
            $display("PASS: Test7 done asserted after reset+start");
            pass_count = pass_count + 1;
        end

        @(posedge clk);
        @(posedge clk);

        // =====================================================================
        // Test 8: Small diagonal matrix: A[i][i] = i+1, B = Identity -> C = A
        // =====================================================================
        A
