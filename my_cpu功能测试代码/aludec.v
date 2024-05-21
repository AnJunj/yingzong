`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:27:24
// Design Name: 
// Module Name: aludec
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "defines2.vh"

module aludec(
	input wire[5:0] funct,
	input wire[3:0] aluop,
	output reg[4:0] alucontrol
    );
    always @(*) begin
		if (aluop == `R_TYPE_OP)
		begin
            case(funct)
                `AND: alucontrol<= `AND_CONTROL;
                `NOR: alucontrol<= `NOR_CONTROL;
                `OR: alucontrol<= `OR_CONTROL;
                `XOR: alucontrol<= `XOR_CONTROL;
                `ADD: alucontrol<= `ADD_CONTROL;
                `ADDU: alucontrol<= `ADDU_CONTROL;
                `SUB: alucontrol<= `SUB_CONTROL;
                `SUBU: alucontrol<= `SUBU_CONTROL;
                `SLT: alucontrol<= `SLT_CONTROL;
                `SLTU: alucontrol<= `SLTU_CONTROL;
                `SLLV: alucontrol<= `SLLV_CONTROL;
                `SLL: alucontrol<= `SLL_CONTROL;
                `SRAV: alucontrol<= `SRAV_CONTROL;
                `SRA: alucontrol<= `SRA_CONTROL;
                `SRLV: alucontrol<= `SRLV_CONTROL;
                `SRL: alucontrol<= `SRL_CONTROL;
                `MULT: alucontrol<= `MULT_CONTROL;
                `MULTU: alucontrol<= `MULTU_CONTROL;
                `DIV: alucontrol<= `DIV_CONTROL;
                `DIVU: alucontrol<= `DIVU_CONTROL;
                `MFHI: alucontrol<= `MFHI_CONTROL;
                `MFLO: alucontrol<= `MFLO_CONTROL;
                `MTHI: alucontrol<= `MTHI_CONTROL;
                `MTLO: alucontrol<= `MTLO_CONTROL;
                default: alucontrol<= `DONOTHING_CONTROL;
            endcase
		end
		else begin 
		     case(aluop)
		          `ANDI_OP: alucontrol<= `AND_CONTROL;
		          `LUI_OP: alucontrol<= `LUI_CONTROL;
		          `ORI_OP: alucontrol<= `OR_CONTROL;
		          `XORI_OP: alucontrol<= `XOR_CONTROL;
		          `ADDI_OP:alucontrol<= `ADD_CONTROL;
			     `ADDIU_OP:alucontrol<= `ADDU_CONTROL;
			     `SLTI_OP:alucontrol<= `SLT_CONTROL;
			     `SLTIU_OP:alucontrol<= `SLTU_CONTROL;
		          default: alucontrol<= `DONOTHING_CONTROL;
		     endcase
		end
    end
endmodule
//module aludec(
//	input wire[5:0] funct,
//	input wire[1:0] aluop,
//	output reg[2:0] alucontrol
//    );
//	always @(*) begin
//		case (aluop)
//			2'b00: alucontrol <= 3'b010;//add (for lw/sw/addi)
//			2'b01: alucontrol <= 3'b110;//sub (for beq)
//			default : case (funct)
//				6'b100000:alucontrol <= 3'b010; //add
//				6'b100010:alucontrol <= 3'b110; //sub
//				6'b100100:alucontrol <= 3'b000; //and
//				6'b100101:alucontrol <= 3'b001; //or
//				6'b101010:alucontrol <= 3'b111; //slt
//				default:  alucontrol <= 3'b000;
//			endcase
//		endcase
	
//	end
//endmodule
