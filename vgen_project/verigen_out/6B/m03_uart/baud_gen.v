// Baud rate clock divider. Outputs single-cycle tick every CLK_FREQ/BAUD_RATE clocks.
module baud_gen #(parameter CLK_FREQ=50000000, parameter BAUD_RATE=115200) (
    input  clk, rst,
    output tick
);
    localparam CLK_PER_BIT = CLK_FREQ/BAUD_RATE;
    reg [$clog2(CLK_PER_BIT)-1:0] counter=0;
    reg [2:0] state=0;
    reg [9:0] baud_cnt=0;
    assign tick = (counter==0);
    always @(posedge clk) begin
        if(rst) begin
            counter <= 0;
            state <= 0;
        end
        else begin
            counter <= counter+1;
            if(counter==CLK_PER_BIT-1) begin
                counter <= 0;
                if(state==0)
                    state <= 1;
                else
                    state <= 0;
                baud_cnt <= baud_cnt+1;
            end
            if(counter==(baud_cnt+1))
                baud_cnt <= 0;
        end
    end
endmodule
`timescale 1ns/1ps

module uart_tx #(parameter CLK_FREQ=50000000) (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0]  din,
    input  wire       trans_start,
    output reg        tx_done,
    output wire       uart_tx
);
    reg [3:0]   uart_data;
    reg         uart_start;
    reg [2:0]   uart_cnt;
    reg [9:0]   baud_cnt;
    reg [2:0]   data_cnt;
    reg [7:0]   data_buf;
    reg [2:0]   data_buf_cnt;
    reg [7:0]   data_buf_r;
    reg [2:0]   bit_cnt;
    reg [7:0]   bit_buf;
    reg [2:0]   bit_buf_cnt;
    reg [7:0]   bit_buf_r;
    reg [2:0]   parity_cnt;
    reg [7:0]   parity_buf;
    reg [2:0]   parity_buf_cnt;
    reg [7:0]   parity_buf_r;
    reg [2:0]   stop_cnt;
    reg [7:0]   stop_buf;
    reg [2:0]   stop_buf_cnt;
    reg [7:0]   stop_buf_r;
    reg [2:0]   trans_cnt;
    reg [7:0]   trans_buf;
    reg [2:0]   trans_buf_cnt;
    reg [7:0]   trans_buf_r;
    reg [2:0]   baud_cnt_r;
    reg [9:0]   baud_cnt_r1;
    reg [2:0]   baud_cnt_r2;
    reg [2:0]   baud_cnt_r3;
    reg [2:0]   baud_cnt_r4;
    reg [2:0]   baud_cnt_r5;
    reg [2:0]   baud_cnt_r6;
    reg [2:0]   baud_cnt_r7;
    reg [2:0]   baud_cnt_r8;
    reg [2:0]   baud_cnt_r9;
    reg [2:0]   baud_cnt_r10;
    reg [2:0]   baud_cnt_r11;
    reg [2:0]   baud_cnt_r12;
    reg [2:0]   baud_cnt_r13;
    reg [2:0]   baud_cnt_r14;
    reg [2:0]   baud_cnt_r15;
    reg [2:0]   baud_cnt_r16;
    reg [2:0]   baud_cnt_r17;
    reg [2:0]   baud_cnt_r18;
    reg [2:0]   baud_cnt_r19;
    reg [2:0]   baud_cnt_r20;
    reg [2:0]   baud_cnt_r21;
    reg [2:0]   baud_cnt_r22;
    reg [2:0]   baud_cnt_r23;
    reg [2:0]   baud_cnt_r24;
    reg [2:0]   baud_cnt_r25;
    reg [2:0]   baud_cnt_r26;
    reg [2:0]   baud_cnt_r27;
    reg [2:0]   baud_cnt_r28;
    reg [2:0]   baud_cnt_r29;
    reg [2:0]   baud_cnt_r30;
    reg [2:0]   baud_cnt_r31;
    reg [2:0]   baud_cnt_r32;
    reg [2:0]   baud_cnt_r33;
    reg [2:0]   baud_cnt_r34;
    reg [2:0]   baud_cnt_r35;
    reg [2:0]   baud_cnt_r36;
    reg [2:0]   baud_cnt_r37;
    reg [2:0]   baud_cnt_r38;
    reg [2:0]   baud_cnt_r39;
    reg [2:0]   baud_cnt_r40;
    reg [2:0]   baud_cnt_r41;
    reg [2:0]   baud_cnt_r42;
    reg [2:0]   baud_cnt_r43;
    reg [2:0]   baud_cnt_r44;
    reg [2:0]   baud_cnt_r45;
    reg [2:0]   baud_cnt_r46;
    reg [2:0]   baud_cnt_r47;
    reg [2:0]   baud_cnt_r48;
    reg [2:0]   baud_cnt_r49;
    reg [2:0]   baud_cnt_r50;
    reg [2:0]   baud_cnt_r51;
    reg [2:0]   baud_cnt_r52;
    reg [2:0]   baud_cnt_r53;
    reg [2:0]   baud_cnt_r54;
    reg [2:0]   baud_cnt_r55;
    reg [2:0]   baud_cnt_r56;
    reg [2:0]   baud_cnt_r57;
    reg [2:0]   baud_cnt_r58;
    reg [2:0]   baud_cnt_r59;
    reg [2:0]   baud_cnt_r60;
    reg [2:0]   baud_cnt_r61;
    reg [2:0]   baud_cnt_r62;
    reg [2:0]   baud_cnt_r63;
    reg [2:0]   baud_cnt_r64;
    reg [2:0]   baud_cnt_r65;
    reg [2:0]   baud_cnt_r66;
    reg [2:0]   baud_cnt_r67;
    reg [2:0]   baud_cnt_r68;
    reg [2:0]   baud_cnt_r69;
    reg [2:0]   baud_cnt_r70;
    reg [2:0]   baud_cnt_r71;
    reg [2:0]   baud
endmodule
