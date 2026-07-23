// UART TX FSM. States: IDLE->START->DATA(8 bits)->STOP->IDLE. Driven by baud tick.
module uart_tx_fsm (
    input      clk, rst, tick, tx_start,
    output reg load, shift_en, tx_out, busy
);
    localparam IDLE = 2'b00,
                START = 2'b01,
                DATA  = 2'b10,
                STOP  = 2'b11;
    reg [1:0] state, next_state;
    reg [7:0] data;
    reg [3:0] bit_count;
    reg [7:0] tx_byte;
    always @(*) begin
        case (state)
            IDLE: begin
                load = 1'b0;
                shift_en = 1'b0;
                tx_out = 1'b0;
                if (tx_start) begin
                    next_state = START;
                end else begin
                    next_state = IDLE;
                end
            end
            START: begin
                load = 1'b1;
                tx_out = 1'b1;
                if (bit_count == 0) begin
                    next_state = DATA;
                end else begin
                    next_state = START;
                end
            end
            DATA: begin
                load = 1'b0;
                shift_en = 1'b1;
                if (bit_count == 0) begin
                    next_state = STOP;
                end else begin
                    next_state = DATA;
                end
            end
            STOP: begin
                load = 1'b0;
                tx_out = 1'b0;
                if (bit_count == 0) begin
                    next_state = IDLE;
                end else begin
                    next_state = STOP;
                end
            end
            default: next_state = IDLE;
        endcase
    end
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            bit_count <= 0;
            data <= 0;
            tx_byte <= 0;
        end else begin
            state <= next_state;
            bit_count <= bit_count - 1;
            if (load) begin
                data <= tx_byte;
            end
            if (shift_en) begin
                tx_byte <= {tx_byte[6:0], 1'b0};
            end
        end
    end

endmodule
