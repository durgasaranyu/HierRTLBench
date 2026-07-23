// Hardwired control unit: phases 2 (EX), 3 (MEM), 4 (WB). 7-bit opcode + 3-bit phase input.
// Combinational outputs: pc_write, ir_write, reg_write, mem_write, alu_src_a/b, mem_to_reg, pc_source.
module ctrl_phase234 (
    input  [6:0] opcode,
    input  [2:0] phase,
    output reg   pc_write, ir_write, reg_write, mem_write,
    output reg   alu_src_a, alu_src_b, mem_to_reg, pc_source
);
    always @(*) begin
        case (phase)
            3'b000: begin // Instruction phase, fetch instruction
                pc_write = 1'b0;
                ir_write = 1'b1;
                reg_write = 1'b0;
                mem_write = 1'b0;
                alu_src_a = 1'b0;
                alu_src_b = 2'b00;
                mem_to_reg = 1'b0;
                pc_source = 2'b00;
            end
            3'b001: begin // Instruction phase, fetch instruction
                pc_write = 1'b0;
                ir_write = 1'b1;
                reg_write = 1'b0;
                mem_write = 1'b0;
                alu_src_a = 1'b0;
                alu_src_b = 2'b00;
                mem_to_reg = 1'b0;
                pc_source = 2'b00;
            end
            3'b010: begin // Instruction phase, fetch instruction
                pc_write = 1'b0;
                ir_write = 1'b1;
                reg_write = 1'b0;
                mem_write = 1'b0;
                alu_src_a = 1'b0;
                alu_src_b = 2'b00;
                mem_to_reg = 1'b0;
                pc_source = 2'b00;
            end
            3'b011: begin // Instruction phase, fetch instruction
                pc_write = 1'b0;
                ir_write = 1'b1;
                reg_write = 1'b0;
                mem_write = 1'b0;
                alu_src_a = 1'b0;
                alu_src_b = 2'b00;
                mem_to_reg = 1'b0;
                pc_source = 2'b00;
            end
            3'b100: begin // Instruction phase, fetch instruction
                pc_write = 1'b0;
                ir_write = 1'b1;
                reg_write = 1'b0;
                mem_write = 1'b0;
                alu_src_a = 1'b0;
                alu_src_b = 2'b00;
                mem_to_reg = 1'b0;
                pc_source = 2'b00;
            end
            3'b101: begin // Instruction phase, fetch instruction
                pc_write = 1'b0;
                ir_write = 1'b1;
                reg_write = 1'b0;
                mem_write = 1'b0;
                alu_src_a = 1'b0;
                alu_src_b = 2'b00;
                mem_to_reg = 1'b0;
                pc_source = 2'b00;
            end
            3'b110: begin // Instruction phase, fetch instruction
                pc_write = 1'b0;
                ir_write = 1'b1;
                reg_write = 1'b0;
                mem_write = 1'b0;
                alu_src_a = 1'b0;
                alu_src_b = 2'b00;
                mem_to_reg = 1'b0;
                pc_source = 2'b00;
            end
            3'b111: begin // Instruction phase, fetch instruction
                pc_write = 1'b0;
                ir_write = 1'b1;
                reg_write = 1'b0;
                mem_write = 1'b0;
                alu_src_a = 1'b0;
                alu_src_b = 2'b00;
                mem_to_reg = 1'b0;
                pc_source = 2'b00;
            end
        endcase
    end
endmodule
// --------------------------------------------------------------------
// Copyright (c) 2005 by Terasic Technologies Inc. 
// --------------------------------------------------------------------
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altrea Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL or Verilog source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// --------------------------------------------------------------------
//           
//                     Terasic Technologies Inc
//                     356 Fu-Shin E. Rd Sec. 1. JhuBei City,
//                     HsinChu County, Taiwan
//                     302
//
//                     web: http://www.terasic.com/
//                     email: support@terasic.com
//
// --------------------------------------------------------------------
//
// Major Functions:	DE1 Default Code
//
// --------------------------------------------------------------------
//
// Revision History :
// --------------------------------------------------------------------
//   Ver  :| Author            :| Mod. Date :| Changes Made:
//   V1.0 :| Johnny Chen       :| 06/04/25  :|      Initial Revision
// --------------------------------------------------------------------

module DE1_Default
	(
		////////////////////	Clock Input	 	////////////////////	 
		CLOCK_24,						//	24 MHz
		CLOCK_27,						//	27 MHz
		CLOCK_50,						//	50 MHz
		EXT_CLOCK,						//	External Clock
		////////////////////	Push Button		////////////////////
		KEY,							//	Pushbutton[3:0]
		////////////////////	DPDT Switch		////////////////////
		SW,								//	Toggle Switch[17:0]
		////////////////////	7-SEG Dispaly	////////////////////
		HEX0,							//	Seven Segment Digit 0
		HEX1,							//	Seven Segment Digit 1
		HEX2,							//	Seven Segment Digit 2
		HEX3,							//	Seven Segment Digit 3
		HEX4,							//	Seven Segment Digit 4
		HEX5,							//	Seven Segment Digit 5
		HEX6,							//	Seven Segment Digit 6
		HEX7,							//	Seven Segment Digit 7
		////////////////////////	LED		////////////////////////
		LEDG,							//	LED Green[8:0]
		LEDR,							//	LED Red[17:0]
		////////////////////////	UART	////////////////////////
		UART_TXD,						//	UART Transmitter
		UART_RXD,						//	UART Receiver
		////////////////////////	IRDA	////////////////////////
		IRDA_TXD,						//	IRDA Transmitter
		IRDA_RXD,						//	IRDA Receiver
		////////////////////////	SDRAM Interface		////////////////
		DRAM_DQ,						//	SDRAM Data bus 16 Bits
		DRAM_ADDR,						//	SDRAM Address bus 12 Bits
		DRAM_LDQM,						//	SDRAM Low-byte Data Mask
		DRAM_UDQM,						//	SDRAM High-byte Data Mask
		DRAM_WE_N,						//	SDRAM Write Enable
		DRAM_CAS_N,						//	SDRAM Column Address Strobe
		DRAM_RAS_N,						//	SDRAM Row Address Strobe
		DRAM_CS_N,						//	SDRAM Chip Select
		DRAM_BA_0,						//	SDRAM Bank Address 0
		DRAM_BA_1,						//	SDRAM Bank Address 0
		DRAM_CLK,						//	SDRAM Clock
		DRAM_CKE,						//	SDRAM
endmodule
