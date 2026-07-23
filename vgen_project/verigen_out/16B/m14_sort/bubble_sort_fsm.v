// Bubble sort FSM controller. States: 0=IDLE, 1=LOAD, 2=SORT, 3=DONE.
// 8 elements. Outer pass index j (0..6), inner compare index i (0..6-j).
module bubble_sort_fsm (
    input        clk, rst, start,
    output reg [1:0] state,
    output reg [2:0] i, j,
    output reg       swap_en, load_en, done
);

reg [1:0] next_state;
reg [2:0] next_i, next_j;
reg [2:0] n_cycles;

parameter IDLE = 2'd0;
parameter LOAD = 2'd1;
parameter SORT = 2'd2;
parameter DONE = 2'd3;

always @(*) begin
    // Default values
    state = IDLE;
    i = 3'd0;
    j = 3'd0;
    swap_en = 1'b0;
    load_en = 1'b0;
    done = 1'b0;

    case (state)
        IDLE: begin
            if (start) begin
                next_state = LOAD;
                next_i = 3'd0;
                next_j = 3'd0;
                n_cycles = 3'd0;
            end
        end
        LOAD: begin
            if (n_cycles == 3'd7) begin
                next_state = SORT;
                next_i = 3'd0;
                next_j = 3'd0;
                n_cycles = 3'd0;
            end
            else begin
                next_state = LOAD;
                next_i = 3'd0;
                next_j = 3'd0;
                n_cycles = n_cycles + 1;
            end
        end
        SORT: begin
            if (i == 3'd6) begin
                next_state = DONE;
                next_i = 3'd0;
                next_j = 3'd0;
                n_cycles = 3'd0;
            end
            else begin
                next_state = SORT;
                next_i = i + 1;
                next_j = j;
                n_cycles = n_cycles + 1;
            end
        end
        DONE: begin
            if (start) begin
                next_state = LOAD;
                next_i = 3'd0;
                next_j = 3'd0;
                n_cycles = 3'd0;
            end
            else begin
                next_state = IDLE;
                next_i = 3'd0;
                next_j = 3'd0;
                n_cycles = 3'd0;
            end
        end
        default: begin
            next_state = IDLE;
            next_i = 3'd0;
            next_j = 3'd0;
            n_cycles = 3'd0;
        end
    endcase
end

always @(posedge clk) begin
    if (rst) begin
        state <= IDLE;
    end
    else begin
        state <= next_state;
        i <= next_i;
        j <= next_j;
        swap_en <= 1'b0;
        load_en <= 1'b0;
        done <= 1'b0;
        n_cycles <= n_cycles + 1;
        if (state == LOAD) begin
            load_en <= 1'b1;
        end
        else if (state == SORT) begin
            if (i == 3'd6) begin
                swap_en <= 1'b1;
            end
            else begin
                swap_en <= 1'b0;
            end
        end
        else if (state == DONE) begin
            done <= 1'b1;
        end
    end
end


endmodule
