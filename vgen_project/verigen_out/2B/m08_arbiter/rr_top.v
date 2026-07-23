// Round-robin arbiter top: N requestors, registered one-hot grant, no starvation.
module round_robin_arbiter #(parameter N = 4) (
    input          clk, rst,
    input  [N-1:0] req,
    output [N-1:0] grant
);
    // N-1 since we get N-1 req's and N-1 grants
    reg [N-1:0] grant_r;
    always @(posedge clk or posedge rst) begin
        if (rst)
            grant_r <= 0;
        else
            grant_r <= req & ~(|req) & ~(|grant_r);
    end
    assign grant = grant_r;

endmodule
