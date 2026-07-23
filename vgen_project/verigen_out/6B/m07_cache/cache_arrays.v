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
    // tag array
    reg [`TAG_WIDTH - 1:0] tag [`T_ENTRIES-1:0];
    // tag entries
    reg [`TAG_WIDTH - 1:0] tag_entries [`T_ENTRIES-1:0];
    // data array
    reg [`DATA_WIDTH - 1:0] data [`D_ENTRIES-1:0];
    // data entries
    reg [`DATA_WIDTH - 1:0] data_entries [`D_ENTRIES-1:0];
    // tag entry
    reg [`TAG_WIDTH - 1:0] tag_entry;
    // data entry
    reg [`DATA_WIDTH - 1:0] data_entry;
    // temporary variables
    reg [`TAG_WIDTH - 1:0] tag_entry_1;
    reg [`DATA_WIDTH - 1:0] data_entry_1;
    reg [`TAG_WIDTH - 1:0] tag_entry_2;
    reg [`DATA_WIDTH - 1:0] data_entry_2;
    reg [`TAG_WIDTH - 1:0] tag_entry_3;
    reg [`DATA_WIDTH - 1:0] data_entry_3;
    reg [`TAG_WIDTH - 1:0] tag_entry_4;
    reg [`DATA_WIDTH - 1:0] data_entry_4;
    reg [`TAG_WIDTH - 1:0] tag_entry_5;
    reg [`DATA_WIDTH - 1:0] data_entry_5;
    reg [`TAG_WIDTH - 1:0] tag_entry_6;
    reg [`DATA_WIDTH - 1:0] data_entry_6;
    reg [`TAG_WIDTH - 1:0] tag_entry_7;
    reg [`DATA_WIDTH - 1:0] data_entry_7;
    reg [`TAG_WIDTH - 1:0] tag_entry_8;
    reg [`DATA_WIDTH - 1:0] data_entry_8;
    reg [`TAG_WIDTH - 1:0] tag_entry_9;
    reg [`DATA_WIDTH - 1:0] data_entry_9;
    reg [`TAG_WIDTH - 1:0] tag_entry_10;
    reg [`DATA_WIDTH - 1:0] data_entry_10;
    reg [`TAG_WIDTH - 1:0] tag_entry_11;
    reg [`DATA_WIDTH - 1:0] data_entry_11;
    reg [`TAG_WIDTH - 1:0] tag_entry_12;
    reg [`DATA_WIDTH - 1:0] data_entry_12;
    reg [`TAG_WIDTH - 1:0] tag_entry_13;
    reg [`DATA_WIDTH - 1:0] data_entry_13;
    reg [`TAG_WIDTH - 1:0] tag_entry_14;
    reg [`DATA_WIDTH - 1:0] data_entry_14;
    reg [`TAG_WIDTH - 1:0] tag_entry_15;
    reg [`DATA_WIDTH - 1:0] data_entry_15;
    reg [`TAG_WIDTH - 1:0] tag_entry_16;
    reg [`DATA_WIDTH - 1:0] data_entry_16;
    reg [`TAG_WIDTH - 1:0] tag_entry_17;
    reg [`DATA_WIDTH - 1:0] data_entry_17;
    reg [`TAG_WIDTH - 1:0] tag_entry_18;
    reg [`DATA_WIDTH - 1:0] data_entry_18;
    reg [`TAG_WIDTH - 1:0] tag_entry_19;
    reg [`DATA_WIDTH - 1:0] data_entry_19;
    reg [`TAG_WIDTH - 1:0] tag_entry_20;
    reg [`DATA_WIDTH - 1:0] data_entry_20;
    reg [`TAG_WIDTH - 1:0] tag_entry_21;
    reg [`DATA_WIDTH - 1:0] data_entry_21;
    reg [`TAG_WIDTH - 1:0] tag_entry_22;
    reg [`DATA_WIDTH - 1:0] data_entry_22;
    reg [`TAG_WIDTH - 1:0] tag_entry_23;
    reg [`DATA_WIDTH - 1:0] data_entry_23;
    reg [`TAG_WIDTH - 1:0] tag_entry_24;
    reg [`DATA_WIDTH - 1:0] data_entry_24;
    reg [`TAG_WIDTH - 1:0] tag_entry_25;
    reg [`DATA_WIDTH - 1:0] data_entry_25;
    reg [`TAG_WIDTH - 1:0] tag_entry_26;
    reg [`DATA_WIDTH - 1:0] data_entry_26;
    reg [`TAG_WIDTH - 1:0] tag_entry_27;
    reg [`DATA_WIDTH - 1:0] data_entry_27;
    reg [`TAG_WIDTH - 1:0] tag_entry_28;
    reg [`DATA_WIDTH - 1:0] data_entry_28;
    reg [`TAG_WIDTH - 1:0] tag_entry_29;
    reg [`DATA_WIDTH - 1:0] data_entry_29;
    reg [`TAG_WIDTH - 1:0] tag_entry_30;
    reg [`DATA_WIDTH - 1:0] data_entry_30;
    reg [`TAG_WIDTH - 1:0] tag_entry_31;
    reg [`DATA_WIDTH - 1:0] data_entry_31;
    reg [`TAG_WIDTH - 1:0] tag_entry_32;
    reg [`DATA_WIDTH - 1:0] data_entry_32;
    reg [`TAG_WIDTH - 1:0] tag_entry_33;
    reg [`DATA_WIDTH - 1:0] data_entry_33;
    reg [`TAG_WIDTH - 1:0] tag_entry_34;
    reg [`DATA_WIDTH - 1:0] data_entry_34;
    reg [`TAG_WIDTH - 1:0] tag_entry_35;
    reg [`DATA_WIDTH - 1:0] data_entry_35;
    reg [`TAG_WIDTH - 1:0] tag_entry_36;
    reg [`DATA_WIDTH - 1:0] data_entry_36;
    reg [`TAG_WIDTH - 1:0] tag_entry_37;
    reg [`DATA_WIDTH - 1:0] data_entry_37;
    reg [`TAG_WIDTH - 1:0] tag_entry_38;
    reg [`DATA_WIDTH - 1:0] data_entry_38;
    reg [`TAG_WIDTH - 1:0] tag_entry_39;
    reg [`DATA_WIDTH - 1:0] data_entry_39;
    reg [`TAG_WIDTH - 1:0] tag_entry_40;
    reg [`DATA_WIDTH - 1:0] data_entry_40;
    reg [`TAG_WIDTH - 1:0] tag_entry_41;
    reg [`DATA_WIDTH - 1:0] data_entry
endmodule
