`timescale 1ns/1ps
// M08: Round-robin arbiter integration top
// rr_grant_logic (combinational) → register → rr_ptr (updates pointer).
module round_robin_arbiter_integration #(parameter N = 4) (
    input          clk, rst,
    input  [N-1:0] req,
    output reg [N-1:0] grant
);
    wire [N-1:0] ptr, grant_comb;

    rr_grant_logic #(.N(N)) u_gl (
        .req(req), .ptr(ptr), .grant(grant_comb)
    );

    rr_ptr #(.N(N)) u_ptr (
        .clk(clk), .rst(rst),
        .grant(grant),      // use registered grant so ptr advances after commit
        .ptr(ptr)
    );

    always @(posedge clk) begin
        if (rst) grant <= {N{1'b0}};
        else     grant <= grant_comb;
    end
endmodule
