// RISC-V forwarding unit. forward_a/b: 00=regfile, 01=MEM/WB, 10=EX/MEM.
module rv_forward (
    input [4:0] id_ex_rs1, id_ex_rs2,
    input [4:0] ex_mem_rd, mem_wb_rd,
    input       ex_mem_reg_write, mem_wb_reg_write,
    output reg [1:0] forward_a, forward_b
);
    always @ (*) begin
        if (ex_mem_reg_write && ex_mem_rd != 0) begin
            forward_a <= 2'b01;
            forward_b <= 2'b10;
        end
        else if (mem_wb_reg_write && mem_wb_rd != 0) begin
            forward_a <= 2'b10;
            forward_b <= 2'b01;
        end
        else begin
            forward_a <= 2'b00;
            forward_b <= 2'b00;
        end
    end
endmodulemodule rv32im_top (
    input        clk,
    input        reset,
    output       mem_en,
    output [31:0] mem_addr,
    output [31:0] mem_wdata,
    output [3:0]  mem_wstrb,
    input [31:0]  mem_rdata,
    // Debug interface
    output [`DMEM_MSB:0] dmem_addr,
    output [`DMEM_MSB:0] dmem_wdata,
    output [`DMEM_MSB:0] dmem_rdata,
    output dmem_ready,
    output [`DBG_WB_MSB:0] dbg_mem_addr,
    output [`DBG_WB_MSB:0] dbg_mem_data,
    output dbg_mem_ack,
    output [`DBG_UART_MSB:0] dbg_uart_addr,
    output [`DBG_UART_MSB:0] dbg_uart_data,
    output dbg_uart_ack
);
    parameter nr_of_wb_ports = 3;
    parameter nr_of_wb_regs = 32;
    parameter nr_of_wb_mem = 2;
    parameter nr_of_wb_mem_cmd = 2;
    parameter nr_of_wb_mem_data = 32;
    parameter nr_of_wb_mem_data_cmd = 2;
    parameter nr_of_wb_irqs = 3;
    parameter nr_of_wb_irq_cmd = 2;
    parameter nr_of_wb_irq_status = 32;
    parameter nr_of_wb_irq_status_cmd = 2;
    parameter nr_of_wb_exception_status = 32;
    parameter nr_of_wb_exception_status_cmd = 2;
    parameter nr_of_wb_exception_isr = 32;
    parameter nr_of_wb_exception_isr_cmd = 2;
    parameter nr_of_wb_exception_eicvector = 32;
    parameter nr_of_wb_exception_eicvector_cmd = 2;
    parameter nr_of_wb_exception_offset = 32;
    parameter nr_of_wb_exception_offset_cmd = 2;
    parameter nr_of_wb_exception_nmi = 32;
    parameter nr_of_wb_exception_nmi_cmd = 2;
    parameter nr_of_wb_exception_int = 32;
    parameter nr_of_wb_exception_int_cmd = 2;
    parameter nr_of_wb_exception_syscall = 32;
    parameter nr_of_wb_exception_syscall_cmd = 2;
    parameter nr_of_wb_exception_trap = 32;
    parameter nr_of_wb_exception_trap_cmd = 2;
    parameter nr_of_wb_exception_itlbmiss = 32;
    parameter nr_of_wb_exception_itlbmiss_cmd = 2;
    parameter nr_of_wb_exception_immufault = 32;
    parameter nr_of_wb_exception_immufault_cmd = 2;
    parameter nr_of_wb_exception_tick = 32;
    parameter nr_of_wb_exception_tick_cmd = 2;
    parameter nr_of_wb_fpu_inst = 32;
    parameter nr_of_wb_fpu_inst_cmd = 2;
    parameter nr_of_wb_fpu_inst_done = 32;
    parameter nr_of_wb_fpu_inst_done_cmd = 2;
    parameter nr_of_wb_fpu_inst_stall = 32;
    parameter nr_of_wb_fpu_inst_stall_cmd = 2;
    parameter nr_of_wb_fpu_inst_cancel = 32;
    parameter nr_of_wb_fpu_inst_cancel_cmd = 2;
    parameter nr_of_wb_fpu_inst_exception = 32;
    parameter nr_of_wb_fpu_inst_exception_cmd = 2;
    parameter nr_of_wb_fpu_inst_stall_cancel = 32;
    parameter nr_of_wb_fpu_inst_stall_cancel_cmd = 2;
    parameter nr_of_wb_fpu_inst_stall_tick = 32;
    parameter nr_of_wb_fpu_inst_stall_tick_cmd = 2;
    parameter nr_of_wb_fpu_inst_done_tick = 32;
    parameter nr_of_wb_fpu_inst_done_tick_cmd = 2;
    parameter nr_of_wb_fpu_inst_stall_fp = 32;
    parameter nr_of_wb_fpu_inst_stall_fp_cmd = 2;
    parameter nr_of_wb_fpu_inst_done_fp = 32;
    parameter nr_of_wb_fpu_inst_done_fp_cmd = 2;
    parameter nr_of_wb_fpu_inst_stall_int = 32;
    parameter nr_of_wb_fpu_inst_stall_int_cmd = 2;
    parameter nr_of_wb_fpu_inst_done_int = 32;
    parameter nr_of_wb_fpu_inst_done_int_cmd = 2;
    parameter nr_of_wb_fpu_inst_stall_sys = 32;
    parameter nr_of_wb_fpu_inst_stall_sys_cmd = 2;
    parameter nr_of_wb_fpu_inst_done_sys = 32;
    parameter nr_of_wb_fpu_inst_done_sys_cmd = 2;
    parameter nr_of_wb_fpu_inst_stall_du = 32;
    parameter nr_of_wb_fpu_inst_stall_du_cmd = 2;
    parameter nr_of_wb_fpu_inst_done_du = 32;
    parameter nr_of_wb_fpu_inst_done_du_cmd = 2;
    parameter nr_of_wb_fpu_inst_stall_ie = 32;
    parameter nr_of_wb_fpu_inst_stall_ie_cmd = 2;
    parameter nr_of_wb_fpu_inst_done_ie = 32;
    parameter nr_of_wb_fpu_inst_done_ie_cmd = 2;
    parameter nr_of_wb_fpu_inst_stall_m = 32;
    parameter nr_of_wb_fpu_inst_stall_m_cmd = 2;
    parameter nr_of_wb_fpu_inst_done_m = 32;
    parameter nr_of_wb_fpu_inst_done_m_cmd = 2;
    parameter nr_of_wb_fpu_inst_stall_w = 32
endmodule
