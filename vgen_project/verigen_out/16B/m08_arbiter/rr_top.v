// Round-robin arbiter top: N requestors, registered one-hot grant, no starvation.
module round_robin_arbiter #(parameter N = 4) (
    input          clk, rst,
    input  [N-1:0] req,
    output [N-1:0] grant
);
    reg [N-1:0] next_grant;
    always @(posedge clk, posedge rst) begin
        if (rst)
            next_grant <= {N{1'b0}};
        else
            next_grant <= req[N-1:0]? {req[N-2:0], 1'b0} : next_grant;
    end
    assign grant = next_grant;

endmodule
