// RISC-V hazard detection. Load-use hazard: stall pipeline when id_ex_mem_read and rs match.
module rv_hazard (
    input      id_ex_mem_read,
    input [4:0] id_ex_rd, if_id_rs1, if_id_rs2,
    output reg stall, flush
);
    reg [4:0] reg1, reg2;
    always @(posedge clk) begin
        reg1 <= if_id_rs1;
        reg2 <= if_id_rs2;
    end
    always @(posedge clk) begin
        if (id_ex_mem_read & ((reg1 == id_ex_rd) | (reg2 == id_ex_rd))) begin
            stall <= 1;
            flush <= 1;
        end
        else begin
            stall <= 0;
            flush <= 0;
        end
    end
endmodulemodule ID(
        input wire clk,
        input wire rst,
        input wire [`Instr_width-1:0] instr,
        input wire stall,
        input wire branch,
        input wire [`PC_width-1:0] PC_in,
        input wire [`reg_width-1:0] reg_data1,
        input wire [`reg_width-1:0] reg_data2,
        input wire [`reg_width-1:0] reg_data3,
        input wire [`reg_width-1:0] reg_data4,
        output reg [`Instr_width-1:0] instr_ID_out,
        output reg [`PC_width-1:0] PC_ID_out,
        output reg [`reg_width-1:0] reg_data1_ID_out,
        output reg [`reg_width-1:0] reg_data2_ID_out,
        output reg [`reg_width-1:0] reg_data3_ID_out,
        output reg [`reg_width-1:0] reg_data4_ID_out
    );
    always @(posedge clk) begin
        if (rst) begin
            instr_ID_out <= 0;
            PC_ID_out <= 0;
            reg_data1_ID_out <= 0;
            reg_data2_ID_out <= 0;
            reg_data3_ID_out <= 0;
            reg_data4_ID_out <= 0;
        end
        else begin
            instr_ID_out <= instr;
            PC_ID_out <= PC_in;
            reg_data1_ID_out <= reg_data1;
            reg_data2_ID_out <= reg_data2;
            reg_data3_ID_out <= reg_data3;
            reg_data4_ID_out <= reg_data4;
        end
    end
endmodulemodule EX(
        input wire clk,
        input wire rst,
        input wire [`Instr_width-1:0] instr,
        input wire [`reg_width-1:0] reg_data1,
        input wire [`reg_width-1:0] reg_data2,
        input wire [`reg_width-1:0] reg_data3,
        input wire [`reg_width-1:0] reg_data4,
        input wire [`PC_width-1:0] PC_in,
        input wire [`MUX_width-1:0] ALU_in_Sel,
        input wire ALU_in_Val,
        input wire [`MUX_width-1:0] ALU_out_Sel,
        output reg [`MUX_width-1:0] ALU_out_Val,
        output reg [`reg_width-1:0] reg_data1_out,
        output reg [`reg_width-1:0] reg_data2_out,
        output reg [`reg_width-1:0] reg_data3_out,
        output reg [`reg_width-1:0] reg_data4_out,
        output reg [`PC_width-1:0] PC_out,
        output reg [`ALU_width-1:0] ALU_out
    );
    always @(posedge clk) begin
        if (rst) begin
            ALU_out_Val <= 0;
            reg_data1_out <= 0;
            reg_data2_out <= 0;
            reg_data3_out <= 0;
            reg_data4_out <= 0;
            PC_out <= 0;
            ALU_out <= 0;
        end
        else begin
            ALU_out_Val <= ALU_out_Sel ? ALU_out : ALU_in_Val;
            reg_data1_out <= reg_data1_Sel ? reg_data1 : reg_data1_in;
            reg_data2_out <= reg_data2_Sel ? reg_data2 : reg_data2_in;
            reg_data3_out <= reg_data3_Sel ? reg_data3 : reg_data3_in;
            reg_data4_out <= reg_data4_Sel ? reg_data4 : reg_data4_in;
            PC_out <= PC_in;
            ALU_out <= ALU_in_Sel ? ALU_out_Val : ALU_out;
        end
    end
endmodulemodule MEM(
        input wire rst,
        input wire rd_enable_in,
        input wire [`reg_width-1:0] rd_addr_in,
        input wire [`reg_width-1:0] rd_num_in,
        input wire [`DATA_WIDTH-1:0] val_store_num,
        input wire [`DATA_WIDTH-1:0] val_store_and_load_addr,
        input wire val_store_enable,
        input wire val_load_enable,
        input wire mem_ctrl_enable_in,
        input wire mem_ctrl_if_busy_in,
        input wire mem_ctrl_mem_busy_in,
        input wire [`mem_addr_width-1:0] mem_ctrl_addr_in,
        input wire [`mem_data_width-1:0] mem_ctrl_data_in,
        output reg mem_ctrl_enable_out,
        output reg mem_ctrl_rw_status_out,
        output reg [`mem_addr_width-1:0] mem_ctrl_addr_out,
        output reg [`mem_data_width-1:0] mem_ctrl_data_out,
        output reg [`mem_data_width-1:0] mem_ctrl_data_len_out,
        output reg stall_from_mem,
        output reg rd_enable_out,
        output reg [`reg_width-1:0] rd_data_out,
        output reg [`mem_addr_width-1:0] rd_addr_out
    );
    always @(posedge clk) begin
        if(rst) begin
            mem_ctrl_enable_out <= 0;
            mem_ctrl_rw_status_out <= 0;
            mem_ctrl_addr_out <= 0;
            mem_ctrl_data_out <= 0;
            mem_ctrl_data_len_out <= 0;
            stall_from_mem <= 0;
            rd_enable_out <= 0;
            rd_data_out <= 0;
            rd_addr_out <= 0;
        end
        else begin
            mem_ctrl_enable_out <= mem_ctrl_enable_in;
            mem_ctrl_rw_status_out <= mem_ctrl_rw_status_in;
            mem_ctrl_addr_out <= mem_ctrl_addr_in;
            mem_ctrl_data_out <= mem_ctrl_data_in;
            mem_ctrl_data_len_out <= mem_ctrl_data_len_in;
            stall_from_mem <= mem_ctrl_stall_in;
            rd_enable_out <= rd_enable_in;
            rd_data_out <= rd_data_in;
            rd_addr_out <= rd_addr_in;
        end
    end
endmodulemodule MEM_WB(
        input wire clk,
        input wire rst,
        input wire [`mem_addr_width-1:0] mem_addr,
        input wire [`mem_data_width-1:0] mem_data,

endmodule
