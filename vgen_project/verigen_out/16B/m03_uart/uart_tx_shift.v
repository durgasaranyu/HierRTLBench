// 8-bit UART shift register. Loads byte on load. Shifts LSB first on shift_en.
module uart_tx_shift (
    input        clk, rst,
    input        load, shift_en,
    input  [7:0] data,
    output       serial_out,
    output       empty
);
    reg [7:0] shift_reg;
    reg        shift_reg_load;
    reg        shift_reg_shift;
    reg        shift_reg_empty;
    assign serial_out = shift_reg[0];
    assign empty = shift_reg_empty;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            shift_reg <= 0;
            shift_reg_load <= 0;
            shift_reg_shift <= 0;
            shift_reg_empty <= 1;
        end else begin
            shift_reg_load <= load;
            shift_reg_shift <= shift_en;
            if (shift_reg_load) begin
                shift_reg <= data;
                shift_reg_empty <= 0;
            end else if (shift_reg_shift) begin
                shift_reg <= {shift_reg[6:0], 1'b0};
                shift_reg_empty <= 0;
            end
        end
    end

endmodule
