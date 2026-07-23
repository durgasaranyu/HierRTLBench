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
    reg [31:0] valid;
    reg [31:0] tag [15:0];
    reg [31:0] data [15:0];
    // 16 sets
    reg [15:0] set [0:15];
    // Current set (set0) and next set (set1)
    reg [15:0] set0, set1;
    // Index into current set
    reg [4:0] index;
    // Line valid bits
    reg [0:15] line_valid;
    // 16 lines, each line is 4-byte (32-bit)
    reg [31:0] line [0:15];
    // Memory read data
    reg [31:0] mem_rdata_dly;
    // Memory read data valid
    reg mem_rdata_valid;
    // Memory write data
    reg [31:0] mem_wdata_dly;
    // Memory write data valid
    reg mem_wdata_valid;
    // Memory write strobe
    reg mem_wstrb_dly;
    // Memory write strobe valid
    reg mem_wstrb_valid;
    // Memory write response
    reg [1:0] mem_bresp_dly;
    // Memory write response valid
    reg mem_bresp_valid;
    // Memory read address
    reg [31:0] mem_addr_dly;
    // Memory read address valid
    reg mem_addr_valid;
    // Memory read/write enable
    reg mem_en_dly;
    // Memory read/write enable valid
    reg mem_en_valid;
    // Memory read/write response
    reg [1:0] mem_breq_dly;
    // Memory read/write response valid
    reg mem_breq_valid;
    // Memory read/write address
    reg [31:0] mem_addr_dly_r;
    // Memory read/write address valid
    reg mem_addr_valid_r;
    // Memory read/write enable
    reg [1:0] mem_en_dly_r;
    // Memory read/write enable valid
    reg mem_en_valid_r;
    // Memory read/write response
    reg [1:0] mem_breq_dly_r;
    // Memory read/write response valid
    reg mem_breq_valid_r;
    // Memory read/write address
    reg [31:0] mem_addr_dly_r_r;
    // Memory read/write address valid
    reg mem_addr_valid_r_r;
    // Memory read/write enable
    reg [1:0] mem_en_dly_r_r;
    // Memory read/write enable valid
    reg mem_en_valid_r_r;
    // Memory read/write response
    reg [1:0] mem_breq_dly_r_r;
    // Memory read/write response valid
    reg mem_breq_valid_r_r;
    // Memory read/write address
    reg [31:0] mem_addr_dly_r_r_r;
    // Memory read/write address valid
    reg mem_addr_valid_r_r_r;
    // Memory read/write enable
    reg [1:0] mem_en_dly_r_r_r;
    // Memory read/write enable valid
    reg mem_en_valid_r_r_r;
    // Memory read/write response
    reg [1:0] mem_breq_dly_r_r_r;
    // Memory read/write response valid
    reg mem_breq_valid_r_r_r;
    // Memory read/write address
    reg [31:0] mem_addr_dly_r_r_r_r;
    // Memory read/write address valid
    reg mem_addr_valid_r_r_r_r;
    // Memory read/write enable
    reg [1:0] mem_en_dly_r_r_r_r;
    // Memory read/write enable valid
    reg mem_en_valid_r_r_r_r;
    // Memory read/write response
    reg [1:0] mem_breq_dly_r_r_r_r;
    // Memory read/write response valid
    reg mem_breq_valid_r_r_r_r;
    // Memory read/write address
    reg [31:0] mem_addr_dly_r_r_r_r;
    // Memory read/write address valid
    reg mem_addr_valid_r_r_r_r;
    // Memory read/write enable
    reg [1:0] mem_en_dly_r_r_r_r;
    // Memory read/write enable valid
    reg mem_en_valid_r_r_r_r;
    // Memory read/write response
    reg [1:0] mem_breq_dly_r_r_r_r;
    // Memory read/write response valid
    reg mem_breq_valid_r_r_r_r;
    // Memory read/write address
    reg [31:0] mem_addr_dly_r_r_r_r;
    // Memory read/write address valid
    reg mem_addr_valid_r_r_r_r;
    // Memory read/write enable
    reg [1:0] mem_en_dly_r_r_r_r;
    // Memory read/write enable valid
    reg mem_en_valid_r_r_r_r;
    // Memory read/write response
    reg [1:0] mem_breq_dly_r_r_r_r;
    // Memory read/write response valid
    reg mem_breq_valid_r_r_r_r;
    // Memory read/write address
    reg [31:0] mem_addr_dly_r_r_r_r;
    // Memory read/write address valid
    reg mem_addr_valid_r_r_r_r;
    // Memory read/write enable
    reg [1:0] mem_en_dly_r_r_r_r;
    // Memory read/write enable valid
    reg mem_en_valid_r_r_r_r;
    // Memory read/write response
    reg [1:0] mem_breq_dly_r_r_r_r;
    // Memory read/write response valid
    reg mem_breq_valid_r_r_r_r;
    // Memory read/write address
    reg [31:0] mem_addr_dly_r_r_r_r;
    // Memory read/write address valid
    reg mem_addr_valid_r_r_r_r;
    // Memory read/write enable
    reg [1:0] mem_en_dly_r_r_r_r;
    // Memory read/write enable valid
    reg mem_en_valid_r_r_r_r;
    // Memory read/write response
    reg [1:0] mem_breq_dly_r_r_r_r;
    // Memory read/write response valid
    
endmodule
