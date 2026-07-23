// Write-through cache controller FSM. States: IDLE, COMPARE, MEM_FETCH, WRITE_BACK.
// Address: tag[31:6], index[5:2], offset[1:0].
module cache_ctrl (
    input        clk, rst, cpu_req, mem_ack, hit, cpu_we,
    output reg   we_tag, we_data, mem_req, mem_we, stall
);
    // CPU requests
    always @(posedge clk or posedge rst)
        if (rst) begin
            cpu_req <= 0;
            mem_req <= 0;
        end else begin
            cpu_req <= cpu_req;
            mem_req <= mem_req;
        end
    // CPU write enable
    always @(posedge clk or posedge rst)
        if (rst) begin
            cpu_we <= 0;
        end else begin
            if (cpu_req == 1)
                cpu_we <= 1;
            else if (cpu_we)
                cpu_we <= 0;
        end
    // Write-back
    always @(posedge clk or posedge rst)
        if (rst) begin
            we_tag <= 0;
            we_data <= 0;
        end else begin
            if (cpu_req == 1) begin
                we_tag <= 1;
                we_data <= 0;
            end else if (cpu_we) begin
                we_tag <= 0;
                we_data <= 1;
            end
        end
    // Stall
    always @(posedge clk or posedge rst)
        if (rst)
            stall <= 0;
        else
            stall <= (cpu_req == 1) || (cpu_we == 1);

endmodule
