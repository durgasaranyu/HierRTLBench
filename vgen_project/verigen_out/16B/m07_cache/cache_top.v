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
    reg [31:0] cache [0:15];
    reg [31:0] mem [0:15];
    reg [31:0] tag [0:15];
    reg [31:0] index [0:15];
    reg [31:0] offset [0:15];
    reg [31:0] tag_rdata, index_rdata, offset_rdata;
    reg [4:0]  state;
    reg [31:0] cpu_rdata_reg, cpu_rdata_tag, cpu_rdata_index, cpu_rdata_offset;
    reg [31:0] stall_addr, stall_data;
    reg stall;
    reg [31:0] next_addr, next_data;
    reg [31:0] prev_addr, prev_data;
    reg [31:0] next_addr_reg, next_data_reg;
    reg [31:0] prev_addr_reg, prev_data_reg;
    reg [4:0]  next_state;
    reg [4:0]  next_state_reg;
    reg [31:0] tag_addr, index_addr, offset_addr;
    reg [31:0] tag_addr_reg, index_addr_reg, offset_addr_reg;
    reg [31:0] tag_rdata_reg, index_rdata_reg, offset_rdata_reg;
    reg [31:0] tag_rdata_next, index_rdata_next, offset_rdata_next;
    reg [31:0] tag_rdata_prev, index_rdata_prev, offset_rdata_prev;
    reg [31:0] tag_rdata_next_reg, index_rdata_next_reg, offset_rdata_next_reg;
    reg [31:0] tag_rdata_prev_reg, index_rdata_prev_reg, offset_rdata_prev_reg;
    reg [31:0] data_addr, data_rdata;
    reg [31:0] data_addr_reg, data_rdata_reg;
    reg [31:0] data_addr_next, data_rdata_next;
    reg [31:0] data_addr_next_reg, data_rdata_next_reg;
    reg [31:0] data_addr_prev, data_rdata_prev;
    reg [31:0] data_addr_prev_reg, data_rdata_prev_reg;
    reg [31:0] data_addr_next_reg_in, data_rdata_next_reg_in;
    reg [31:0] data_addr_prev_reg_in, data_rdata_prev_reg_in;
    reg [31:0] data_addr_next_tmp, data_rdata_next_tmp;
    reg [31:0] data_addr_next_reg_tmp, data_rdata_next_reg_tmp;
    reg [31:0] data_addr_prev_tmp, data_rdata_prev_tmp;
    reg [31:0] data_addr_prev_reg_tmp, data_rdata_prev_reg_tmp;
    reg [31:0] data_addr_tmp, data_rdata_tmp;
    reg [31:0] data_addr_reg_tmp, data_rdata_reg_tmp;
    reg [31:0] data_addr_next_reg_in, data_rdata_next_reg_in;
    reg [31:0] data_addr_prev_reg_in, data_rdata_prev_reg_in;
    reg [31:0] data_addr_tmp_reg, data_rdata_tmp_reg;
    reg [31:0] data_addr_next_tmp_reg, data_rdata_next_tmp_reg;
    reg [31:0] data_addr_prev_tmp_reg, data_rdata_prev_tmp_reg;
    reg [31:0] data_addr_next_reg, data_rdata_next_reg;
    reg [31:0] data_addr_prev_reg, data_rdata_prev_reg;
    reg [31:0] data_addr_next_reg_in, data_rdata_next_reg_in;
    reg [31:0] data_addr_prev_reg_in, data_rdata_prev_reg_in;
    reg [31:0] data_addr_tmp_reg_in, data_rdata_tmp_reg_in;
    reg [31:0] data_addr_next_tmp_reg_in, data_rdata_next_tmp_reg_in;
    reg [31:0] data_addr_prev_tmp_reg_in, data_rdata_prev_tmp_reg_in;
    reg [31:0] data_addr_next_reg_out, data_rdata_next_reg_out;
    reg [31:0] data_addr_prev_reg_out, data_rdata_prev_reg_out;
    reg [31:0] data_addr_tmp_reg_out, data_rdata_tmp_reg_out;
    reg [31:0] data_addr_next_tmp_reg_out, data_rdata_next_tmp_reg_out;
    reg [31:0] data_addr_prev_tmp_reg_out, data_rdata_prev_tmp_reg_out;
    reg [31:0] data_addr_next_reg_out, data_rdata_next_reg_out;
    reg [31:0] data_addr_prev_reg_out, data_rdata_prev_reg_out;
    reg [31:0] data_addr_tmp_reg_out, data_rdata_tmp_reg_out;
    reg [31:0] data_addr_next_tmp_reg_out, data_rdata_next_tmp_reg_out;
    reg [31:0] data_addr_prev_tmp_reg_out, data_rdata_prev_tmp_reg_out;
    reg [31:0] data_addr_next_reg_out, data_rdata_next_reg_out;
    reg [31:0] data_addr_prev_reg_out, data_rdata_prev_reg_out;
    reg [31:0] data_addr_tmp_reg_out, data_rdata_tmp_reg_out;
    reg [31:0] data_addr_next_tmp_reg_out, data_rdata_next_tmp_reg_out;
    reg [31:0] data_addr_prev_tmp_reg_out, data_rdata_prev_tmp_reg_out;
    reg [31:0] data_addr_next_reg_out, data_rdata_next_reg_out;
    reg [31:0] data_addr_prev_reg_out, data_rdata_prev_reg_out;
    reg [31:0] data_addr_tmp_reg_out, data_rdata_tmp_reg_out;
    reg [31:0] data_addr_next_tmp_reg_out, data_rdata_next_tmp_reg_out;
    reg [31:0] data_addr_prev_tmp_reg_out, data_rdata_prev_tmp_reg_out;
    reg [31:0] data_addr_next_reg_out, data_rdata_next_reg_out;
    reg [31:0] data_addr_prev_reg_out, data_rdata_prev_reg_out;
    reg [31:0] data_addr_tmp_reg_out, data_rdata_tmp_reg_out;
    reg [31:0] data_addr_next_tmp_reg_out, data_rdata_next_tmp_reg_out;
    reg [31:0] data_addr_prev
endmodule
