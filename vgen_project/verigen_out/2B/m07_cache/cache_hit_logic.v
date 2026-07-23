// Cache hit detection. Compares req_tag vs stored_tag when valid. Selects byte by offset.
module cache_hit_logic (
    input  [23:0] req_tag, stored_tag,
    input  [1:0]  byte_offset,
    input         valid,
    input  [31:0] data,
    output        hit,
    output [7:0]  read_byte
);
    assign hit = (req_tag == stored_tag) & valid;
    assign read_byte = byte_offset[1]? data[7:0] : data[15:8];

endmodule
