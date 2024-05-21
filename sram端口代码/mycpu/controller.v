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

module controller(
	input wire clk,rst,
	//decode stage
	input wire[5:0] opD,functD,
	output wire pcsrcD,branchD,equalD,jumpD,
	output wire extend_signedD,
	output wire [3:0]pre_branchD,
	input wire [4:0] rtD,
	
	
	//execute stage
	input wire flushE,
	output wire memtoregE,alusrcE,
	output wire regdstE,regwriteE,	
	output wire[4:0] alucontrolE,

	//mem stage
	output wire memtoregM,
				regwriteM,	
	output wire [3:0]memwriteM,
	output wire [1:0]data_lengthM,
	output wire ls_extend_signedM,
	//write back stage
	output wire memtoregW,regwriteW,
	input wire stall,//此为多种stall的或
	input wire div_stall
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
	wire [3:0]memwriteE;
	wire [1:0]data_lengthE;
	wire ls_extend_signedE;

	maindec md(
		opD,
		functD,
		rtD,
		memtoregD,memwriteD,
		branchD,alusrcD,
		regdstD,regwriteD,
		jumpD,
		extend_signedD,
		aluopD,
		data_lengthD,
		ls_extend_signedD,
		pre_branchD
		);
	aludec ad(functD,aluopD,alucontrolD);

	assign pcsrcD = branchD & equalD;

	//pipeline registers
	flopenrc #(16) regE(
		clk,
		rst,
		~stall,
		flushE,
		{memtoregD,memwriteD,alusrcD,regdstD,regwriteD,alucontrolD,data_lengthD,ls_extend_signedD},
		{memtoregE,memwriteE,alusrcE,regdstE,regwriteE,alucontrolE,data_lengthE,ls_extend_signedE}
		);
	flopr #(9) regM(
		clk,rst,
		{memtoregE,memwriteE,regwriteE,data_lengthE,ls_extend_signedE},
		{memtoregM,memwriteM,regwriteM,data_lengthM,ls_extend_signedM}
		);
	flopr #(8) regW(
		clk,rst,
		{memtoregM,regwriteM},
		{memtoregW,regwriteW}
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
