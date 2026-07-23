// Hardware bubble sort engine for 8 elements of 8-bit unsigned integers
// Elements stored in an internal register array: arr[0..7]
// load=1 loads input_data into the array on the next posedge clk
// start=1 begins sorting (ignored if already busy)
// done=1 when array is fully sorted (pulses for 1 cycle)
// Sorted output available on arr_out[63:0] (arr[0] in [7:0], arr[7] in [63:56])
// Uses bubble sort: N-1 passes, each pass does N-1 compare-swap steps
// One compare-swap per clock cycle
module bubble_sort (
    input  wire        clk,
    input  wire        reset,
    input  wire        load,
    input  wire        start,
    input  wire [63:0] input_data,  // arr[0] in [7:0], arr[7] in [63:56]
    output reg  [63:0] arr_out,
    output reg         done
);
    // FSM states: IDLE, LOAD, SORT, DONE
    // Pass counter: 0..6 (7 passes for 8 elements)
    // Step counter: 0..(6-pass) for compare-swap pairs
    // Swap: if arr[step] > arr[step+1] then swap them
    reg [2:0] state, next_state;
    reg [3:0] pass_count;
    reg [3:0] step_count;
    reg [63:0] arr [7:0];
    reg [63:0] arr_in;
    reg [63:0] temp;
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            pass_count <= 0;
            step_count <= 0;
            arr_in <= 0;
        end else begin
            arr_in <= input_data;
            if (load)
                arr[0] <= arr_in[63:56];
            if (state == LOAD)
                pass_count <= pass_count + 1;
            if (state == SORT)
                step_count <= step_count + 1;
            if (state == IDLE) begin
                if (start) begin
                    state <= LOAD;
                    pass_count <= 0;
                    step_count <= 0;
                end
            end else if (state == LOAD) begin
                if (pass_count == 7) begin
                    state <= SORT;
                    pass_count <= 0;
                end
            end else if (state == SORT) begin
                if (step_count == (6-pass_count)) begin
                    state <= DONE;
                    step_count <= 0;
                end
            end else if (state == DONE) begin
                if (start) begin
                    state <= LOAD;
                    pass_count <= 0;
                    step_count <= 0;
                end
            end
        end
    end
    always @(*) begin
        case (state)
            IDLE: begin
                if (load)
                    next_state = LOAD;
                else
                    next_state = IDLE;
            end
            LOAD: begin
                next_state = SORT;
            end
            SORT: begin
                if (step_count == (6-pass_count)) begin
                    next_state = DONE;
                end else
                    next_state = SORT;
            end
            DONE: begin
                if (start) begin
                    next_state = LOAD;
                end else
                    next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    always @(posedge clk) begin
        if (reset) begin
            done <= 0;
        end else begin
            if (state == DONE) begin
                done <= 1;
            end else begin
                done <= 0;
            end
        end
    end
    always @(posedge clk) begin
        if (reset) begin
            arr_out <= 0;
        end else begin
            if (state == SORT) begin
                arr_out <= arr[step_count+1];
            end else
                arr_out <= arr[step_count];
        end
    end
    always @(posedge clk) begin
        if (reset) begin
            temp <= 0;
        end else begin
            if (state == SORT) begin
                if (arr[step_count] > arr[step_count+1]) begin
                    temp <= arr[step_count];
                    arr[step_count] <= arr[step_count+1];
                    arr[step_count+1] <= temp;
                end
            end
        end
    end

endmodule
