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
    reg [`DCACHE_TAG-1:0]  tag [`DCACHE_SET-1:0];
    reg [`DCACHE_VAL-1:0]  valid [`DCACHE_SET-1:0];
    reg [`DCACHE_DATA-1:0] data [`DCACHE_SET-1:0];
    wire [`DCACHE_DATA-1:0] line_sel;
    wire [`DCACHE_DATA-1:0] line_sel_data;
    wire [`DCACHE_DATA-1:0] line_sel_tag;
    wire [`DCACHE_DATA-1:0] line_hit;
    wire [`DCACHE_DATA-1:0] line_miss;
    wire [`DCACHE_DATA-1:0] line_stall;
    wire [`DCACHE_DATA-1:0] line_stall_data;
    wire [`DCACHE_DATA-1:0] line_stall_tag;
    wire [`DCACHE_DATA-1:0] fetch;
    wire [`DCACHE_DATA-1:0] fetch_data;
    wire [`DCACHE_DATA-1:0] fetch_tag;
    wire [`DCACHE_DATA-1:0] store;
    wire [`DCACHE_DATA-1:0] store_data;
    wire [`DCACHE_DATA-1:0] store_tag;
    wire [`DCACHE_DATA-1:0] load;
    wire [`DCACHE_DATA-1:0] load_data;
    wire [`DCACHE_DATA-1:0] load_tag;
    wire [`DCACHE_DATA-1:0] prefetch;
    wire [`DCACHE_DATA-1:0] prefetch_data;
    wire [`DCACHE_DATA-1:0] prefetch_tag;
    wire [`DCACHE_DATA-1:0] stall;
    wire [`DCACHE_DATA-1:0] stall_data;
    wire [`DCACHE_DATA-1:0] stall_tag;
    wire [`DCACHE_DATA-1:0] kill;
    wire [`DCACHE_DATA-1:0] kill_data;
    wire [`DCACHE_DATA-1:0] kill_tag;
    wire [`DCACHE_DATA-1:0] store_stall;
    wire [`DCACHE_DATA-1:0] load_stall;
    wire [`DCACHE_DATA-1:0] fetch_stall;
    wire [`DCACHE_DATA-1:0] store_stall_data;
    wire [`DCACHE_DATA-1:0] load_stall_data;
    wire [`DCACHE_DATA-1:0] fetch_stall_data;
    wire [`DCACHE_DATA-1:0] store_stall_tag;
    wire [`DCACHE_DATA-1:0] load_stall_tag;
    wire [`DCACHE_DATA-1:0] fetch_stall_tag;
    wire [`DCACHE_DATA-1:0] store_kill;
    wire [`DCACHE_DATA-1:0] load_kill;
    wire [`DCACHE_DATA-1:0] fetch_kill;
    wire [`DCACHE_DATA-1:0] store_kill_data;
    wire [`DCACHE_DATA-1:0] load_kill_data;
    wire [`DCACHE_DATA-1:0] fetch_kill_data;
    wire [`DCACHE_DATA-1:0] store_kill_tag;
    wire [`DCACHE_DATA-1:0] load_kill_tag;
    wire [`DCACHE_DATA-1:0] fetch_kill_tag;
    wire [`DCACHE_DATA-1:0] store_kill_stall;
    wire [`DCACHE_DATA-1:0] load_kill_stall;
    wire [`DCACHE_DATA-1:0] fetch_kill_stall;
    wire [`DCACHE_DATA-1:0] store_stall_stall;
    wire [`DCACHE_DATA-1:0] load_stall_stall;
    wire [`DCACHE_DATA-1:0] fetch_stall_stall;
    wire [`DCACHE_DATA-1:0] store_kill_stall_data;
    wire [`DCACHE_DATA-1:0] load_kill_stall_data;
    wire [`DCACHE_DATA-1:0] fetch_kill_stall_data;
    wire [`DCACHE_DATA-1:0] store_kill_stall_tag;
    wire [`DCACHE_DATA-1:0] load_kill_stall_tag;
    wire [`DCACHE_DATA-1:0] fetch_kill_stall_tag;
    wire [`DCACHE_DATA-1:0] store_kill_stall_stall;
    wire [`DCACHE_DATA-1:0] load_kill_stall_stall;
    wire [`DCACHE_DATA-1:0] fetch_kill_stall_stall;
    wire [`DCACHE_DATA-1:0] store_stall_stall;
    wire [`DCACHE_DATA-1:0] load_stall_stall;
    wire [`DCACHE_DATA-1:0] fetch_stall_stall;
    wire [`DCACHE_DATA-1:0] store_stall_data_stall;
    wire [`DCACHE_DATA-1:0] load_stall_data_stall;
    wire [`DCACHE_DATA-1:0] fetch_stall_data_stall;
    wire [`DCACHE_DATA-1:0] store_stall_tag_stall;
    wire [`DCACHE_DATA-1:0] load_stall_tag_stall;
    wire [`DCACHE_DATA-1:0] fetch_stall_tag_stall;
    wire [`DCACHE_DATA-1:0] store_stall_stall;
    wire [`DCACHE_DATA-1:0] load_stall_stall;
    wire [`DCACHE_DATA-1:0] fetch_stall_stall;
    wire [`DCACHE_DATA-1:0] store_kill_stall_data;
    wire [`DCACHE_DATA-1:0] load_kill_stall_data;
    wire [`DCACHE_DATA-1:0] fetch_kill_stall_data;
    wire [`DCACHE_DATA-1:0] store_kill_stall_tag;
    wire [`DCACHE_DATA-1:0] load_kill_stall_tag;
    wire [`DCACHE_DATA-1:0] fetch_kill_stall_tag;
    wire [`DCACHE_DATA-1:0] store_kill_stall_stall;
    wire [`DCACHE_DATA-1:0] load_
endmodule
