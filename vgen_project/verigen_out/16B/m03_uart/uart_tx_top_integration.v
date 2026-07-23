`timescale 1ns/1ps
// M03: UART TX integration top (8-N-1)
// Instantiates baud_gen, uart_tx_fsm, uart_tx_shift.
// baud_gen  → tick → uart_tx_fsm (load, shift_en, tx_out, busy)
// uart_tx_shift holds the byte; FSM controls load/shift timing.
module uart_tx_integration #(
    parameter CLK_FREQ  = 50000000,
    parameter BAUD_RATE = 115200
) (
    input        clk, rst, tx_start,
    input  [7:0] tx_data,
    output       tx, busy
);
    wire tick, load, shift_en, tx_out, busy_w, serial_out, empty;

    baud_gen #(
        .CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)
    ) u_baud (
        .clk(clk), .rst(rst), .tick(tick)
    );

    uart_tx_shift u_shift (
        .clk(clk), .rst(rst),
        .load(load), .shift_en(shift_en),
        .data(tx_data),
        .serial_out(serial_out),
        .empty(empty)
    );

    uart_tx_fsm u_fsm (
        .clk(clk), .rst(rst),
        .tick(tick), .tx_start(tx_start),
        .load(load), .shift_en(shift_en),
        .tx_out(tx_out), .busy(busy_w)
    );

    // FSM drives tx_out (start=0, data bits, stop=1)
    assign tx   = tx_out;
    assign busy = busy_w;
endmodule
