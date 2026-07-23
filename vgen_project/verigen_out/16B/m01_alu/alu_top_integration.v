`timescale 1ns/1ps
// M01: N-bit ALU integration top
// Instantiates alu_addsub, alu_logic, alu_shift, alu_flags.
// op: 000=ADD 001=SUB 010=AND 011=OR 100=XOR 101=SHL
// Registered outputs on posedge clk, synchronous reset.
module alu_integration #(parameter N = 8) (
    input              clk, rst,
    input  [N-1:0]     a, b,
    input  [2:0]       op,
    output reg [N-1:0] result,
    output reg         zero_flag, carry_flag
);
    // ── submodule output wires ────────────────────────────────────────────────
    wire [N-1:0] add_res, log_res, sh_res;
    wire         add_c, sh_c;

    // alu_addsub: op=0 → ADD, op=1 → SUB (uses op[0])
    alu_addsub #(.N(N)) u_addsub (
        .a(a), .b(b), .op(op[0]),
        .result(add_res), .carry_out(add_c)
    );

    // alu_logic: sel 00=AND 01=OR 10=XOR
    // map ALU op to logic sel
    wire [1:0] log_sel = (op == 3'b010) ? 2'b00 :   // AND
                         (op == 3'b011) ? 2'b01 :   // OR
                         (op == 3'b100) ? 2'b10 :   // XOR
                                          2'b00;
    alu_logic #(.N(N)) u_logic (
        .a(a), .b(b), .sel(log_sel),
        .result(log_res)
    );

    // alu_shift: logical left shift by 1
    alu_shift #(.N(N)) u_shift (
        .a(a), .result(sh_res), .carry_out(sh_c)
    );

    // ── result mux ───────────────────────────────────────────────────────────
    wire [N-1:0] mux_res;
    wire         carry_w;

    assign mux_res = (op[2:1] == 2'b00) ? add_res :   // ADD or SUB
                     (op == 3'b101)      ? sh_res  :   // SHL
                                           log_res;    // AND/OR/XOR

    assign carry_w = (op == 3'b101) ? sh_c : add_c;

    // ── flags ────────────────────────────────────────────────────────────────
    wire zf_w, cf_w;
    alu_flags #(.N(N)) u_flags (
        .result(mux_res), .carry_in(carry_w),
        .zero_flag(zf_w), .carry_flag(cf_w)
    );

    // ── registered outputs ───────────────────────────────────────────────────
    always @(posedge clk) begin
        if (rst) begin
            result     <= {N{1'b0}};
            zero_flag  <= 1'b0;
            carry_flag <= 1'b0;
        end else begin
            result     <= mux_res;
            zero_flag  <= zf_w;
            carry_flag <= cf_w;
        end
    end
endmodule
