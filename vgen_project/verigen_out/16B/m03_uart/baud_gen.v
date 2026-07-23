// Baud rate clock divider. Outputs single-cycle tick every CLK_FREQ/BAUD_RATE clocks.
module baud_gen #(parameter CLK_FREQ=50000000, parameter BAUD_RATE=115200) (
    input  clk, rst,
    output tick
);
    localparam BAUD_CLK_FREQ = CLK_FREQ/BAUD_RATE;
    reg [$clog2(BAUD_CLK_FREQ)-1:0] counter = 0;
    reg tick_reg = 0;
    assign tick = tick_reg;
    always @(posedge clk) begin
        if (rst) begin
            counter <= 0;
            tick_reg <= 0;
        end else if (counter==(BAUD_CLK_FREQ-1)) begin
            counter <= 0;
            tick_reg <= 1;
        end else begin
            counter <= counter + 1;
            tick_reg <= 0;
        end
    end

endmodule
