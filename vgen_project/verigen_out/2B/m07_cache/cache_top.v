// Direct-mapped write-through cache: 16 sets, 4-byte lines. 32-bit address.
// tag[31:6]=24b, index[5:2]=4b, offset[1:0]=2b. Valid array reset on rst.
module cache (
    input         clk, rst, cpu_req, cpu_we,
    input  [31:0] cpu_addr, cpu_wdata,
    output [31:0] cpu_rdata,
    output        stall,
    output [31:0] mem_addr,
    input  [31:0] mem_rdata,
    output        mem_req
);
    // 32-bit tag, 4-byte index, 2-byte offset
    wire [31:0] tag_rdata, index_rdata, offset_rdata;
    // 16-bit tag, 4-byte index, 2-byte offset
    wire [15:0] tag_rdata_16, index_rdata_16, offset_rdata_16;
    // 32-bit tag, 4-byte index, 2-byte offset
    wire [31:0] tag_rdata_32, index_rdata_32, offset_rdata_32;
    // 16-bit tag, 4-byte index, 2-byte offset
    wire [15:0] tag_rdata_16_nxt, index_rdata_16_nxt, offset_rdata_16_nxt;
    // 32-bit tag, 4-byte index, 2-byte offset
    wire [31:0] tag_rdata_32_nxt, index_rdata_32_nxt, offset_rdata_32_nxt;
    // 16-bit tag, 4-byte index, 2-byte offset
    wire [15:0] tag_rdata_16_nxt_1, index_rdata_16_nxt_1, offset_rdata_16_nxt_1;
    // 32-bit tag, 4-byte index, 2-byte offset
    wire [31:0] tag_rdata_32_nxt_1, index_rdata_32_nxt_1, offset_rdata_32_nxt_1;
    // 16-bit tag, 4-byte index, 2-byte offset
    wire [15:0] tag_rdata_16_nxt_2, index_rdata_16_nxt_2, offset_rdata_16_nxt_2;
    // 32-bit tag, 4-byte index, 2-byte offset
    wire [31:0] tag_rdata_32_nxt_2, index_rdata_32_nxt_2, offset_rdata_32_nxt_2;
    // 16-bit tag, 4-byte index, 2-byte offset
    wire [15:0] tag_rdata_16_nxt_3, index_rdata_16_nxt_3, offset_rdata_16_nxt_3;
    // 32-bit tag, 4-byte index, 2-byte offset
    wire [31:0] tag_rdata_32_nxt_3, index_rdata_32_nxt_3, offset_rdata_32_nxt_3;
    // 16-bit tag, 4-byte index, 2-byte offset
    wire [15:0] tag_rdata_16_nxt_4, index_rdata_16_nxt_4, offset_rdata_16_nxt_4;
    // 32-bit tag, 4-byte index, 2-byte offset
    wire [31:0] tag_rdata_32_nxt_4, index_rdata_32_nxt_4, offset_rdata_32_nxt_4;
    // 16-bit tag, 4-byte index, 2-byte offset
    wire [15:0] tag_rdata_16_nxt_5, index_rdata_16_nxt_5, offset_rdata_16_nxt_5;
    // 32-bit tag, 4-byte index, 2-byte offset
    wire [31:0] tag_rdata_32_nxt_5, index_rdata_32_nxt_5, offset_rdata_32_nxt_5;
    // 16-bit tag, 4-byte index, 2-byte offset
    wire [15:0] tag_rdata_16_nxt_6, index_rdata_16_nxt_6, offset_rdata_16_nxt_6;
    // 32-bit tag, 4-byte index, 2-byte offset
    wire [31:0] tag_rdata_32_nxt_6, index_rdata_32_nxt_6, offset_rdata_32_nxt_6;
    // 16-bit tag, 4-byte index, 2-byte offset
    wire [15:0] tag_rdata_16_nxt_7, index_rdata_16_nxt_7, offset_rdata_16_nxt_7;
    // 32-bit tag, 4-byte index, 2-byte offset
    wire [31:0] tag_rdata_32_nxt_7, index_rdata_32_nxt_7, offset_rdata_32_nxt_7;
    // 16-bit tag, 4-byte index, 2-byte offset
    wire [15:0] tag_rdata_16_nxt_8, index_rdata_16_nxt_8, offset_rdata_16_nxt_8;
    // 32-bit tag, 4-byte index, 2-byte offset
    wire [31:0] tag_rdata_32_nxt_8, index_rdata_32_nxt_8, offset_rdata_32_nxt_8;
    // 16-bit tag, 4-byte index, 2-byte offset
    wire [15:0] tag_rdata_16_nxt_9, index_rdata_16_nxt_9, offset_rdata_16_nxt_9;
    // 32-bit tag, 4-byte index, 2-byte offset
    wire [31:0] tag_rdata_32_nxt_9, index_rdata_32_nxt_9, offset_rdata_32_nxt_9;
    // 16-bit tag, 4-byte index, 2-byte offset
    wire [15:0] tag_rdata_16_nxt_10, index_rdata_16_nxt_10, offset_rdata_16_nxt_10;
    // 32-bit tag, 4-byte index, 2-byte offset
    wire [31:0] tag_rdata_32_nxt_10, index_rdata_32_nxt_10, offset_rdata_32_nxt_10;
    // 16-bit tag, 4-byte index, 2-byte offset
    wire [15:0] tag_rdata_16_nxt_11, index_rdata_16_nxt_11, offset_rdata_16_nxt_11;
    // 32-bit tag, 4-byte index, 2-byte offset
    wire [31:0] tag_rdata_32_nxt_11, index_rdata_32_nxt_11, offset_rdata_32_nxt_11;
    // 16-bit tag, 4-byte index, 2-byte offset
    wire [15:0] tag_rdata_16_nxt_12, index_rdata_16_nxt_12, offset_rdata_16_nxt_12;
    // 32-bit tag, 4-byte index, 2-byte offset
    wire [31:0] tag_rdata_32_nxt_12, index_rdata_32_nxt_12, offset_rdata_32_nxt_12;
    // 16-bit tag, 4-byte index, 2-byte offset
    wire [15:0] tag_rdata_16_nxt_13, index_rdata_16_nxt_13, offset_rdata_16_nxt_13;
    // 32-bit tag, 4-byte index, 2-byte offset
    wire [31:0] tag_rdata_32_nxt_13, index_rdata_32_nxt_13, offset_rdata_32_nxt_13;
    // 16-bit tag, 4-byte index, 2-byte offset
    wire [15:0] tag_rdata_16_nxt_14, index_rdata_16_nxt_14, offset_rdata_16_nxt_14;
    // 32-bit
endmodule
