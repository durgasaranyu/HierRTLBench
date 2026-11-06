`timescale 1ns/1ps

module tb_bubble_sort_top;

    // ---------- DUT connections ----------
    reg         clk;
    reg         rst;
    reg         start;
    reg  [63:0] data_in_flat;
    wire [63:0] data_out_flat;
    wire        done;

    // ---------- DUT instantiation ----------
    bubble_sort uut (
        .clk          (clk),
        .rst          (rst),
        .start        (start),
        .data_in_flat (data_in_flat),
        .data_out_flat(data_out_flat),
        .done         (done)
    );

    // ---------- clock ----------
    initial clk = 0;
    always #5 clk = ~clk;

    // ---------- helper integers ----------
    integer i;
    integer timeout;
    integer pass_count;
    integer fail_count;

    // Helper task: pack 8 x 8-bit values into a 64-bit flat word
    // byte0 -> bits[7:0], byte7 -> bits[63:56]
    task pack_array;
        input [7:0] b0,b1,b2,b3,b4,b5,b6,b7;
        output [63:0] flat;
        begin
            flat = {b7,b6,b5,b4,b3,b2,b1,b0};
        end
    endtask

    // Helper: extract element i (0=LSB side) from flat
    function [7:0] get_elem;
        input [63:0] flat;
        input [2:0]  idx;
        begin
            get_elem = flat[idx*8 +: 8];
        end
    endfunction

    // Helper: check sorted ascending (element 0 = smallest)
    function check_sorted;
        input [63:0] flat;
        input [7:0] e0,e1,e2,e3,e4,e5,e6,e7;
        begin
            check_sorted = (flat[7:0]   == e0) &&
                           (flat[15:8]  == e1) &&
                           (flat[23:16] == e2) &&
                           (flat[31:24] == e3) &&
                           (flat[39:32] == e4) &&
                           (flat[47:40] == e5) &&
                           (flat[55:48] == e6) &&
                           (flat[63:56] == e7);
        end
    endfunction

    // Task: apply reset for 5 rising edges
    task apply_reset;
        begin
            rst   = 1;
            start = 0;
            repeat(5) @(posedge clk);
            @(negedge clk);
            rst = 0;
        end
    endtask

    // Task: wait for done or timeout
    task wait_done;
        input integer max_cycles;
        output timed_out;
        begin
            timed_out = 0;
            timeout   = 0;
            while (!done && timeout < max_cycles) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if (timeout >= max_cycles)
                timed_out = 1;
        end
    endtask

    reg timed_out;

    initial begin
        pass_count = 0;
        fail_count = 0;

        // ============================================================
        // RESET
        // ============================================================
        rst          = 1;
        start        = 0;
        data_in_flat = 64'h0;
        repeat(5) @(posedge clk);
        @(negedge clk);
        rst = 0;

        // ============================================================
        // TEST 1: All-zeros input
        // ============================================================
        @(negedge clk);
        pack_array(8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,
                   data_in_flat);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;
        wait_done(500, timed_out);
        if (!timed_out && done &&
            check_sorted(data_out_flat,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00)) begin
            $display("PASS: All-zeros input sorted correctly");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: All-zeros input. done=%b timed_out=%b out=%h",
                      done, timed_out, data_out_flat);
            fail_count = fail_count + 1;
        end

        // ============================================================
        // RESET before next test
        // ============================================================
        apply_reset;

        // ============================================================
        // TEST 2: All-ones (0xFF) input
        // ============================================================
        @(negedge clk);
        pack_array(8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,
                   data_in_flat);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;
        wait_done(500, timed_out);
        if (!timed_out && done &&
            check_sorted(data_out_flat,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF,8'hFF)) begin
            $display("PASS: All-0xFF input sorted correctly");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: All-0xFF input. done=%b timed_out=%b out=%h",
                      done, timed_out, data_out_flat);
            fail_count = fail_count + 1;
        end

        apply_reset;

        // ============================================================
        // TEST 3: [5,1,4,2,8,3,7,6] -> [1,2,3,4,5,6,7,8]
        // ============================================================
        @(negedge clk);
        pack_array(8'd5,8'd1,8'd4,8'd2,8'd8,8'd3,8'd7,8'd6,
                   data_in_flat);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;
        wait_done(500, timed_out);
        if (!timed_out && done &&
            check_sorted(data_out_flat,8'd1,8'd2,8'd3,8'd4,8'd5,8'd6,8'd7,8'd8)) begin
            $display("PASS: [5,1,4,2,8,3,7,6] -> [1,2,3,4,5,6,7,8]");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: [5,1,4,2,8,3,7,6] sort. done=%b timed_out=%b out=%h",
                      done, timed_out, data_out_flat);
            fail_count = fail_count + 1;
        end

        apply_reset;

        // ============================================================
        // TEST 4: Already sorted [1,2,3,4,5,6,7,8]
        // ============================================================
        @(negedge clk);
        pack_array(8'd1,8'd2,8'd3,8'd4,8'd5,8'd6,8'd7,8'd8,
                   data_in_flat);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;
        wait_done(500, timed_out);
        if (!timed_out && done &&
            check_sorted(data_out_flat,8'd1,8'd2,8'd3,8'd4,8'd5,8'd6,8'd7,8'd8)) begin
            $display("PASS: Already-sorted [1..8] completes correctly");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Already-sorted input. done=%b timed_out=%b out=%h",
                      done, timed_out, data_out_flat);
            fail_count = fail_count + 1;
        end

        apply_reset;

        // ============================================================
        // TEST 5: Reverse sorted [8,7,6,5,4,3,2,1]
        // ============================================================
        @(negedge clk);
        pack_array(8'd8,8'd7,8'd6,8'd5,8'd4,8'd3,8'd2,8'd1,
                   data_in_flat);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;
        wait_done(500, timed_out);
        if (!timed_out && done &&
            check_sorted(data_out_flat,8'd1,8'd2,8'd3,8'd4,8'd5,8'd6,8'd7,8'd8)) begin
            $display("PASS: Reverse-sorted [8..1] -> [1..8]");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Reverse-sorted input. done=%b timed_out=%b out=%h",
                      done, timed_out, data_out_flat);
            fail_count = fail_count + 1;
        end

        apply_reset;

        // ============================================================
        // TEST 6: Max-value elements [0xFF,0xFE,0xFD,0xFC,0xFB,0xFA,0xF9,0xF8]
        // ============================================================
        @(negedge clk);
        pack_array(8'hFF,8'hFE,8'hFD,8'hFC,8'hFB,8'hFA,8'hF9,8'hF8,
                   data_in_flat);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;
        wait_done(500, timed_out);
        if (!timed_out && done &&
            check_sorted(data_out_flat,8'hF8,8'hF9,8'hFA,8'hFB,8'hFC,8'hFD,8'hFE,8'hFF)) begin
            $display("PASS: Max-range [FF..F8] sorted correctly");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Max-range input. done=%b timed_out=%b out=%h",
                      done, timed_out, data_out_flat);
            fail_count = fail_count + 1;
        end

        apply_reset;

        // ============================================================
        // TEST 7: Duplicate values [3,3,1,1,2,2,0,0]
        // ============================================================
        @(negedge clk);
        pack_array(8'd3,8'd3,8'd1,8'd1,8'd2,8'd2,8'd0,8'd0,
                   data_in_flat);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;
        wait_done(500, timed_out);
        if (!timed_out && done &&
            check_sorted(data_out_flat,8'd0,8'd0,8'd1,8'd1,8'd2,8'd2,8'd3,8'd3)) begin
            $display("PASS: Duplicates [3,3,1,1,2,2,0,0] -> [0,0,1,1,2,2,3,3]");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Duplicates input. done=%b timed_out=%b out=%h",
                      done, timed_out, data_out_flat);
            fail_count = fail_count + 1;
        end

        apply_reset;

        // ============================================================
        // TEST 8: Single distinct max and min [0,255,128,64,32,16,8,4]
        // ============================================================
        @(negedge clk);
        pack_array(8'd0,8'd255,8'd128,8'd64,8'd32,8'd16,8'd8,8'd4,
                   data_in_flat);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;
        wait_done(500, timed_out);
        if (!timed_out && done &&
            check_sorted(data_out_flat,8'd0,8'd4,8'd8,8'd16,8'd32,8'd64,8'd128,8'd255)) begin
            $display("PASS: [0,255,128,64,32,16,8,4] -> [0,4,8,16,32,64,128,255]");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Mixed input. done=%b timed_out=%b out=%h",
                      done, timed_out, data_out_flat);
            fail_count = fail_count + 1;
        end

        apply_reset;

        // ============================================================
        // TEST 9: FSM IDLE state - done should NOT assert before start
        // ============================================================
        @(negedge clk);
        // After reset, we are in IDLE; done should be 0 without start
        pack_array(8'd10,8'd20,8'd5,8'd15,8'd25,8'd1,8'd30,8'd3,
                   data_in_flat);
        // Do NOT assert start; wait a few cycles
        repeat(10) @(posedge clk);
        if (!done) begin
            $display("PASS: FSM stays in IDLE (done=0) without start");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: FSM should be IDLE but done=%b", done);
            fail_count = fail_count + 1;
        end

        // Now assert start and check sorting completes (IDLE->LOAD->SORT->DONE)
        @(negedge clk);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;
        wait_done(500, timed_out);
        if (!timed_out && done &&
            check_sorted(data_out_flat,8'd1,8'd3,8'd5,8'd10,8'd15,8'd20,8'd25,8'd30)) begin
            $display("PASS: FSM IDLE->LOAD->SORT->DONE, [10,20,5,15,25,1,30,3] -> [1,3,5,10,15,20,25,30]");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: FSM full flow. done=%b timed_out=%b out=%h",
                      done, timed_out, data_out_flat);
            fail_count = fail_count + 1;
        end

        apply_reset;

        // ============================================================
        // SUMMARY
        // ============================================================
        $display("--------------------------------------");
        $display("Results: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("--------------------------------------");

        $finish;
    end

endmodule
