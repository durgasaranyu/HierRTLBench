// RISC CPU register file. 32x32-bit. Async read rs1,rs2. Sync write on we. x0=0.
module cpu_regfile (
    input        clk,
    input [4:0]  rs1, rs2, rd,
    input [31:0] wdata,
    input        we,
    output [31:0] rdata1, rdata2
);
    reg [31:0] regfile [31:0];
    integer i;
    initial begin
        for (i=0; i<32; i=i+1) begin
            regfile[i] = (i %2) ? 0 : i;
        end
    end
    always @(posedge clk) begin
        if (we)
            regfile[rd] <= wdata;
        else
            rdata1 <= regfile[rs1];
        rdata2 <= regfile[rs2];
    end
endmodule

// RISC CPU with 32-bit register file, 32-bit program counter, and 32-bit instruction memory.
module cpu (
    input        clk,
    input        reset,      // Active-high synchronous reset
    output [31:0] iaddr,
    output [31:0] idata,
    output [31:0] daddr,
    output [31:0] drdata,
    output [31:0] dwdata,
    output [3:0] we
);
    parameter dw = `OR1200_OPERAND_WIDTH;
    parameter aw = `OR1200_OPERAND_WIDTH;
    parameter ppic_ints = `OR1200_PIC_INTS;
    parameter boot_adr = `OR1200_BOOT_ADR;
    parameter rom_adr = `OR1200_ROM_ADR;
    parameter fpu_adr = `OR1200_FPU_ADR;
    parameter epcr_adr = `OR1200_EPCR_ADR;
    parameter eear_adr = `OR1200_EEAR_ADR;
    parameter esr_adr = `OR1200_ESR_ADR;
    parameter fpcsr_adr = `OR1200_FPCSR_ADR;
    parameter sr_adr = `OR1200_SR_ADR;
    parameter epcr_we = `OR1200_EPCR_WE;
    parameter eear_we = `OR1200_EEAR_WE;
    parameter esr_we = `OR1200_ESR_WE;
    parameter fpcsr_we = `OR1200_FPCSR_WE;
    parameter sr_we = `OR1200_SR_WE;
    parameter fpu_we = 4'b0000;
    parameter pc_we = 4'b0000;
    parameter epcr_we = `OR1200_EPCR_WE;
    parameter eear_we = `OR1200_EEAR_WE;
    parameter esr_we = `OR1200_ESR_WE;
    parameter fpcsr_we = `OR1200_FPCSR_WE;
    parameter sr_we = `OR1200_SR_WE;
    parameter fpu_sr_we = 0;
    parameter fpu_arith_done = 0;
    parameter fpu_conv_done = 0;
    parameter fpu_comp_done = 0;
    parameter fpu_rmode_r = 0;
    parameter fpu_rmode_i = 0;
    parameter fpu_rmode_m = 0;
    parameter fpu_rmode_w = 0;
    parameter fpu_fract_28_i = 0;
    parameter fpu_fract_28_m = 0;
    parameter fpu_fract_28_w = 0;
    parameter fpu_exp_i = 0;
    parameter fpu_exp_m = 0;
    parameter fpu_exp_w = 0;
    parameter fpu_sign_i = 0;
    parameter fpu_sign_m = 0;
    parameter fpu_sign_w = 0;
    parameter fpu_r_sign_i = 0;
    parameter fpu_r_sign_m = 0;
    parameter fpu_r_sign_w = 0;
    parameter fpu_fract_28_r_sign_i = 0;
    parameter fpu_fract_28_r_sign_m = 0;
    parameter fpu_fract_28_r_sign_w = 0;
    parameter fpu_rmode_r_sign_i = 0;
    parameter fpu_rmode_r_sign_m = 0;
    parameter fpu_rmode_r_sign_w = 0;
    parameter fpu_fract_28_i_sign = 0;
    parameter fpu_fract_28_m_sign = 0;
    parameter fpu_fract_28_w_sign = 0;
    parameter fpu_exp_i_sign = 0;
    parameter fpu_exp_m_sign = 0;
    parameter fpu_exp_w_sign = 0;
    parameter fpu_sign_i_sign = 0;
    parameter fpu_sign_m_sign = 0;
    parameter fpu_sign_w_sign = 0;
    parameter fpu_r_sign_i_sign = 0;
    parameter fpu_r_sign_m_sign = 0;
    parameter fpu_r_sign_w_sign = 0;
    parameter fpu_fract_28_r_sign_i_sign = 0;
    parameter fpu_fract_28_r_sign_m_sign = 0;
    parameter fpu_fract_28_r_sign_w_sign = 0;
    parameter fpu_rmode_r_sign_i_sign = 0;
    parameter fpu_rmode_r_sign_m_sign = 0;
    parameter fpu_rmode_r_sign_w_sign = 0;
    parameter fpu_fract_28_i_sign_rnd = 0;
    parameter fpu_fract_28_m_sign_rnd = 0;
    parameter fpu_fract_28_w_sign_rnd = 0;
    parameter fpu_exp_i_sign_rnd = 0;
    parameter fpu_exp_m_sign_rnd = 0;
    parameter fpu_exp_w_sign_rnd = 0;
    parameter fpu_sign_i_sign_rnd = 0;
    parameter fpu_sign_m_sign_rnd = 0;
    parameter fpu_sign_w_sign_rnd = 0;
    parameter fpu_r_sign_i_sign_rnd = 0;
    parameter fpu_r_sign_m_sign_rnd = 0;
    parameter fpu_r_sign_w_sign_rnd = 0;
    parameter fpu_fract_28_i_sign_rnd = 0;
    parameter fpu_fract_28_m_sign_rnd = 0;
    parameter fpu_fract_28_w_sign_rnd = 0;
    parameter fpu_exp_i_sign_rnd_fpu = 0;
    parameter fpu_exp_m_sign_rnd_fpu = 0;
    parameter fpu_exp_w_sign_rnd_fpu = 0;
    parameter fpu_sign_i_sign_rnd_fpu = 0;
    parameter fpu_sign_m_sign_rnd_fpu = 0;
    parameter fpu_sign_w_sign_rnd_fpu = 0;
    parameter fpu_r_sign_i_sign_rnd_fpu = 0;
    parameter fpu_r_sign_m_sign_rnd_fpu = 0;
    parameter fpu_r_sign_w_sign_rnd_fpu = 0;
    parameter [8:0] fpu_fract_28_i_rnd = 0;
    parameter [8:0] fpu_fract_28_m_rnd = 0;
    parameter [8:0] fpu_fract_28_w_rnd = 0;
    parameter [8:0] fpu_fract
endmodule
