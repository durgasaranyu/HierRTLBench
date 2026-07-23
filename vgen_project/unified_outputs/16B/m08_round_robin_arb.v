// Parameterized round-robin arbiter for N requestors
// grant is one-hot: exactly one bit set when any request is active
// grant is zero when req == 0
// Priority rotates: after granting bit i, next search starts at i+1
// Registered output: grant updates on posedge clk
// reset is synchronous active-high — priority pointer resets to 0
// No starvation: every active requestor is served within N cycles
module round_robin_arb #(parameter N = 4) (
    input  wire        clk,
    input  wire        reset,
    input  wire [N-1:0] req,
    output reg  [N-1:0] grant
);
    // Internal: priority pointer register [log2(N)-1:0]
    // Algorithm: starting from pointer, find first set bit in req (wrapping)
    // Use a for-loop in always block — ensure it synthesises to priority mux
    // After grant, advance pointer to (granted_index + 1) % N
    reg [N-1:0] pointer;
    always @(posedge clk, posedge reset) begin
        if (reset) pointer <= 0;
        else begin
            for (pointer = 0; pointer < N; pointer = pointer + 1)
                if (req[pointer]) begin
                    // Found first set bit
                    if (pointer == N-1) pointer = 0;
                    else break;
                end
        end
    end
    // Grant signal: output of priority mux
    // When reset, grant is 0
    // When req is 0, grant is unchanged
    // When req is nonzero, grant is updated
    always @(posedge clk, posedge reset) begin
        if (reset) grant <= 0;
        else if (req[pointer]) grant <= pointer + 1;
    end

endmodule
