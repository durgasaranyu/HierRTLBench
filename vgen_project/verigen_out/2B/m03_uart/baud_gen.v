// Baud rate clock divider. Outputs single-cycle tick every CLK_FREQ/BAUD_RATE clocks.
module baud_gen #(parameter CLK_FREQ=50000000, parameter BAUD_RATE=115200) (
    input  clk, rst,
    output tick
);
    reg [$clog2(CLK_FREQ/BAUD_RATE)-1:0] counter;
    always @(posedge clk) begin
        if (rst) counter <= 0;
        else if (counter == CLK_FREQ/BAUD_RATE-1) counter <= 0;
        else counter <= counter + 1;
    end
    assign tick = (counter == CLK_FREQ/BAUD_RATE-1);

endmodule
