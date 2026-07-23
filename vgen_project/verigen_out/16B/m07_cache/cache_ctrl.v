// Write-through cache controller FSM. States: IDLE, COMPARE, MEM_FETCH, WRITE_BACK.
// Address: tag[31:6], index[5:2], offset[1:0].
module cache_ctrl (
    input        clk, rst, cpu_req, mem_ack, hit, cpu_we,
    output reg   we_tag, we_data, mem_req, mem_we, stall
);
    parameter IDLE = 2'b00, FETCH = 2'b01, COMPARE = 2'b10, WRITE_BACK = 2'b11;
    reg [1:0] state, next_state;
    always @(*) begin
        case (state)
            IDLE: begin
                if (cpu_req) next_state = FETCH;
                else next_state = IDLE;
            end
            FETCH: begin
                if (hit) next_state = COMPARE;
                else next_state = FETCH;
            end
            COMPARE: begin
                if (hit) next_state = WRITE_BACK;
                else next_state = IDLE;
            end
            WRITE_BACK: begin
                if (cpu_req) next_state = FETCH;
                else next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    always @(posedge clk) begin
        if (rst) state <= IDLE;
        else state <= next_state;
    end
    always @(*) begin
        case (state)
            IDLE: begin
                we_tag = 1'b0;
                we_data = 1'b0;
                mem_req = 1'b0;
                mem_we = 1'b0;
                stall = 1'b0;
                if (cpu_req) begin
                    we_tag = 1'b1;
                    we_data = cpu_we;
                    mem_req = 1'b1;
                    stall = 1'b1;
                end
            end
            FETCH: begin
                we_tag = 1'b0;
                we_data = 1'b0;
                mem_req = 1'b0;
                mem_we = 1'b0;
                stall = 1'b0;
            end
            COMPARE: begin
                we_tag = 1'b0;
                we_data = 1'b0;
                mem_req = 1'b0;
                mem_we = 1'b0;
                stall = 1'b0;
            end
            WRITE_BACK: begin
                we_tag = 1'b0;
                we_data = 1'b0;
                mem_req = 1'b0;
                mem_we = 1'b0;
                stall = 1'b0;
            end
        endcase
    end

endmodule
