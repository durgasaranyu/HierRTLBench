// Multiply-accumulate unit. 16-bit unsigned a,b. 32-bit accumulation.
// clear resets acc. en enables accumulation of a*b.
module mac_unit (
    input         clk, rst, clear, en,
    input  [15:0] a, b,
    output reg [31:0] acc
);
    reg [31:0] acc_r;
    always @(posedge clk, posedge rst) begin
        if (rst)
            acc_r <= 0;
        else if (clear)
            acc_r <= 0;
        else if (en)
            acc_r <= a * b;
    end
    assign acc = acc_r;
endmodulemodule mul_unit (
    input         clk, rst, start,
    input  [15:0] a, b,
    output [31:0] acc
);
    reg [15:0] a_r, b_r, acc_r;
    reg [16:0] temp;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            a_r <= 0;
            b_r <= 0;
        end
        else if (start) begin
            a_r <= a;
            b_r <= b;
            acc_r <= 0;
        end
        else begin
            temp <= a_r * b_r;
            acc_r <= acc_r + temp;
        end
    end
    assign acc = acc_r;
endmodulemodule accumlator (
    input         clk, rst, start,
    input  [15:0] a, b,
    output [31:0] acc
);
    reg [31:0] acc_r;
    always @(posedge clk, posedge rst) begin
        if (rst)
            acc_r <= 0;
        else if (start)
            acc_r <= a + b;
    end
    assign acc = acc_r;
endmodulemodule controller (
    input         clk, rst, start, eq, gt, ge, set,
    output reg    start_c, set_c, eq_c, gt_c, ge_c
);
    reg [3:0] state;
    parameter s0=4'b0000, s1=4'b0001, s2=4'b0010, s3=4'b0011, s4=4'b0100, s5=4'b0101, s6=4'b0110, s7=4'b0111, s8=4'b1000, s9=4'b1001;
    always @(posedge clk, posedge rst) begin
        if (rst)
            state <= s0;
        else
            state <= state + 4'b0001;
    end
    always @(state, start, set, eq, gt, ge, start_c, set_c, eq_c, gt_c, ge_c) begin
        start_c = 0;
        set_c    = 0;
        eq_c     = 0;
        gt_c     = 0;
        ge_c     = 0;
        case (state)
            s0: begin
                start_c = start;
                set_c    = set;
                eq_c     = eq;
                gt_c     = gt;
                ge_c     = ge;
                end
            s1: begin
                start_c = 1'b0;
                set_c    = 1'b1;
                eq_c     = 1'b0;
                gt_c     = 1'b0;
                ge_c     = 1'b1;
                end
            s2: begin
                start_c = 1'b0;
                set_c    = 1'b1;
                eq_c     = 1'b1;
                gt_c     = 1'b0;
                ge_c     = 1'b1;
                end
            s3: begin
                start_c = 1'b0;
                set_c    = 1'b1;
                eq_c     = 1'b0;
                gt_c     = 1'b1;
                ge_c     = 1'b0;
                end
            s4: begin
                start_c = 1'b0;
                set_c    = 1'b1;
                eq_c     = 1'b0;
                gt_c     = 1'b1;
                ge_c     = 1'b0;
                end
            s5: begin
                start_c = 1'b0;
                set_c    = 1'b1;
                eq_c     = 1'b0;
                gt_c     = 1'b0;
                ge_c     = 1'b1;
                end
            s6: begin
                start_c = 1'b0;
                set_c    = 1'b1;
                eq_c     = 1'b1;
                gt_c     = 1'b0;
                ge_c     = 1'b1;
                end
            s7: begin
                start_c = 1'b0;
                set_c    = 1'b1;
                eq_c     = 1'b0;
                gt_c     = 1'b1;
                ge_c     = 1'b1;
                end
            s8: begin
                start_c = 1'b0;
                set_c    = 1'b1;
                eq_c     = 1'b1;
                gt_c     = 1'b1;
                ge_c     = 1'b1;
                end
            s9: begin
                start_c = 1'b1;
                set_c    = 1'b0;
                eq_c     = 1'b0;
                gt_c     = 1'b0;
                ge_c     = 1'b0;
                end
            default: begin
                start_c = 1'b0;
                set_c    = 1'b0;
                eq_c     = 1'b0;
                gt_c     = 1'b0;
                ge_c     = 1'b0;
                end
        endcase
    end
endmodulemodule eq1 #(ADDRESS_BUS_SIZE=3, DATA_BUS_SIZE=8) (
    input               clk, rst,
    input       [ADDRESS_BUS_SIZE-1:0] address,
    input       [DATA_BUS_SIZE-1:0] data,
    input               cs, we,
    input               clk_bus,
    output      [DATA_BUS_SIZE-1:0] bus
);
    reg     [DATA_BUS_SIZE-1:0] ram [2**ADDRESS_BUS_SIZE-1:0];
    reg     [DATA_BUS_SIZE-1:0] bus_reg;
    reg     [DATA_BUS_SIZE-1:0] ram_reg;
    reg     [DATA_BUS_SIZE-1:0] ram_reg_bus;
    reg     [DATA_BUS_SIZE-1:0] ram_reg_bus_d;
    reg     [DATA_BUS_SIZE-1:0] ram_reg_d;
    reg     [DATA_BUS_SIZE-1:0] ram_reg_d_bus;
    reg     [DATA_BUS_SIZE-1:0] ram_reg_d_bus_d;
    reg     [DATA_BUS_SIZE-1:0] ram_reg_d_bus_d_bus;
    reg     [DATA_BUS_SIZE-1:0] ram_reg_d_bus_d_bus_d;
    reg     [DATA_BUS_SIZE-1:0] ram_reg_d_bus_d_bus_d_bus;
    reg     [DATA_BUS_SIZE-1:0] ram_reg_d_bus_d_bus_d_bus_d;
    reg     [DATA_BUS_SIZE-1:0] ram_reg_d_bus_d_bus_d_bus_d;
    reg     [DATA_BUS_SIZE-1:0] ram_reg_d_bus_d_bus_d_bus_d;
    reg     [DATA_BUS_SIZE-1:0] ram_reg_d_bus_d_bus_d_bus_d;
    reg     [DATA_BUS_SIZE-1:0] ram_reg_d_bus_d_bus_
endmodule
