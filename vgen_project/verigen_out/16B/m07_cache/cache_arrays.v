// Cache storage: 16-entry tag array, 16x32-bit data array, 16 valid bits.
// Synchronous reset clears valid bits. Synchronous indexed write.
module cache_arrays (
    input         clk, rst,
    input  [3:0]  index,
    input  [23:0] tag_in,
    input  [31:0] data_in,
    input         we_tag, we_data,
    output [23:0] tag_out,
    output [31:0] data_out,
    output        valid_out
);
    reg [23:0] tag_out;
    reg [31:0] data_out;
    reg        valid_out;
    reg [3:0]  index_tag_sel;
    reg [31:0] data_out_reg;
    reg        valid_out_reg;
    always @(posedge clk) begin
        if (rst) begin
            index_tag_sel <= 4'd0;
            data_out_reg <= 32'd0;
            valid_out_reg <= 1'b0;
        end else begin
            if (we_tag) begin
                if (index_tag_sel == 4'd0) begin
                    data_out_reg <= data_in;
                    valid_out_reg <= 1'b1;
                end else if (index_tag_sel == 4'd1) begin
                    tag_out <= data_in[31:0];
                    valid_out_reg <= 1'b1;
                end else if (index_tag_sel == 4'd2) begin
                    tag_out <= data_in[63:32];
                    valid_out_reg <= 1'b1;
                end else if (index_tag_sel == 4'd3) begin
                    tag_out <= data_in[95:64];
                    valid_out_reg <= 1'b1;
                end else if (index_tag_sel == 4'd4) begin
                    tag_out <= data_in[127:96];
                    valid_out_reg <= 1'b1;
                end else if (index_tag_sel == 4'd5) begin
                    tag_out <= data_in[159:128];
                    valid_out_reg <= 1'b1;
                end else if (index_tag_sel == 4'd6) begin
                    tag_out <= data_in[191:160];
                    valid_out_reg <= 1'b1;
                end else if (index_tag_sel == 4'd7) begin
                    tag_out <= data_in[223:192];
                    valid_out_reg <= 1'b1;
                end else if (index_tag_sel == 4'd8) begin
                    tag_out <= data_in[255:224];
                    valid_out_reg <= 1'b1;
                end else if (index_tag_sel == 4'd9) begin
                    tag_out <= data_in[287:256];
                    valid_out_reg <= 1'b1;
                end else begin
                    tag_out <= tag_out;
                    valid_out_reg <= 1'b0;
                end
            end else begin
                tag_out <= tag_out;
                data_out_reg <= data_out_reg;
                valid_out_reg <= 1'b0;
            end
            if (we_data) begin
                if (index_tag_sel == 4'd0) begin
                    data_out_reg[7:0] <= data_in[7:0];
                    data_out_reg[15:8] <= data_in[15:8];
                    data_out_reg[23:16] <= data_in[23:16];
                    data_out_reg[31:24] <= data_in[31:24];
                end else if (index_tag_sel == 4'd1) begin
                    data_out_reg[7:0] <= data_in[31:24];
                    data_out_reg[15:8] <= data_in[23:16];
                    data_out_reg[23:16] <= data_in[15:8];
                    data_out_reg[31:24] <= data_in[7:0];
                end else if (index_tag_sel == 4'd2) begin
                    data_out_reg[7:0] <= data_in[15:8];
                    data_out_reg[15:8] <= data_in[7:0];
                end else if (index_tag_sel == 4'd3) begin
                    data_out_reg[7:0] <= data_in[23:16];
                    data_out_reg[15:8] <= data_in[31:24];
                    data_out_reg[23:16] <= data_in[15:8];
                    data_out_reg[31:24] <= data_in[7:0];
                end else if (index_tag_sel == 4'd4) begin
                    data_out_reg[7:0] <= data_in[31:24];
                    data_out_reg[15:8] <= data_in[23:16];
                    data_out_reg[23:16] <= data_in[15:8];
                    data_out_reg[31:24] <= data_in[7:0];
                end else if (index_tag_sel == 4'd5) begin
                    data_out_reg[7:0] <= data_in[7:0];
                    data_out_reg[15:8] <= data_in[31:24];
                    data_out_reg[23:16] <= data_in[15:8];
                    data_out_reg[31:24] <= data_in[23:16];
                end else if (index_tag_sel == 4'd6) begin
                    data_out_reg[7:0] <= data_in[15:8];
                    data_out_reg[15:8] <= data_in[7:0];
                    data_out_reg[23:16] <= data_in[31:24];
                end else if (index_tag_sel == 4'd7) begin
                    data_out_reg[7:0] <= data_in[23:16];
                    data_out_reg[15:8] <= data_in[31:24];
                    data_out_reg[23:16] <= data_in[15:8];
                end else if (index_tag_sel == 4'd8) begin
                    data_out_reg[7:0] <= data_in[31:24];
                    data_out_reg[15:8] <= data_in[23:16];
                    data_out_reg[23:16] <= data_in[7:0];
                end else if (index_tag_sel == 4'd9) begin
                    data_out_reg[7:0] <= data_in[7:0];
                    data_out_reg[15:8] <= data_in[31:24];
                    data_out_reg[23:16] <= data_in[15:8];
                end else begin
                    data_out_reg <= data_out_reg;
                end
            end else begin
                data_out_reg <= data_out_reg;
            end
            index_tag_sel <= index_tag_sel + 1;
            if (index_tag_sel == 10) begin
                index_tag_sel <= 0;
            end
        end
    end
    assign tag_out = tag_out_reg;
    assign data_out = data_out_reg;
    assign valid_out = valid_out_reg;

endmodule
