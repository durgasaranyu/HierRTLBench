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
    // Count STOP bit
    reg [3:0] state, next_state;
    reg [4:0] baud_counter;
    reg [2:0] bit_counter;
    reg [7:0] data_shift;
    always @(*) begin
        case (state)
            IDLE: next_state = load? START : IDLE;
            START: next_state = DATA;
            DATA: next_state = (bit_counter == 0)? STOP : DATA;
            STOP: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            baud_counter <= 0;
            bit_counter <= 0;
            data_shift <= 0;
            tx <= 1'b1;
        end
        else begin
            state <= next_state;
            if (state == START) begin
                baud_counter <= 0;
                bit_counter <= 0;
                data_shift <= {data_in, data_shift[7:1]};
            end
            else if (state == DATA) begin
                baud_counter <= baud_counter + 1;
                if (baud_counter == baud_rate - 1) begin
                    baud_counter <= 0;
                    if (bit_counter == 7) begin
                        bit_counter <= 0;
                        tx <= 1'b0;
                    end
                    else begin
                        bit_counter <= bit_counter + 1;
                        tx <= data_shift[bit_counter];
                    end
                end
            end
            else if (state == STOP) begin
                baud_counter <= baud_counter + 1;
                if (baud_counter == baud_rate - 1) begin
                    baud_counter <= 0;
                    tx <= 1'b1;
                end
            end
        end
    end
    assign busy = (state!= IDLE);

endmodule
