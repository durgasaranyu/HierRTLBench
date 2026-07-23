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
    reg [$clog2(N)-1:0] priority [N-1:0];
    reg [$clog2(N)-1:0] granted_index;
    always @(posedge clk) begin
        if (reset) begin
            granted_index <= 0;
            priority[0] <= 0;
        end else begin
            priority[0] <= req[0]? priority[0] + 1 : priority[0];
            for (integer i = 1; i < N; i = i + 1) begin
                priority[i] <= req[i]? priority[i - 1] + 1 : priority[i - 1];
            end
            granted_index <= req[N-1]? priority[N-1] : granted_index;
        end
    end
    // Output: register of granted indexes
    always @(posedge clk) begin
        if (reset) grant <= 0;
        else grant <= granted_index;
    end

endmodule
