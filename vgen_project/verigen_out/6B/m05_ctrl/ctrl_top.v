// Hardwired control unit top: 7-bit opcode, 3-bit phase. All 5 phases covered.
// Instantiates phase01 and phase234, merges outputs.
module hardwired_ctrl (
    input  [6:0] opcode,
    input  [2:0] phase,
    output       pc_write, ir_write, reg_write, mem_write,
    output       alu_src_a, alu_src_b, mem_to_reg, pc_source
);
    reg reg_pc_write, reg_ir_write, reg_reg_write, mem_write;
    reg [2:0] alu_src_a, alu_src_b;
    reg [2:0] mem_to_reg;
    reg [2:0] pc_source;
    always @(*) begin
        case (phase)
            `PHASE_1: begin
                reg_pc_write = 1;
                reg_ir_write = 0;
                reg_reg_write = 0;
                mem_write = 0;
                alu_src_a = `SRC_A_IDX;
                alu_src_b = `SRC_B_IDX;
                mem_to_reg = `MEM_TO_REG_IDX;
                pc_source = `PC_SRC_IDX;
            end
            `PHASE_2: begin
                reg_pc_write = 0;
                reg_ir_write = 1;
                reg_reg_write = 0;
                mem_write = 0;
                alu_src_a = `ALU_SRC_A_IDX;
                alu_src_b = `ALU_SRC_B_IDX;
                mem_to_reg = `MEM_TO_REG_IDX;
                pc_source = `PC_SRC_IDX;
            end
            `PHASE_3: begin
                reg_pc_write = 0;
                reg_ir_write = 0;
                reg_reg_write = 1;
                mem_write = 0;
                alu_src_a = `ALU_SRC_A_IDX;
                alu_src_b = `ALU_SRC_B_IDX;
                mem_to_reg = `MEM_TO_REG_IDX;
                pc_source = `PC_SRC_IDX;
            end
            `PHASE_4: begin
                reg_pc_write = 0;
                reg_ir_write = 0;
                reg_reg_write = 0;
                mem_write = 1;
                alu_src_a = `SRC_A_IDX;
                alu_src_b = `SRC_B_IDX;
                mem_to_reg = `MEM_TO_REG_IDX;
                pc_source = `PC_SRC_IDX;
            end
            default: begin
                reg_pc_write = 0;
                reg_ir_write = 0;
                reg_reg_write = 0;
                mem_write = 0;
                alu_src_a = `SRC_A_IDX;
                alu_src_b = `SRC_B_IDX;
                mem_to_reg = `MEM_TO_REG_IDX;
                pc_source = `PC_SRC_IDX;
            end
        endcase
    end
endmodule
//
//  HW6.v
//  HW6.v
//
//  Created by: Synopsys DC Ultra(TM) in wire load mode
//  Author      : Synopsys DC Ultra(TM) in wire load mode
//  Version     : P-2019.03-SP1-1
//  Date        : Sat Jan 25 17:55:25 2020
//
//  Pipeline ID: netgen
//  Description: HW6.v
//
//  `include "HW6.v"

`timescale 1ns/1ps

module HW6_tb ();

  // Testbench uses a 10 ns clock
  // Want to interface to 100 MHz system clock
  // 100 MHz system clock
  reg        clk_100MHz;
  reg        rst_n;
  wire       clk_5KHz;
  wire       out_port;
  wire       clk_1Hz;
  wire       clk_2Hz;
  wire       clk_50Hz;
  wire       clk_100Hz;
  wire       clk_500Hz;
  wire       clk_1KHz;
  wire       clk_5KHz;
  wire       clk_10KHz;
  wire       clk_20KHz;
  wire       clk_40KHz;
  wire       clk_80KHz;
  wire       clk_160KHz;
  wire       clk_320KHz;
  wire       clk_640KHz;
  wire       clk_1280KHz;
  wire       clk_2560KHz;
  wire       clk_5120KHz;
  wire       clk_10240KHz;
  wire       clk_20480KHz;
  wire       clk_1048576KHz;
  wire       clk_219728KHz;
  wire       clk_439296KHz;
  wire       clk_786432KHz;
  wire       clk_1572864KHz;
  wire       clk_3174608KHz;
  wire       clk_633600KHz;
  wire       clk_12582912KHz;
  wire       clk_259216KHz;
  wire       clk_518432KHz;
  wire       clk_1058464KHz;
  wire       clk_2199023KHz;
  wire       clk_4392384KHz;
  wire       clk_78582912KHz;
  wire       clk_157288960KHz;
  wire       clk_317475296KHz;
  wire       clk_633760KHz;
  wire       clk_125829376KHz;
  wire       clk_259250336KHz;
  wire       clk_5092544KHz;
  wire       clk_104857664KHz;
  wire       clk_219902384KHz;
  wire       clk_439238416KHz;
  wire       clk_785829376KHz;
  wire       clk_15728896096KHz;
  wire       clk_31747529616KHz;
  wire       clk_63376064KHz;
  wire       clk_12582937616KHz;
  wire       clk_25925033616KHz;
  wire       clk_509254416KHz;
  reg        clk_50;
  reg        rst_50;
  reg        clk_25;
  reg        rst_25;
  reg        clk_24;
  reg        rst_24;
  reg        clk_23;
  reg        rst_23;
  reg        clk_22;
  reg        rst_22;
  reg        clk_21;
  reg        rst_21;
  reg        clk_20;
  reg        rst_20;
  reg        clk_19;
  reg        rst_19;
  reg        clk_18;
  reg        rst_18;
  reg        clk_17;
  reg        rst_17;
  reg        clk_16;
  reg        rst_16;
  reg        clk_15;
  reg        rst_15;
  reg        clk_14;
  reg        rst_14;
  reg        clk_13;
  reg        rst_13;
  reg        clk_12;
  reg        rst_12;
  reg        clk_11;
  reg        rst_11;
  reg        clk_10;
  reg        rst_10;
  reg        clk_9;
  reg        rst_9;
  reg        clk_8;
  reg        rst_8;
  reg        clk_7;
  reg        rst_7;
  reg        clk_6;
  reg        rst_6;
  reg        clk_5;
  reg        rst_5;
  reg        clk
endmodule
