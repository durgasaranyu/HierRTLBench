// CRC-32 engine using IEEE 802.3 reflected polynomial 0xEDB88320
// Bit-serial: one input bit per clock cycle
// Input bits are processed LSB first (bit-reflected input)
// Output CRC is bit-reflected (standard Ethernet CRC-32 convention)
// crc_out is valid one cycle after last input bit when done=1
// init=1 resets the LFSR to 32'hFFFFFFFF (standard CRC-32 init)
// Final XOR: output = lfsr XOR 32'hFFFFFFFF
module crc32 (
    input  wire        clk,
    input  wire        reset,
    input  wire        init,
    input  wire        data_in,   // 1 bit per cycle, LSB first
    input  wire        data_valid,
    output reg  [31:0] crc_out
);
    // LFSR feedback polynomial (reflected): 0xEDB88320
    // = x^32+x^26+x^23+x^22+x^16+x^12+x^11+x^10+x^8+x^7+x^5+x^4+x^2+x+1
    // Each cycle: if data_in XOR lfsr[0] == 1, shift and XOR polynomial
    //             else just shift right
    // crc_out = lfsr XOR 32'hFFFFFFFF
    reg [31:0] lfsr;
    always @(posedge clk) begin
        if (reset) begin
            crc_out <= 32'hFFFFFFFF;
            lfsr <= 32'hFFFFFFFF;
        end else begin
            if (data_valid) begin
                lfsr <= lfsr ^ (data_in ^ lfsr[0]);
            end else begin
                lfsr <= lfsr;
            end
            crc_out <= lfsr ^ 32'hFFFFFFFF;
        end
    end

endmodule
