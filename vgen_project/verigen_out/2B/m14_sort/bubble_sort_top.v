// Hardware bubble sort top. 8 elements, 8-bit unsigned. FSM IDLE/LOAD/SORT/DONE.
// One compare-swap per clock cycle. done asserts when sorted.
module bubble_sort (
    input        clk, rst, start,
    input  [63:0] data_in_flat,
    output [63:0] data_out_flat,
    output        done
);
    // input registers
    reg [63:0] data_in_reg [0:7];
    reg [63:0] data_out_reg [0:7];
    reg [7:0]  done_reg;
    // output registers
    reg [63:0] data_out_reg_0;
    reg [63:0] data_out_reg_1;
    reg [63:0] data_out_reg_2;
    reg [63:0] data_out_reg_3;
    reg [63:0] data_out_reg_4;
    reg [63:0] data_out_reg_5;
    reg [63:0] data_out_reg_6;
    reg [63:0] data_out_reg_7;
    // output flip-flops
    assign data_out_flat = data_out_reg[0];
    assign done = done_reg;
    // registers
    always @(posedge clk) begin
        if (rst) begin
            data_in_reg[0] <= 0;
            data_in_reg[1] <= 0;
            data_in_reg[2] <= 0;
            data_in_reg[3] <= 0;
            data_in_reg[4] <= 0;
            data_in_reg[5] <= 0;
            data_in_reg[6] <= 0;
            data_in_reg[7] <= 0;
            done_reg <= 0;
        end else begin
            if (start) begin
                data_in_reg[0] <= data_in_reg[1];
                data_in_reg[1] <= data_in_reg[2];
                data_in_reg[2] <= data_in_reg[3];
                data_in_reg[3] <= data_in_reg[4];
                data_in_reg[4] <= data_in_reg[5];
                data_in_reg[5] <= data_in_reg[6];
                data_in_reg[6] <= data_in_reg[7];
                data_in_reg[7] <= data_in_reg[0];
                done_reg <= 0;
            end else begin
                data_in_reg[0] <= data_in_reg[1];
                data_in_reg[1] <= data_in_reg[2];
                data_in_reg[2] <= data_in_reg[3];
                data_in_reg[3] <= data_in_reg[4];
                data_in_reg[4] <= data_in_reg[5];
                data_in_reg[5] <= data_in_reg[6];
                data_in_reg[6] <= data_in_reg[7];
                data_in_reg[7] <= data_in_reg[0];
                done_reg <= done_reg + 1;
            end
        end
    end
    always @(posedge clk) begin
        data_out_reg[0] <= data_out_reg_0;
        data_out_reg[1] <= data_out_reg_1;
        data_out_reg[2] <= data_out_reg_2;
        data_out_reg[3] <= data_out_reg_3;
        data_out_reg[4] <= data_out_reg_4;
        data_out_reg[5] <= data_out_reg_5;
        data_out_reg[6] <= data_out_reg_6;
        data_out_reg[7] <= data_out_reg_7;
    end
    always @(posedge clk) begin
        data_out_reg_0 <= data_out_reg[0];
        data_out_reg_1 <= data_out_reg[1];
        data_out_reg_2 <= data_out_reg[2];
        data_out_reg_3 <= data_out_reg[3];
        data_out_reg_4 <= data_out_reg[4];
        data_out_reg_5 <= data_out_reg[5];
        data_out_reg_6 <= data_out_reg[6];
        data_out_reg_7 <= data_out_reg[7];
    end

endmodule
