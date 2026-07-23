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
    // If no bits are set, then return 0
    reg [$clog2(N)-1:0] ptr;
    always @(posedge clk) begin
        if (reset) ptr <= 0;
        else if (req[0]) ptr <= ptr + 1;
    end
    // Grant logic: if more than half of the bits are set, grant.
    //   If only 1 bit is set, grant if it's the only thing set.
    //   Otherwise, grant if half or more of the bits are set.
    //   If no bits are set, then grant if there is only 1 bit set.
    reg [N-1:0] bits_set;
    always @(posedge clk) begin
        if (reset) bits_set <= 0;
        else if (req[N-1]) bits_set <= bits_set + 1;
        else if (|bits_set) bits_set <= bits_set - 1;
    end
    assign grant = bits_set >= N/2? {{N-1{1'b1}}, 1'b1} : {{N-1{1'b0}}, 1'b0};

endmodule
