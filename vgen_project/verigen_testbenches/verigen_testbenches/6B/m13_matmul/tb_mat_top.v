`timescale 1ns/1ps

module tb_mat_top;

    // Clock and control
    reg clk, rst, start;
    
    // Matrix inputs (16x16 matrices of 16-bit unsigned values, row-major, flattened)
    // A_flat[4095:0]: A[0][0] in bits [15:0], A[0][1] in bits [31:16], etc.
    // (depends on module convention - we'll use row-major, element [i][j] at bits [16*(i*16+j)+15 : 16*(i*16+j)])
    reg  [4095:0] A_flat, B_flat;
    wire [8191:0] C_flat;
    wire          done;

    // DUT instantiation
    matrix_mult uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .A_flat(A_flat),
        .B_flat(B_flat),
        .C_flat(C_flat),
        .done(done)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Helper integers
    integer i, j, k;
    integer timeout;
    integer pass_count, fail_count;

    // Matrices stored as 16-bit elements
    reg [15:0] A_mat [0:15][0:15];
    reg [15:0] B_mat [0:15][0:15];
    reg [31:0] C_expected [0:15][0:15];
    reg [31:0] C_got [0:15][0:15];

    // Task to flatten A_mat into A_flat
    task flatten_A;
        integer ii, jj;
        begin
            for (ii = 0; ii < 16; ii = ii + 1)
                for (jj = 0; jj < 16; jj = jj + 1)
                    A_flat[16*(ii*16+jj) +: 16] = A_mat[ii][jj];
        end
    endtask

    // Task to flatten B_mat into B_flat
    task flatten_B;
        integer ii, jj;
        begin
            for (ii = 0; ii < 16; ii = ii + 1)
                for (jj = 0; jj < 16; jj = jj + 1)
                    B_flat[16*(ii*16+jj) +: 16] = B_mat[ii][jj];
        end
    endtask

    // Task to compute expected C = A * B
    task compute_expected;
        integer ii, jj, kk;
        reg [31:0] acc;
        begin
            for (ii = 0; ii < 16; ii = ii + 1)
                for (jj = 0; jj < 16; jj = jj + 1) begin
                    acc = 0;
                    for (kk = 0; kk < 16; kk = kk + 1)
                        acc = acc + A_mat[ii][kk] * B_mat[kk][jj];
                    C_expected[ii][jj] = acc;
                end
        end
    endtask

    // Task to extract C_got from C_flat
    task extract_C;
        integer ii, jj;
        begin
            for (ii = 0; ii < 16; ii = ii + 1)
                for (jj = 0; jj < 16; jj = jj + 1)
                    C_got[ii][jj] = C_flat[32*(ii*16+jj) +: 32];
        end
    endtask

    // Task to run one multiplication and check
    // test_name: string description
    task run_test;
        input [255:0] test_name;
        integer ii, jj;
        reg mismatch;
        begin
            // Apply matrices
            flatten_A;
            flatten_B;
            compute_expected;

            // Assert start
            @(posedge clk);
            #1;
            start = 1;
            @(posedge clk);
            #1;
            start = 0;

            // Wait for done with timeout
            timeout = 0;
            while (done !== 1'b1 && timeout < 1000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end

            // Extra cycle to let outputs settle
            @(posedge clk);
            #1;

            if (done !== 1'b1) begin
                $display("FAIL: %s - done never asserted (timeout)", test_name);
                fail_count = fail_count + 1;
            end else begin
                extract_C;
                mismatch = 0;
                for (ii = 0; ii < 16; ii = ii + 1)
                    for (jj = 0; jj < 16; jj = jj + 1)
                        if (C_got[ii][jj] !== C_expected[ii][jj])
                            mismatch = 1;
                if (mismatch) begin
                    $display("FAIL: %s - output mismatch", test_name);
                    fail_count = fail_count + 1;
                end else begin
                    $display("PASS: %s", test_name);
                    pass_count = pass_count + 1;
                end
            end

            // Wait a few cycles before next test
            repeat (5) @(posedge clk);
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

        // Reset for 5 rising edges
        repeat (5) @(posedge clk);
        #1;
        rst = 0;
        repeat (2) @(posedge clk);

        // ---------------------------------------------------------------
        // Test 1: Zero matrix * Zero matrix = Zero matrix
        // ---------------------------------------------------------------
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1) begin
                A_mat[i][j] = 0;
                B_mat[i][j] = 0;
            end
        run_test("Zero * Zero = Zero");

        // ---------------------------------------------------------------
        // Test 2: Identity * Identity = Identity
        // ---------------------------------------------------------------
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1) begin
                A_mat[i][j] = (i == j) ? 16'h0001 : 16'h0000;
                B_mat[i][j] = (i == j) ? 16'h0001 : 16'h0000;
            end
        run_test("Identity * Identity = Identity");

        // ---------------------------------------------------------------
        // Test 3: A * Identity = A  (A = all ones diagonal + 1 off-diag)
        // ---------------------------------------------------------------
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1) begin
                A_mat[i][j] = i + j + 1;  // small values
                B_mat[i][j] = (i == j) ? 16'h0001 : 16'h0000;
            end
        run_test("A * Identity = A");

        // ---------------------------------------------------------------
        // Test 4: Identity * B = B
        // ---------------------------------------------------------------
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1) begin
                A_mat[i][j] = (i == j) ? 16'h0001 : 16'h0000;
                B_mat[i][j] = (i + 1) * (j + 1);
            end
        run_test("Identity * B = B");

        // ---------------------------------------------------------------
        // Test 5: All-ones matrix * All-ones matrix
        //         C[i][j] = 16 (each row sum = 16 * 1 * 1 = 16)
        // ---------------------------------------------------------------
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1) begin
                A_mat[i][j] = 16'h0001;
                B_mat[i][j] = 16'h0001;
            end
        run_test("All-ones * All-ones");

        // ---------------------------------------------------------------
        // Test 6: Diagonal matrix * Diagonal matrix
        // ---------------------------------------------------------------
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1) begin
                A_mat[i][j] = (i == j) ? (i + 1) : 0;
                B_mat[i][j] = (i == j) ? (i + 2) : 0;
            end
        run_test("Diagonal * Diagonal");

        // ---------------------------------------------------------------
        // Test 7: Small values typical multiplication
        // ---------------------------------------------------------------
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1) begin
                A_mat[i][j] = (i * 16 + j) % 256;
                B_mat[i][j] = (j * 16 + i) % 256;
            end
        run_test("Typical small values A*B");

        // ---------------------------------------------------------------
        // Test 8: Max-value inputs (check for overflow/saturation behavior)
        // All elements = 0xFFFF
        // C[i][j] = 16 * 0xFFFF * 0xFFFF = 16 * 4294836225 (check lower 32 bits)
        // ---------------------------------------------------------------
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1) begin
                A_mat[i][j] = 16'hFFFF;
                B_mat[i][j] = 16'hFFFF;
            end
        run_test("Max-value all 0xFFFF");

        // ---------------------------------------------------------------
        // Test 9: Mixed: row i of A = i+1, col j of B = j+1 (rank-1)
        // ---------------------------------------------------------------
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1) begin
                A_mat[i][j] = i + 1;   // each row is constant
                B_mat[i][j] = j + 1;   // each col is constant
            end
        run_test("Rank-1 outer product");

        // ---------------------------------------------------------------
        // Test 10: A with alternating 0 and 1, B = Identity
        // ---------------------------------------------------------------
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1) begin
                A_mat[i][j] = ((i + j) % 2 == 0) ? 16'h0001 : 16'h0000;
                B_mat[i][j] = (i == j) ? 16'h0001 : 16'h0000;
            end
        run_test("Alternating 0/1 * Identity");

        // ---------------------------------------------------------------
        // Summary
        // ---------------------------------------------------------------
        $display("----------------------------------------");
        $display("Tests complete: PASS=%0d  FAIL=%0d", pass_count, fail_count);
        $display("----------------------------------------");
        $finish;
    end

endmodule
