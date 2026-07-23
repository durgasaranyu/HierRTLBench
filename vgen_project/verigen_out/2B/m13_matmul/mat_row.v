// Dot product of a 16-element row vector with a 16-element column vector.
// 16-bit unsigned elements. 32-bit accumulator. Takes 16 cycles after start.
module mat_row (
    input         clk, rst, start,
    input  [255:0] row_a_flat,
    input  [255:0] col_b_flat,
    output [31:0]  result,
    output         done
);
    // constant declaration
    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam CALC = 2'b10;
    localparam DONE = 2'b11;
    // signal declaration
    reg [1:0] state;
    reg [1:0] next_state;
    reg [255:0] a;
    reg [255:0] b;
    reg [31:0]  result;
    reg         done;
    // body
    //=================================================
    // start signal processing
    //=================================================
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            // reset
            state <= IDLE;
            next_state <= IDLE;
            a <= 0;
            b <= 0;
            result <= 0;
            done <= 0;
        end
        else begin
            state <= next_state;
            case (state)
                IDLE: begin
                    if (start) begin
                        a <= row_a_flat;
                        b <= col_b_flat;
                        next_state <= START;
                    end
                end
                START: begin
                    next_state <= CALC;
                end
                CALC: begin
                    result <= a * b;
                    next_state <= DONE;
                end
                DONE: begin
                    done <= 1;
                end
            endcase
        end
    end

endmodule
