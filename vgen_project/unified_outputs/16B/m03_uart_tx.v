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
    reg [1:0] state;
    reg [1:0] next_state;
    reg [4:0] baud_counter;
    reg [7:0] bit_counter;
    reg [7:0] shift_reg;
    // Set initial values
    initial begin
        state = IDLE;
        baud_counter = 0;
        bit_counter = 0;
        shift_reg = 0;
        busy = 0;
        tx = 1;
    end
    // FSM
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    // FSM next state logic
    always @* begin
        next_state = state;
        case (state)
            IDLE: begin
                if (load)
                    next_state = START;
            end
            START: begin
                if (baud_counter == BAUD_RATE/2 - 1)
                    next_state = DATA;
            end
            DATA: begin
                if (baud_counter == BAUD_RATE - 1)
                    next_state = STOP;
            end
            STOP: begin
                if (baud_counter == BAUD_RATE/2 - 1)
                    next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    // FSM output logic
    always @* begin
        case (state)
            IDLE: begin
                tx = 1;
                busy = 0;
            end
            START: begin
                tx = 0;
            end
            DATA: begin
                shift_reg[0] <= data_in[0];
                shift_reg[7:1] <= data_in[7:1];
                tx = shift_reg[0];
            end
            STOP: begin
                shift_reg[7:0] <= data_in[7:0];
                tx = shift_reg[0];
            end
            default: begin
                tx = 1;
                busy = 0;
            end
        endcase
    end
    // baud_counter
    always @(posedge clk) begin
        if (reset) begin
            baud_counter <= 0;
        end else begin
            if (baud_counter == BAUD_RATE/2 - 1) begin
                baud_counter <= 0;
                bit_counter <= bit_counter + 1;
                if (bit_counter == 8)
                    bit_counter <= 0;
            end else begin
                baud_counter <= baud_counter + 1;
            end
        end
    end

endmodule
