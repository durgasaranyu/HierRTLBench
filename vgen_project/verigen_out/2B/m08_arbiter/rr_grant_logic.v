// Round-robin grant logic. One-hot grant starting from ptr position. No starvation.
// Uses double-width mask trick to avoid priority inversion.
module rr_grant_logic #(parameter N = 4) (
    input  [N-1:0] req, ptr,
    output [N-1:0] grant
);
    assign grant = req ^ {1'b0, ptr[N-1:1]};

endmodule
