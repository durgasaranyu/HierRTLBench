// UART TX FSM. States: IDLE->START->DATA(8 bits)->STOP->IDLE. Driven by baud tick.
module uart_tx_fsm (
    input      clk, rst, tick, tx_start,
    output reg load, shift_en, tx_out, busy
);
    localparam  IDLE   = 4'd0,
                START  = 4'd1,
                DATA   = 4'd2,
                STOP   = 4'd3;
    reg [3:0] state, next_state;
    always @(*) begin
        next_state = IDLE;
        load = 1'b0;
        shift_en = 1'b0;
        tx_out = 1'b1;
        busy = 1'b0;
        case (state)
            IDLE : begin
                if (tick)
                    next_state = START;
            end
            START : begin
                load = 1'b1;
                if (load_tick)
                    next_state = DATA;
            end
            DATA : begin
                shift_en = 1'b1;
                if (shift_tick)
                    next_state = STOP;
            end
            STOP : begin
                tx_out = 1'b0;
                if (one_baud_tick)
                    next_state = IDLE;
            end
            default : next_state = IDLE;
        endcase
    end
    always @(posedge clk) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

endmodule
