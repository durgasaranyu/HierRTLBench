// UART transmitter: 8-N-1 format (8 data bits, no parity, 1 stop bit)
// System clock frequency: CLK_FREQ Hz (parameter)
// Baud rate: BAUD_RATE bps (parameter)
// Baud clock divider = CLK_FREQ / BAUD_RATE
// tx idles HIGH. Start bit = LOW. Stop bit = HIGH.
// Data bits transmitted LSB first.
// Load new byte on load=1 when idle (busy=0)
// busy=1 while transmitting; busy=0 when idle
module uart_tx #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 9600
) (
    input  wire        clk,
    input  wire        reset,
    input  wire        load,
    input  wire [7:0]  data_in,
    output reg         tx,
    output reg         busy
);
    // FSM states: IDLE, START, DATA (8 bits), STOP
    // Use a baud_counter counting up to CLK_FREQ/BAUD_RATE-1
    // Use a bit_counter 0..7 for the 8 data bits
    // Shift register: load data_in, shift right each baud tick
    reg [7:0] data_shift;
    reg [7:0] data_shift_next;
    reg [2:0] bit_counter;
    reg [2:0] bit_counter_next;
    reg [7:0] data_out;
    reg [7:0] data_out_next;
    reg [7:0] data_out_reg;
    reg [7:0] data_out_reg_next;
    reg [7:0] data_out_reg_reg;
    reg [7:0] data_out_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg;
    reg [7:0] data_out_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg;
    reg [7:0] data_out_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data_out_reg_reg_reg_reg_reg_next;
    reg [7:0] data
endmodule
