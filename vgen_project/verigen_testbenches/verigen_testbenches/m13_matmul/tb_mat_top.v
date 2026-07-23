`timescale 1ns/1ps

module tb_mat_top;

    // Parameters
    parameter CLK_PERIOD = 10;
    parameter N = 16;
    parameter A_BITS = 4096;  // 16*16*16
    parameter B_BITS = 4096;
    parameter C_BITS = 8192;  // 16*16*32

    // DUT connections
    reg clk;
    reg rst;
    reg start;
    reg  [A_BITS-1:0] A_flat;
    reg  [B_BITS-1:0] B_flat;
    wire [C_BITS-1:0] C_flat;
    wire              done;

    // Instantiate DUT
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

    // Test infrastructure
    integer i, j, k;
    integer pass_count, fail_count;
    integer timeout;

    // Matrix storage (16x16, 16-bit unsigned elements)
    reg [15:0] A_mat [0:15][0:15];
    reg [15:0] B_mat [0:15][0:15];
    reg [31:0] C_expected [0:15][0:15];
    reg [31:0] C_got [0:15][0:15];

    // Task: flatten A matrix to A_flat
    task flatten_A;
        integer r, c;
        begin
            for (r = 0; r < 16; r = r + 1)
                for (c = 0; c < 16; c = c + 1)
                    A_flat[(r*16+c)*16 +: 16] = A_mat[r][c];
        end
    endtask

    // Task: flatten B matrix to B_flat
    task flatten_B;
        integer r, c;
        begin
            for (r = 0; r < 16; r = r + 1)
                for (c = 0; c < 16; c = c + 1)
                    B_flat[(r*16+c)*16 +: 16] = B_mat[r][c];
        end
    endtask

    // Task: compute expected C = A*B
    task compute_expected;
        integer r, c, kk;
        reg [31:0] acc;
        begin
            for (r = 0; r < 16; r = r + 1)
                for (c = 0; c < 16; c = c + 1) begin
                    acc = 0;
                    for (kk = 0; kk < 16; kk = kk + 1)
                        acc = acc + A_mat[r][kk] * B_mat[kk][c];
                    C_expected[r][c] = acc;
                end
        end
    endtask

    // Task: extract C_flat to C_got
    task extract_C;
        integer r, c;
        begin
            for (r = 0; r < 16; r = r + 1)
                for (c = 0; c < 16; c = c + 1)
                    C_got[r][c] = C_flat[(r*16+c)*32 +: 32];
        end
    endtask

    // Task: check C result
    task check_result;
        input [255:0] test_name;
        integer r, c;
        reg pass;
        begin
            extract_C;
            pass = 1;
            for (r = 0; r < 16; r = r + 1)
                for (c = 0; c < 16; c = c + 1)
                    if (C_got[r][c] !== C_expected[r][c]) begin
                        pass = 0;
                        $display("  Mismatch at [%0d][%0d]: got %0d, expected %0d", r, c, C_got[r][c], C_expected[r][c]);
                    end
            if (pass) begin
                $display("PASS: %s", test_name);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: %s", test_name);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Task: run a matrix mult and wait for done
    task run_mult;
        input [255:0] test_name;
        begin
            // Apply start
            @(posedge clk); #1;
            start = 1;
            @(posedge clk); #1;
            start = 0;

            // Wait for done with timeout
            timeout = 0;
            while (!done && timeout < 1000) begin
                @(posedge clk); #1;
                timeout = timeout + 1;
            end

            if (timeout >= 1000) begin
                $display("FAIL: %s - TIMEOUT waiting for done", test_name);
                fail_count = fail_count + 1;
            end else begin
                check_result(test_name);
            end

            // Wait a couple cycles after done
            @(posedge clk); @(posedge clk);
        end
    endtask

    // Task: apply reset
    task apply_reset;
        integer i;
        begin
            rst = 1;
            start = 0;
            A_flat = 0;
            B_flat = 0;
            for (i = 0; i < 5; i = i + 1)
                @(posedge clk);
            #1;
            rst = 0;
            @(posedge clk);
        end
    endtask

    // Main test sequence
    initial begin
        pass_count = 0;
        fail_count = 0;
        rst   = 1;
        start = 0;
        A_flat = 0;
        B_flat = 0;

        // Apply reset for exactly 5 rising edges
        @(posedge clk); // 1
        @(posedge clk); // 2
        @(posedge clk); // 3
        @(posedge clk); // 4
        @(posedge clk); // 5
        #1;
        rst = 0;
        @(posedge clk);

        // =============================================
        // Test 1: Multiply by identity matrix
        // =============================================
        // Set A to a known matrix (row i, col j = i+j+1 mod 256)
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1)
                A_mat[i][j] = (i * 16 + j + 1) & 16'hFFFF;
        // Set B to identity
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1)
                B_mat[i][j] = (i == j) ? 16'd1 : 16'd0;
        flatten_A; flatten_B; compute_expected;
        run_mult("Multiply by identity matrix");

        // Apply reset between tests
        apply_reset;

        // =============================================
        // Test 2: All-zero A matrix (zero * anything = 0)
        // =============================================
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1) begin
                A_mat[i][j] = 16'd0;
                B_mat[i][j] = 16'hFFFF;
            end
        flatten_A; flatten_B; compute_expected;
        run_mult("All-zero A matrix");

        apply_reset;

        // =============================================
        // Test 3: All-zero B matrix
        // =============================================
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1) begin
                A_mat[i][j] = 16'h1234;
                B_mat[i][j] = 16'd0;
            end
        flatten_A; flatten_B; compute_expected;
        run_mult("All-zero B matrix");

        apply_reset;

        // =============================================
        // Test 4: Identity * Identity = Identity
        // =============================================
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1) begin
                A_mat[i][j] = (i == j) ? 16'd1 : 16'd0;
                B_mat[i][j] = (i == j) ? 16'd1 : 16'd0;
            end
        flatten_A; flatten_B; compute_expected;
        run_mult("Identity times Identity");

        apply_reset;

        // =============================================
        // Test 5: All-ones matrices
        // =============================================
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1) begin
                A_mat[i][j] = 16'd1;
                B_mat[i][j] = 16'd1;
            end
        flatten_A; flatten_B; compute_expected;
        run_mult("All-ones matrices (C[i][j]=16)");

        apply_reset;

        // =============================================
        // Test 6: Small values (row [1..16] dot [1..16])
        // A = diagonal matrix with values 1..16
        // B = identity
        // =============================================
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1) begin
                A_mat[i][j] = (i == j) ? (i + 1) : 16'd0;
                B_mat[i][j] = (i == j) ? 16'd1 : 16'd0;
            end
        flatten_A; flatten_B; compute_expected;
        run_mult("Diagonal A (1..16) times Identity");

        apply_reset;

        // =============================================
        // Test 7: Maximum 16-bit values for a few elements
        // =============================================
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1) begin
                A_mat[i][j] = 16'd0;
                B_mat[i][j] = 16'd0;
            end
        // Single element A[0][0] = 0xFFFF, B[0][0] = 0xFFFF => C[0][0] = 0xFFFE0001
        A_mat[0][0] = 16'hFFFF;
        B_mat[0][0] = 16'hFFFF;
        flatten_A; flatten_B; compute_expected;
        run_mult("Max value single element (0xFFFF * 0xFFFF)");

        apply_reset;

        // =============================================
        // Test 8: Row vector times column vector
        // A[0][j] = j+1, rest zero; B[i][0] = i+1, rest zero
        // C[0][0] = sum(i=0..15)(i+1)^2
        // =============================================
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1) begin
                A_mat[i][j] = 16'd0;
                B_mat[i][j] = 16'd0;
            end
        for (j = 0; j < 16; j = j + 1)
            A_mat[0][j] = j + 1;
        for (i = 0; i < 16; i = i + 1)
            B_mat[i][0] = i + 1;
        flatten_A; flatten_B; compute_expected;
        run_mult("Row x Column vector (sum of squares 1..16)");

        apply_reset;

        // =============================================
        // Test 9: Done signal check - re-test with identity
        // =============================================
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1) begin
                A_mat[i][j] = (i == j) ? 16'd5 : 16'd0;
                B_mat[i][j] = (i == j) ? 16'd3 : 16'd0;
            end
        flatten_A; flatten_B; compute_expected;

        @(posedge clk); #1;
        start = 1;
        @(posedge clk); #1;
        start = 0;

        // Wait for done
        timeout = 0;
        while (!done && timeout < 1000) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end

        if (timeout >= 1000) begin
            $display("FAIL: Done signal test - TIMEOUT");
            fail_count = fail_count + 1;
        end else begin
            // Check done asserted
            if (done) begin
                $display("PASS: Done signal asserted correctly");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Done signal not asserted");
                fail_count = fail_count + 1;
            end
            check_result("Diagonal 5*3 result check");
        end

        @(posedge clk); @(posedge clk);

        // =============================================
        // Summary
        // =============================================
        $display("==============================");
        $display("Test Summary: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("==============================");

        $finish;
    end

endmodule
