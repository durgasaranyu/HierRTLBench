// Round-robin priority pointer register. Updates to position after last grant on each cycle.
module rr_ptr #(parameter N = 4) (
    input            clk, rst,
    input  [N-1:0]   grant,
    output reg [N-1:0] ptr
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            ptr <= 0;
        else
            ptr <= (ptr + 1) % grant;
    end

endmodule
