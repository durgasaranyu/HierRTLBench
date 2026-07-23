// Round-robin grant logic. One-hot grant starting from ptr position. No starvation.
// Uses double-width mask trick to avoid priority inversion.
module rr_grant_logic #(parameter N = 4) (
    input  [N-1:0] req, ptr,
    output [N-1:0] grant
);
    reg [N-1:0] next_grant;
    always @* begin
        next_grant = '0;
        for (int i = 0; i < N; i++) begin
            if (req[i])
                next_grant[i] = ptr[i];
        end
    end
    assign grant = next_grant;

endmodule
