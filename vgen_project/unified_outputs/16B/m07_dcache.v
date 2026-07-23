// Direct-mapped cache: 16 sets, 4-byte (32-bit) lines, write-through policy
// 32-bit byte address decomposition:
//   [1:0]  = byte offset (ignored — word-aligned access)
//   [5:2]  = index (4 bits → 16 sets)
//   [31:6] = tag (26 bits)
// On read hit:  rdata = cache_data[index]; hit = 1
// On read miss: fetch from memory (mem_rdata), update cache, hit = 0
// On write:     update cache and write through to memory simultaneously
// valid array initialised to 0 on reset
module dcache (
    input  wire        clk,
    input  wire        reset,
    // CPU interface
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire        we,
    input  wire        req,
    output reg  [31:0] rdata,
    output reg         hit,
    // Memory interface
    output wire [31:0] mem_addr,
    output wire [31:0] mem_wdata,
    output wire        mem_we,
    input  wire [31:0] mem_rdata
);
    // Arrays: valid[15:0], tag[15:0][25:0], data[15:0][31:0]
    reg [15:0] valid [0:15];
    reg [15:0] tag [0:15];
    reg [15:0] data [0:15];
    reg [31:0] rdata_reg;
    // Set to 1 if the line is in the cache
    reg [31:0] tag_rdata_reg;
    // Set to 1 if the line is in the cache
    reg [31:0] data_rdata_reg;
    // Index in the cache array
    reg [4:0] index;
    // Tag comparison results
    reg [1:0] tag_comp_a;
    reg [1:0] tag_comp_b;
    // Valid comparison results
    reg [1:0] valid_comp_a;
    reg [1:0] valid_comp_b;
    // Write hit
    reg write_hit;
    // Read hit
    reg read_hit;
    // Read miss
    reg read_miss;
    // Write miss
    reg write_miss;
    // Write-back buffer
    reg [31:0] wdata_buf;
    // Main memory
    assign mem_addr = addr;
    assign mem_wdata = wdata_buf;
    assign mem_we = we & ~write_hit;
    // Instantiate the memory system
    mem mem_sys(
       .clk(clk),
       .addr(mem_addr),
       .wdata(mem_wdata),
       .we(mem_we),
       .rdata(mem_rdata)
    );
    // Instantiate the cache
    cache cache_sys(
       .clk(clk),
       .reset(reset),
       .addr(addr[31:4]),
       .rdata(rdata_reg),
       .valid(valid_comp_a),
       .tag(tag_rdata_reg),
       .data(data_rdata_reg),
       .hit(hit),
       .index(index),
       .req(req),
       .write_hit(write_hit),
       .read_hit(read_hit),
       .read_miss(read_miss),
       .write_miss(write_miss)
    );
    // Read miss action
    always @(read_miss) begin
        rdata_reg = 32'bx;
        index = 16'bx;
        tag_rdata_reg = 32'bx;
        data_rdata_reg = 32'bx;
        valid_comp_a = 2'bxx;
        valid_comp_b = 2'bxx;
        tag_comp_a = 2'bxx;
        tag_comp_b = 2'bxx;
        hit = 1'b0;
        wdata_buf = 32'bx;
        if (mem_rdata[31:0] == 32'bx)
            $display ("%t ERROR: dcache miss on unmapped reference", $time);
        else begin
            rdata_reg = mem_rdata;
            index = (addr[31:2] & 15'h1f00) >> 9;
            tag_rdata_reg = {mem_rdata[31:10], mem_rdata[24:0]};
            data_rdata_reg = data[index];
            valid_comp_a = (tag[index] == tag_rdata_reg)? 2'b11 : 2'b00;
            valid_comp_b = (rdata[index] == rdata_reg)? 2'b11 : 2'b00;
            tag_comp_a = (tag[index] == tag_rdata_reg)? 2'b11 : 2'b00;
            tag_comp_b = (rdata[index] == rdata_reg)? 2'b11 : 2'b00;
            if (valid[index] == 2'b00) begin
                hit = 1'b0;
                write_miss = 1'b1;
                wdata_buf = rdata_reg;
            end else if (valid[index] == 2'b10) begin
                hit = 1'b1;
                write_miss = 1'b0;
                wdata_buf = 32'bx;
            end else begin
                hit = 1'b0;
                write_miss = 1'b0;
                wdata_buf = 32'bx;
            end
        end
    end
    // Read hit action
    always @(read_hit) begin
        rdata_reg = data_rdata_reg;
        index = (addr[31:2] & 15'h1f00) >> 9;
        valid_comp_a = (tag[index] == tag_rdata_reg)? 2'b11 : 2'b00;
        valid_comp_b = (rdata[index] == rdata_reg)? 2'b11 : 2'b00;
        tag_comp_a = (tag[index] == tag_rdata_reg)? 2'b11 : 2'b00;
        tag_comp_b = (rdata[index] == rdata_reg)? 2'b11 : 2'b00;
        hit = 1'b1;
        write_miss = 1'b0;
        wdata_buf = 32'bx;
    end
    // Write hit action
    always @(write_hit) begin
        rdata_reg = 32'bx;
        index = (addr[31:2] & 15'h1f00) >> 9;
        valid_comp_a = 2'bxx;
        valid_comp_b = 2'bxx;
        tag_comp_a = 2'bxx;
        tag_comp_b = 2'bxx;
        hit = 1'b0;
        write_miss = 1'b0;
        wdata_buf = 32'bx;
    end
    // Write miss action
    always @(write_miss) begin
        rdata_reg = 32'bx;
        index = (addr[31:2] & 15'h1f00) >> 9;
        valid_comp_a = 2'bxx;
        valid_comp_b = 2'bxx;
        tag_comp_a = 2'bxx;
        tag_comp_b = 2'bxx;
        hit = 1'b0;
        write_miss = 1'b0;
        wdata_buf = 32'bx;
    end
    // Read miss and write miss actions
    always @(read_miss or write_miss) begin
        rdata_reg = 32'bx;
        index = 16'bx;
        tag_rdata_reg = 32'bx;
        data_rdata_reg = 32'bx;
        valid_comp_a = 2'bxx;
        valid_comp_b = 2'bxx;
        tag_comp_a = 2'bxx;
        tag_comp_b = 2'bxx;
        hit = 1'b0;
        wdata_buf = 32'bx;
        if (write_miss) begin
            if (valid_comp_a == 2'b11) begin
                valid[index] =
endmodule
