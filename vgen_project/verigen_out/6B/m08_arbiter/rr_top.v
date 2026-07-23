// Round-robin arbiter top: N requestors, registered one-hot grant, no starvation.
module round_robin_arbiter #(parameter N = 4) (
    input          clk, rst,
    input  [N-1:0] req,
    output [N-1:0] grant
);
    // $display("%m:INFO:arbiter:%0d", N);
    reg [N-1:0] grant_reg;
    reg [N-1:0] grant_reg_next;
    reg [N-1:0] grant_reg_prev;
    reg [N-1:0] grant_reg_prev_next;
    reg [$clog2(N)-1:0] grant_bit_idx;
    reg [$clog2(N)-1:0] grant_bit_idx_next;
    reg [$clog2(N)-1:0] grant_bit_idx_prev;
    reg [$clog2(N)-1:0] grant_bit_idx_prev_next;
    reg [N-1:0] req_reg;
    reg [N-1:0] req_reg_next;
    reg [N-1:0] req_reg_prev;
    reg [N-1:0] req_reg_prev_next;
    reg [$clog2(N)-1:0] req_bit_idx;
    reg [$clog2(N)-1:0] req_bit_idx_next;
    reg [$clog2(N)-1:0] req_bit_idx_prev;
    reg [$clog2(N)-1:0] req_bit_idx_prev_next;
    reg [N-1:0] grant_reg_0;
    reg [N-1:0] grant_reg_1;
    reg [N-1:0] grant_reg_2;
    reg [N-1:0] grant_reg_3;
    reg grant_0;
    reg grant_1;
    reg grant_2;
    reg grant_3;
    integer i;

    initial begin
        grant_reg_0 = 0;
        grant_reg_1 = 0;
        grant_reg_2 = 0;
        grant_reg_3 = 0;
        grant_0 = 0;
        grant_1 = 0;
        grant_2 = 0;
        grant_3 = 0;
    end

    always @(posedge clk) begin
        if (rst) begin
            grant_reg_0 <= 0;
            grant_reg_1 <= 0;
            grant_reg_2 <= 0;
            grant_reg_3 <= 0;
        end else begin
            grant_reg_0 <= grant_0;
            grant_reg_1 <= grant_1;
            grant_reg_2 <= grant_2;
            grant_reg_3 <= grant_3;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            req_reg_0 <= 0;
            req_reg_1 <= 0;
            req_reg_2 <= 0;
            req_reg_3 <= 0;
        end else begin
            req_reg_0 <= req[0];
            req_reg_1 <= req[1];
            req_reg_2 <= req[2];
            req_reg_3 <= req[3];
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            grant_bit_idx_0 <= 0;
            grant_bit_idx_1 <= 0;
            grant_bit_idx_2 <= 0;
            grant_bit_idx_3 <= 0;
        end else begin
            grant_bit_idx_0 <= grant_bit_idx_0;
            grant_bit_idx_1 <= grant_bit_idx_1;
            grant_bit_idx_2 <= grant_bit_idx_2;
            grant_bit_idx_3 <= grant_bit_idx_3;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            req_bit_idx_0 <= 0;
            req_bit_idx_1 <= 0;
            req_bit_idx_2 <= 0;
            req_bit_idx_3 <= 0;
        end else begin
            req_bit_idx_0 <= req_bit_idx_0;
            req_bit_idx_1 <= req_bit_idx_1;
            req_bit_idx_2 <= req_bit_idx_2;
            req_bit_idx_3 <= req_bit_idx_3;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            grant_reg_0 <= 0;
            grant_reg_1 <= 0;
            grant_reg_2 <= 0;
            grant_reg_3 <= 0;
        end else begin
            grant_reg_0 <= grant_reg_0;
            grant_reg_1 <= grant_reg_1;
            grant_reg_2 <= grant_reg_2;
            grant_reg_3 <= grant_reg_3;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            req_reg_0 <= 0;
            req_reg_1 <= 0;
            req_reg_2 <= 0;
            req_reg_3 <= 0;
        end else begin
            req_reg_0 <= req_reg_0;
            req_reg_1 <= req_reg_1;
            req_reg_2 <= req_reg_2;
            req_reg_3 <= req_reg_3;
        end
    end

    // manage the requests
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i+1) begin
                grant[i] <= 1'b0;
            end
        end else begin
            if (req_0) begin
                grant[0] <= 1'b1;
                // $display("%m:INFO: Grant 0", `MESSAGE);
            end else if (req_1) begin
                grant[1] <= 1'b1;
                // $display("%m:INFO: Grant 1", `MESSAGE);
            end else if (req_2) begin
                grant[2] <= 1'b1;
                // $display("%m:INFO: Grant 2", `MESSAGE);
            end else if (req_3) begin
                grant[3] <= 1'b1;
                // $display("%m:INFO: Grant 3", `MESSAGE);
            end
            for (i = 0; i < N; i = i+1) begin
                if (grant[i]) begin
                    grant_valid[i] <= 1'b1;
                end else begin
                    grant_valid[i] <= 1'b0;
                end
            end
        end
    end

    // manage the grant cycle
    always @(posedge clk) begin
        if (rst) begin
            grant_reg_0 <= 0;
            grant_reg_1 <= 0;
            grant_reg_2 <= 0;
            grant_reg_3 <= 0;
        end else begin
            grant_reg_0 <= grant_0;
            grant_reg_1 <= grant_1;
            grant_reg_2 <= grant_2;
            grant_reg_3 <= grant_3;
        end
    end

    // manage the requests
    always @(posedge clk) begin
        if (rst) begin
            req_reg_0 <= 0;
            req_reg_1 <= 0;
            req_reg_2 <= 0;
            req_reg_3 <= 0;
        end else begin
            req_reg_0 <= req_0;
            req_reg_1 <= req_1;
            req_reg_2 <= req_2;
            req_reg_3 <= req_3;
        end
    end

    // manage the events
    always @(posedge clk) begin
        if (rst) begin
            event_0 <= 0;
            
endmodule
