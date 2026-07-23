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
    reg [4:0] pass;
    reg [5:0] step;
    reg [7:0] arr [0:7];
    reg [7:0] tmp;
    always @(posedge clk) begin
        if (reset) begin
            pass <= 0;
            step <= 0;
            done <= 0;
            arr_out <= 0;
        end else if (load) begin
            arr_out <= input_data;
            done <= 0;
        end else if (start) begin
            pass <= 0;
            step <= 0;
            done <= 0;
            arr_out <= 0;
        end else if (done) begin
            done <= 0;
            if (pass == 6) begin
                done <= 1;
                arr_out <= tmp;
            end else begin
                pass <= pass + 1;
                step <= step + 1;
                case (step)
                    0: begin
                        tmp <= input_data;
                        arr[0] <= input_data;
                        arr[7] <= input_data;
                    end
                    1: begin
                        tmp <= arr[0];
                        arr[0] <= arr[1];
                        arr[1] <= tmp;
                    end
                    2: begin
                        tmp <= arr[0];
                        arr[0] <= arr[2];
                        arr[2] <= tmp;
                    end
                    3: begin
                        tmp <= arr[0];
                        arr[0] <= arr[3];
                        arr[3] <= tmp;
                    end
                    4: begin
                        tmp <= arr[0];
                        arr[0] <= arr[4];
                        arr[4] <= tmp;
                    end
                    5: begin
                        tmp <= arr[0];
                        arr[0] <= arr[5];
                        arr[5] <= tmp;
                    end
                    6: begin
                        tmp <= arr[0];
                        arr[0] <= arr[6];
                        arr[6] <= tmp;
                    end
                    7: begin
                        tmp <= arr[0];
                        arr[0] <= arr[7];
                        arr[7] <= tmp;
                    end
                endcase
            end
        end
    end

endmodule
