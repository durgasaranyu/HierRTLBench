`timescale 1ns/1ps
// M07: Direct-mapped write-through cache integration top
// 16 sets, 4-byte lines. tag[31:6]=24b, index[5:2]=4b, offset[1:0]=2b.
module cache_integration (
    input         clk, rst, cpu_req, cpu_we,
    input  [31:0] cpu_addr, cpu_wdata,
    output [31:0] cpu_rdata,
    output        stall,
    output [31:0] mem_addr,
    input  [31:0] mem_rdata,
    output        mem_req
);
    wire [23:0] req_tag  = cpu_addr[31:6];
    wire [3:0]  idx      = cpu_addr[5:2];
    wire [1:0]  offset   = cpu_addr[1:0];

    wire [23:0] tag_out;
    wire [31:0] data_out;
    wire        valid_out, hit, we_tag, we_data, mem_we, mem_ack;
    wire [7:0]  read_byte;

    // On write fill from cpu_wdata; on miss fill from mem_rdata
    wire [31:0] data_in = cpu_we ? cpu_wdata : mem_rdata;

    cache_arrays u_arr (
        .clk(clk), .rst(rst), .index(idx),
        .tag_in(req_tag), .data_in(data_in),
        .we_tag(we_tag), .we_data(we_data),
        .tag_out(tag_out), .data_out(data_out), .valid_out(valid_out)
    );

    cache_hit_logic u_hit (
        .req_tag(req_tag), .stored_tag(tag_out),
        .byte_offset(offset), .valid(valid_out), .data(data_out),
        .hit(hit), .read_byte(read_byte)
    );

    // Single-cycle memory model: ack immediately
    assign mem_ack = mem_req;

    cache_ctrl u_ctrl (
        .clk(clk), .rst(rst),
        .cpu_req(cpu_req), .mem_ack(mem_ack), .hit(hit), .cpu_we(cpu_we),
        .we_tag(we_tag), .we_data(we_data),
        .mem_req(mem_req), .mem_we(mem_we), .stall(stall)
    );

    assign cpu_rdata = {4{read_byte}};          // byte replicated to word
    assign mem_addr  = {cpu_addr[31:2], 2'b00}; // word-aligned
endmodule
