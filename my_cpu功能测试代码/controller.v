`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:21:30
// Design Name: 
// Module Name: controller
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

module controller(
	input wire clk,rst,
	//decode stage
	input wire[5:0] opD,functD,
	output wire pcsrcD,branchD,equalD,jumpD,
	output wire extend_signedD,
	output wire [3:0]pre_branchD,
	input wire [4:0] rtD,
	input wire [4:0] rsD,
	
	//execute stage
	input wire flushE,
	output wire memtoregE,alusrcE,
	output wire regdstE,regwriteE,	
	output wire[4:0] alucontrolE,

	//mem stage
	output wire memtoregM,
				regwriteM,	
	output wire [3:0]memwriteM_o,
	output wire [1:0]data_lengthM,
	output wire ls_extend_signedM,
	//write back stage
	output wire memtoregW,regwriteW_o,
	input wire stall,//此为多种stall的或
	input wire div_stall,
	output wire cp0_weM,
	output wire cp0_readW,
	output wire cp0_weD,
	output wire cp0_readD,
	output wire cp0_readE,
	output wire cp0_readM,
	output wire l_h,
	output wire s_h,
	output wire l_w,
	output wire s_w,
	output wire decode_ft,//指令解码异常 
	output wire break,
	output wire syscall,
	input wire flush_exceptionM,
	input wire flush_exceptionW 
    );
	
	//decode stage
	wire[3:0] aluopD;
	wire memtoregD,alusrcD,
		regdstD,regwriteD;
    wire [3:0]memwriteD;
	wire[4:0] alucontrolD;
	wire [1:0]data_lengthD;
	wire ls_extend_signedD;

	//execute stage
	wire [3:0]memwriteE,memwriteM;
	wire [1:0]data_lengthE;
	wire ls_extend_signedE;
    //cp0写使能
    wire cp0_weE;
    wire decode_f;
    wire regwriteW;
//    wire cp0_readM;
    //exception need
    assign memwriteM_o=flush_exceptionM?4'b0000:memwriteM;
    assign regwriteW_o = (regwriteW & !flush_exceptionW);
	maindec md(
		opD,
		functD,
		rtD,
		rsD,
		memtoregD,memwriteD,
		branchD,alusrcD,
		regdstD,regwriteD,
		jumpD,
		extend_signedD,
		aluopD,
		data_lengthD,
		ls_extend_signedD,
		pre_branchD,
		cp0_weD,
		cp0_readD,
		l_h,
		s_h,
		l_w,
		s_w,
		decode_f,
		break,
		syscall
		);
	aludec ad(functD,aluopD,alucontrolD);
    assign decode_ft = (alucontrolD==`DONOTHING_CONTROL) & decode_f; 
	assign pcsrcD = branchD & equalD;

	//pipeline registers
	flopenrc #(18) regE(
		clk,
		rst,
		~stall,
		flushE|flush_exceptionM,
		{memtoregD,memwriteD,alusrcD,regdstD,regwriteD,alucontrolD,data_lengthD,ls_extend_signedD,cp0_weD,cp0_readD},
		{memtoregE,memwriteE,alusrcE,regdstE,regwriteE,alucontrolE,data_lengthE,ls_extend_signedE,cp0_weE,cp0_readE}
		);
	floprc #(11) regM(
		clk,rst,
		flush_exceptionM,
		{memtoregE,memwriteE,regwriteE,data_lengthE,ls_extend_signedE,cp0_weE,cp0_readE},
		{memtoregM,memwriteM,regwriteM,data_lengthM,ls_extend_signedM,cp0_weM,cp0_readM}
		);
	flopr #(3) regW(
		clk,rst,
		{memtoregM,regwriteM,cp0_readM},
		{memtoregW,regwriteW,cp0_readW}
		);
endmodule


//module controller(
//	input wire clk,rst,
//	//decode stage
//	input wire[5:0] opD,functD,
//	output wire pcsrcD,branchD,equalD,jumpD,
	
//	//execute stage
//	input wire flushE,
//	output wire memtoregE,alusrcE,
//	output wire regdstE,regwriteE,	
//	output wire[2:0] alucontrolE,

//	//mem stage
//	output wire memtoregM,memwriteM,
//				regwriteM,
//	//write back stage
//	output wire memtoregW,regwriteW

//    );
	
//	//decode stage
//	wire[1:0] aluopD;
//	wire memtoregD,memwriteD,alusrcD,
//		regdstD,regwriteD;
//	wire[2:0] alucontrolD;

//	//execute stage
//	wire memwriteE;

//	maindec md(
//		opD,
//		memtoregD,memwriteD,
//		branchD,alusrcD,
//		regdstD,regwriteD,
//		jumpD,
//		aluopD
//		);
//	aludec ad(functD,aluopD,alucontrolD);

//	assign pcsrcD = branchD & equalD;

//	//pipeline registers
//	floprc #(8) regE(
//		clk,
//		rst,
//		flushE,
//		{memtoregD,memwriteD,alusrcD,regdstD,regwriteD,alucontrolD},
//		{memtoregE,memwriteE,alusrcE,regdstE,regwriteE,alucontrolE}
//		);
//	flopr #(8) regM(
//		clk,rst,
//		{memtoregE,memwriteE,regwriteE},
//		{memtoregM,memwriteM,regwriteM}
//		);
//	flopr #(8) regW(
//		clk,rst,
//		{memtoregM,regwriteM},
//		{memtoregW,regwriteW}
//		);
//endmodule
