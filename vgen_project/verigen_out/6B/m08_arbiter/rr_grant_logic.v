// Round-robin grant logic. One-hot grant starting from ptr position. No starvation.
// Uses double-width mask trick to avoid priority inversion.
module rr_grant_logic #(parameter N = 4) (
    input  [N-1:0] req, ptr,
    output [N-1:0] grant
);
    // Because this is a parameterized module, we need to make sure the
    // Grant_Encoder output is properly shifted and truncated.
    // We use a double-width register to get the proper behavior.
    reg [N-1:0] rr_grant_0;
    reg [N-1:0] rr_grant_1;
    reg [N-1:0] rr_grant_2;
    reg [N-1:0] rr_grant_3;
    always @(*) begin
        // Priority to the most recently granted request
        grant = rr_grant_3;
        // Priority to the second most recently granted request
        // (the first granted request in the FIFO)
        // In the unlikely event that there is a starvation, we will
        // return the first granted request
        if (rr_grant_0 == ptr) begin
            if (rr_grant_1 == ptr) begin
                if (rr_grant_2 == ptr) begin
                    grant = ptr;
                end
                else begin
                    grant = rr_grant_2;
                end
            end
            else begin
                grant = rr_grant_1;
            end
        end
        // If no request is granted, return the last granted request
        else begin
            grant = rr_grant_0;
        end
    end
endmodulemodule rr_master_logic #(parameter N = 4) (
    input clk, rst,
    input req,
    output reg [N-1:0] grant,
    output reg req_out,
    output reg grant_out,
    output reg grant_encoded
);
    // Declaration
    reg [N-1:0] req_reg;
    reg [N-1:0] grant_reg;
    reg [N-1:0] grant_reg_next;
    reg req_out_reg;
    reg grant_out_reg, grant_out_next;
    reg grant_encoded_reg;
    // State transition logic
    always @(posedge clk) begin
        if (rst) begin
            req_reg <= 0;
            req_out_reg <= 0;
            grant_reg <= 0;
            grant_out_reg <= 0;
            grant_encoded_reg <= 0;
        end else begin
            req_reg <= req;
            req_out_reg <= req_out;
            grant_reg <= grant;
            grant_out_reg <= grant_out;
            grant_encoded_reg <= grant_encoded;
        end
    end
    // State flip-flops with asynchronous reset
    always @(posedge clk) begin
        if (rst) begin
            grant_reg_next <= 0;
            grant_out_next <= 0;
            grant_encoded_next <= 0;
        end else begin
            grant_reg_next <= grant_reg;
            grant_out_next <= grant_out_reg;
            grant_encoded_next <= grant_encoded_reg;
        end
    end
    // Grant update logic
    always @(posedge clk) begin
        if (req_out_reg) begin
            grant <= 0;
            grant_out <= 0;
            grant_encoded <= 0;
        end else if (grant_reg_next > 0) begin
            grant <= 1;
            grant_out <= 0;
            grant_encoded <= 0;
        end else if (grant_out_next) begin
            grant <= 0;
            grant_out <= 1;
            grant_encoded <= 0;
        end else if (grant_encoded_next) begin
            grant <= 0;
            grant_out <= 0;
            grant_encoded <= 1;
        end
    end
endmodulemodule rr_master_test #(parameter N = 4) ();
    // Declare the request vector
    reg signed [N-1:0] req;
    reg signed [N-1:0] req_out;
    reg clk, rst;
    // Declare the master
    wire [N-1:0] grant;
    wire grant_out;
    wire grant_encoded;
    // Declare a variable for counting errors
    integer error_ctr;
    // Initialize the variables
    initial begin
        clk = 0;
        rst = 0;
        req = 0;
        req_out = 0;
        error_ctr = 0;
        // Reset the FSM
        #
endmodule
