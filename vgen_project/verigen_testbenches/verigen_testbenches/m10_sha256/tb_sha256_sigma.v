`timescale 1ns/1ps

module tb_sha256_sigma;

    // DUT inputs
    reg  [31:0] a, b, c;

    // DUT outputs
    wire [31:0] SIGMA0_a, SIGMA1_a, sigma0_b, sigma1_b, Ch_abc, Maj_abc;

    // Clock (not used by combinational DUT, but required by spec)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not used by combinational DUT, but required by spec)
    reg rst;
    integer rst_count;
    initial begin
        rst = 1;
        for (rst_count = 0; rst_count < 5; rst_count = rst_count + 1)
            @(posedge clk);
        rst = 0;
    end

    // Instantiate DUT
    sha256_sigma uut (
        .a       (a),
        .b       (b),
        .c       (c),
        .SIGMA0_a(SIGMA0_a),
        .SIGMA1_a(SIGMA1_a),
        .sigma0_b(sigma0_b),
        .sigma1_b(sigma1_b),
        .Ch_abc  (Ch_abc),
        .Maj_abc (Maj_abc)
    );

    // Helper registers for expected values
    reg [31:0] exp_SIGMA0, exp_SIGMA1, exp_sigma0, exp_sigma1, exp_Ch, exp_Maj;

    task apply_and_check;
        input [31:0] ta, tb, tc;
        input [255:0] desc; // 32 chars
        begin
            a = ta; b = tb; c = tc;
            #1; // let combinational logic settle

            // Expected values based on module implementation
            exp_SIGMA0 = {ta[31:24], tb[31:24], tc[31:24]};
            exp_SIGMA1 = {ta[23:16], tb[23:16], tc[23:16]};
            exp_sigma0 = {ta[15:8],  tb[15:8],  tc[15:8]};
            exp_sigma1 = {ta[7:0],   tb[7:0],   tc[7:0]};
            exp_Ch     = exp_SIGMA0 + exp_SIGMA1;
            exp_Maj    = exp_SIGMA0 * exp_SIGMA1;

            if (SIGMA0_a !== exp_SIGMA0) begin
                $display("FAIL: SIGMA0_a mismatch for %s: got %h, expected %h", desc, SIGMA0_a, exp_SIGMA0);
            end else if (SIGMA1_a !== exp_SIGMA1) begin
                $display("FAIL: SIGMA1_a mismatch for %s: got %h, expected %h", desc, SIGMA1_a, exp_SIGMA1);
            end else if (sigma0_b !== exp_sigma0) begin
                $display("FAIL: sigma0_b mismatch for %s: got %h, expected %h", desc, sigma0_b, exp_sigma0);
            end else if (sigma1_b !== exp_sigma1) begin
                $display("FAIL: sigma1_b mismatch for %s: got %h, expected %h", desc, sigma1_b, exp_sigma1);
            end else if (Ch_abc !== exp_Ch) begin
                $display("FAIL: Ch_abc mismatch for %s: got %h, expected %h", desc, Ch_abc, exp_Ch);
            end else if (Maj_abc !== exp_Maj) begin
                $display("FAIL: Maj_abc mismatch for %s: got %h, expected %h", desc, Maj_abc, exp_Maj);
            end else begin
                $display("PASS: %s", desc);
            end
        end
    endtask

    initial begin
        // Wait for reset deassertion
        a = 0; b = 0; c = 0;
        @(negedge rst); // wait until rst goes low
        @(posedge clk); #1;

        // Test 1: All zeros
        apply_and_check(32'h00000000, 32'h00000000, 32'h00000000, "All zeros");

        // Test 2: All ones
        apply_and_check(32'hFFFFFFFF, 32'hFFFFFFFF, 32'hFFFFFFFF, "All ones");

        // Test 3: a=0xDEADBEEF, b=0xCAFEBABE, c=0x12345678 (typical)
        apply_and_check(32'hDEADBEEF, 32'hCAFEBABE, 32'h12345678, "Typical values 1");

        // Test 4: a=0xABCDEF01, b=0x02030405, c=0x06070809
        apply_and_check(32'hABCDEF01, 32'h02030405, 32'h06070809, "Typical values 2");

        // Test 5: a=0x80000000, b=0x00000001, c=0x7FFFFFFF (boundary)
        apply_and_check(32'h80000000, 32'h00000001, 32'h7FFFFFFF, "Boundary test 1");

        // Test 6: a=0xFFFFFFFF, b=0x00000000, c=0xAAAAAAAA (mixed)
        apply_and_check(32'hFFFFFFFF, 32'h00000000, 32'hAAAAAAAA, "Mixed FF/00/AA");

        // Test 7: a=0x01010101, b=0x10101010, c=0x55555555
        apply_and_check(32'h01010101, 32'h10101010, 32'h55555555, "Pattern 01/10/55");

        // Test 8: a=0xFFFF0000, b=0x0000FFFF, c=0xFF00FF00
        apply_and_check(32'hFFFF0000, 32'h0000FFFF, 32'hFF00FF00, "Alternating half-words");

        // Test 9: Maximum values a=0xFFFFFFFF, b=0xFFFFFFFF, c=0x00000000
        apply_and_check(32'hFFFFFFFF, 32'hFFFFFFFF, 32'h00000000, "Max a,b zero c");

        // Test 10: a=0x12345678, b=0x9ABCDEF0, c=0x0F0F0F0F
        apply_and_check(32'h12345678, 32'h9ABCDEF0, 32'h0F0F0F0F, "Incrementing nibbles");

        $finish;
    end

endmodule
