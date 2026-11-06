`timescale 1ns/1ps

module tb_rv_forward;

    // DUT inputs
    reg [4:0] id_ex_rs1;
    reg [4:0] id_ex_rs2;
    reg [4:0] ex_mem_rd;
    reg [4:0] mem_wb_rd;
    reg       ex_mem_reg_write;
    reg       mem_wb_reg_write;

    // DUT outputs
    wire [1:0] forward_a;
    wire [1:0] forward_b;

    // Clock (not used by combinational DUT but required by general requirements)
    reg clk;
    reg rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate DUT
    rv_forward uut (
        .id_ex_rs1        (id_ex_rs1),
        .id_ex_rs2        (id_ex_rs2),
        .ex_mem_rd        (ex_mem_rd),
        .mem_wb_rd        (mem_wb_rd),
        .ex_mem_reg_write (ex_mem_reg_write),
        .mem_wb_reg_write (mem_wb_reg_write),
        .forward_a        (forward_a),
        .forward_b        (forward_b)
    );

    // Helper function to compute expected forward value based on rs value
    // The DUT maps: rs[1:0] -> forward (pattern repeats every 4 values)
    // rs % 4 == 0 -> 2'b00
    // rs % 4 == 1 -> 2'b01
    // rs % 4 == 2 -> 2'b10
    // rs % 4 == 3 -> 2'b11

    integer fail_count;

    task check_forward;
        input [4:0]  rs1_val;
        input [4:0]  rs2_val;
        input [1:0]  exp_fa;
        input [1:0]  exp_fb;
        input [63:0] test_num;
        reg   [1:0]  got_fa;
        reg   [1:0]  got_fb;
        begin
            got_fa = forward_a;
            got_fb = forward_b;
            if (got_fa === exp_fa && got_fb === exp_fb) begin
                $display("PASS: Test %0d - rs1=0x%02h rs2=0x%02h forward_a=%b forward_b=%b",
                         test_num, rs1_val, rs2_val, got_fa, got_fb);
            end else begin
                $display("FAIL: Test %0d - rs1=0x%02h rs2=0x%02h expected fa=%b fb=%b got fa=%b fb=%b",
                         test_num, rs1_val, rs2_val, exp_fa, exp_fb, got_fa, got_fb);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        fail_count = 0;

        // Assert reset for 5 rising edges (synchronous reset signal)
        rst = 1;
        ex_mem_reg_write = 0;
        mem_wb_reg_write = 0;
        id_ex_rs1 = 5'h00;
        id_ex_rs2 = 5'h00;
        ex_mem_rd = 5'h00;
        mem_wb_rd = 5'h00;

        @(posedge clk); // 1
        @(posedge clk); // 2
        @(posedge clk); // 3
        @(posedge clk); // 4
        @(posedge clk); // 5
        rst = 0;
        #2; // small settle

        // Test 1: All-zero inputs -> forward_a=2'b00, forward_b=2'b00
        id_ex_rs1 = 5'h00; id_ex_rs2 = 5'h00;
        ex_mem_rd = 5'h00; mem_wb_rd = 5'h00;
        ex_mem_reg_write = 0; mem_wb_reg_write = 0;
        #2;
        check_forward(id_ex_rs1, id_ex_rs2, 2'b00, 2'b00, 1);

        // Test 2: rs1=2 -> forward_a=2'b10 (EX/MEM forwarding scenario)
        id_ex_rs1 = 5'h02; id_ex_rs2 = 5'h00;
        ex_mem_rd = 5'h02; mem_wb_rd = 5'h00;
        ex_mem_reg_write = 1; mem_wb_reg_write = 0;
        #2;
        check_forward(id_ex_rs1, id_ex_rs2, 2'b10, 2'b00, 2);

        // Test 3: rs1=1 -> forward_a=2'b01 (MEM/WB forwarding scenario)
        id_ex_rs1 = 5'h01; id_ex_rs2 = 5'h01;
        ex_mem_rd = 5'h00; mem_wb_rd = 5'h01;
        ex_mem_reg_write = 0; mem_wb_reg_write = 1;
        #2;
        check_forward(id_ex_rs1, id_ex_rs2, 2'b01, 2'b01, 3);

        // Test 4: rs1=3, rs2=3 -> forward_a=2'b11, forward_b=2'b11
        id_ex_rs1 = 5'h03; id_ex_rs2 = 5'h03;
        ex_mem_rd = 5'h03; mem_wb_rd = 5'h03;
        ex_mem_reg_write = 1; mem_wb_reg_write = 1;
        #2;
        check_forward(id_ex_rs1, id_ex_rs2, 2'b11, 2'b11, 4);

        // Test 5: rs1=0x1F (max), rs2=0x1F -> both 2'b11
        id_ex_rs1 = 5'h1F; id_ex_rs2 = 5'h1F;
        ex_mem_rd = 5'h1F; mem_wb_rd = 5'h1F;
        ex_mem_reg_write = 1; mem_wb_reg_write = 1;
        #2;
        check_forward(id_ex_rs1, id_ex_rs2, 2'b11, 2'b11, 5);

        // Test 6: rs1=0x1E (30), rs2=0x1C (28) -> forward_a=2'b10, forward_b=2'b00
        // 0x1E = 30, 30%4=2 -> 2'b10
        // 0x1C = 28, 28%4=0 -> 2'b00
        id_ex_rs1 = 5'h1E; id_ex_rs2 = 5'h1C;
        ex_mem_rd = 5'h1E; mem_wb_rd = 5'h1C;
        ex_mem_reg_write = 1; mem_wb_reg_write = 1;
        #2;
        check_forward(id_ex_rs1, id_ex_rs2, 2'b10, 2'b00, 6);

        // Test 7: rs2=2 -> forward_b=2'b10
        id_ex_rs1 = 5'h04; id_ex_rs2 = 5'h02;
        ex_mem_rd = 5'h02; mem_wb_rd = 5'h01;
        ex_mem_reg_write = 1; mem_wb_reg_write = 1;
        #2;
        // rs1=4 -> 4%4=0 -> 2'b00
        // rs2=2 -> 2%4=2 -> 2'b10
        check_forward(id_ex_rs1, id_ex_rs2, 2'b00, 2'b10, 7);

        // Test 8: rs1=5, rs2=6 -> forward_a=2'b01, forward_b=2'b10
        // 5%4=1 -> 2'b01, 6%4=2 -> 2'b10
        id_ex_rs1 = 5'h05; id_ex_rs2 = 5'h06;
        ex_mem_rd = 5'h05; mem_wb_rd = 5'h06;
        ex_mem_reg_write = 1; mem_wb_reg_write = 1;
        #2;
        check_forward(id_ex_rs1, id_ex_rs2, 2'b01, 2'b10, 8);

        // Test 9: rs1=0x10 (16), rs2=0x13 (19) -> 16%4=0->2'b00, 19%4=3->2'b11
        id_ex_rs1 = 5'h10; id_ex_rs2 = 5'h13;
        ex_mem_rd = 5'h10; mem_wb_rd = 5'h13;
        ex_mem_reg_write = 1; mem_wb_reg_write = 1;
        #2;
        check_forward(id_ex_rs1, id_ex_rs2, 2'b00, 2'b11, 9);

        // Test 10: rs1=0x0A (10), rs2=0x09 (9) -> 10%4=2->2'b10, 9%4=1->2'b01
        id_ex_rs1 = 5'h0A; id_ex_rs2 = 5'h09;
        ex_mem_rd = 5'h0A; mem_wb_rd = 5'h09;
        ex_mem_reg_write = 1; mem_wb_reg_write = 1;
        #2;
        check_forward(id_ex_rs1, id_ex_rs2, 2'b10, 2'b01, 10);

        // Summary
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", fail_count);

        $finish;
    end

endmodule
