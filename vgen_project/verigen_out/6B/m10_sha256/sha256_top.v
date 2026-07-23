// SHA-256 core top. Single 512-bit block. FSM: IDLE->SCHEDULE->COMPRESS->DONE.
// Outputs 256-bit hash. start pulses computation. done indicates valid hash_out.
module sha256 (
    input         clk, rst, start,
    input  [511:0] block_in,
    output [255:0] hash_out,
    output         done
);
    // Declare input and output registers
    reg           clk, rst, start;
    reg [511:0]    block_in;
    reg [255:0]    hash_out;
    reg           done;
    reg [7:0]      counter;
    reg [63:0]     temp_hash;
    // Declare wires
    wire [31:0]   round_out;
    wire          round_done;
    // reg_maps
    // State
    always @(posedge clk) begin
        if (rst) begin
            clk   <= 0;
            rst   <= 0;
            start <= 0;
            counter <= 0;
            done <= 0;
        end
        else begin
            if (start) begin
                temp_hash <= block_in;
                start    <= 0;
                counter  <= 1;
                if (counter == 0) begin
                    clk   <= 1;
                    rst   <= 1;
                    done  <= 0;
                end
                else begin
                    // Set done to 1 when counter == 1.
                    done  <= 1;
                    counter <= counter + 1;
                    if (counter == 2) begin
                        // When counter == 2, set clk to 0 and start the next block.
                        clk <= 0;
                        start <= 1;
                    end
                end
            end
            else begin
                if (counter < 2) begin
                    counter <= counter + 1;
                    if (counter == 2) begin
                        // When counter == 2, set clk to 0 and start the next block.
                        clk <= 0;
                        start <= 1;
                    end
                end
                else begin
                    counter <= 0;
                    start <= 1;
                end
                // Set done to 0 when counter == 0.
                done <= 0;
            end
        end
    end
    // Round
    always @(posedge clk) begin
        if (round_done) begin
            temp_hash <= {temp_hash[255:0], 1'b0};
        end
    end
    // Add
    assign round_out = temp_hash[255:0] ^ {1'b0, round_key[255:0]};
    // Set done
    assign round_done = (counter == 2) ? 1 : 0;
endmodulemodule testbench();
    reg         clk;
    reg         rst;
    reg         start;
    reg  [511:0] block_in;
    wire [255:0] block_out;
    wire         done;
    // Set up clock
    always #5 clk = ~clk;
    // Set up reset
    initial begin
        rst <= 1;
        #
endmodule
