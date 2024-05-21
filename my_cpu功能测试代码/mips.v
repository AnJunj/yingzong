`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/07 10:58:03
// Design Name: 
// Module Name: mips
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


module mips(
	input wire clk,rst,
	output wire[31:0] pcF,
	input wire[31:0] instrF,
	output wire [3:0]memwriteM,
	output wire[31:0] aluoutM,writedataM,
	input wire[31:0] readdataM,
	input wire[5:0] int_i,
	output wire [31:0]pcW,
	output wire regwriteW,//REG写使能信号
	output wire [4:0]writeregW,//目的寄存器地址
	output wire [31:0]resultW//写回值
    );
	
	wire [5:0] opD,functD;
	wire regdstE,alusrcE,pcsrcD,memtoregE,memtoregM,memtoregW,
			regwriteE,regwriteM;
	wire [4:0] alucontrolE;
	wire flushE,equalD;
	wire extend_signedD,stall,div_stall;
	wire [1:0]data_lengthM;
	wire ls_extend_signedM;
	wire [3:0]pre_branchD;
	wire [4:0]rtD,rsD;
	wire cp0_weD,cp0_readD,cp0_readE,cp0_weM,cp0_readW;
    wire l_h,s_h,l_w,s_w,decode_f,break,syscall;
    wire flush_exceptionM,flush_exceptionW;
//    wire [3:0] memwriteM;
//    assign memwriteM_o =flush_exceptionM?4'b0000:memwriteM;
	controller c(
		clk,rst,
		//decode stage
		opD,functD,
		pcsrcD,branchD,equalD,jumpD,
		extend_signedD,
		pre_branchD,
		rtD,
		rsD,
		//execute stage
		flushE,
		memtoregE,alusrcE,
		regdstE,regwriteE,	
		alucontrolE,

		//mem stage
		memtoregM,
		regwriteM,
		memwriteM,
		data_lengthM,
		ls_extend_signedM,
		//write back stage
		memtoregW,regwriteW,
		stall,
		div_stall,
		cp0_weM,
		cp0_readW,
		cp0_weD,
		cp0_readD,
		cp0_readE,
		cp0_readM,
		l_h,
		s_h,
		l_w,
		s_w,
		decode_f,
		break,
		syscall,
		flush_exceptionM,
		flush_exceptionW
		);
	datapath dp(
		clk,rst,
		//fetch stage
		pcF,
		instrF,
		//decode stage
		pcsrcD,branchD,
		jumpD,
		equalD,
		opD,functD,
		//execute stage
		memtoregE,
		alusrcE,regdstE,
		regwriteE,
		alucontrolE,
		flushE,
		//mem stage
		memtoregM,
		regwriteM,
		aluoutM,writedataM,
		readdataM,
		data_lengthM,
		ls_extend_signedM,
		//writeback stage
		memtoregW,
		regwriteW,
		pcW,
		writeregW,
		resultW,
		extend_signedD,
		stall,
		div_stall,
		pre_branchD,
		rtD,
		rsD,
		cp0_weM,
		cp0_readW,
		cp0_weD,
		cp0_readD,
		cp0_readE,
		cp0_readM,
		l_h,
		s_h,
		l_w,
		s_w,
		decode_f,
		int_i,
		break,
		syscall,
		flush_exceptionM,
		flush_exceptionW
	    );
	//exception
//	wire memaddr_exception;
//	assign memaddr_exception = (memtoregM)||(memwriteM==4'b0001|memwriteM==4'b0011);
endmodule
