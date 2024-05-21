`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/02 15:12:22
// Design Name: 
// Module Name: datapath
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

module datapath(
	input wire clk,rst,
	//fetch stage
	output wire[31:0] pcF,
	input wire[31:0] instrF,
	//decode stage
	input wire pcsrcD,branchD,
	input wire jumpD,
	output wire equalD,//此equalD代表的是满足跳转条件
	output wire[5:0] opD,functD,
	//execute stage
	input wire memtoregE,
	input wire alusrcE,regdstE,
	input wire regwriteE,
	input wire[4:0] alucontrolE,
	output wire flushE,
	//mem stage
	input wire memtoregM,
	input wire regwriteM,
	output wire[31:0] aluoutM,writedataM,
	input wire[31:0] readdataM,
	input wire[1:0] data_lengthM,
	input wire ls_extend_signedM,
	//writeback stage
	input wire memtoregW,
	input wire regwriteW,
	output wire [31:0] pcW,
	output wire [4:0] writeregW,
	output wire [31:0]resultW,
	//ex
	input wire extend_signed,
	output wire stall,//只要有暂停就都要让D-》E的信号传播停止
    output wire div_stall,//当遇到div_stall后要使得整体流水线都停下来
	input wire [3:0]pre_branch,
	output wire[4:0]rtD
    );
    
	//fetch stage
	wire stallF;
	//FD
	wire [31:0] pcnextFD,pcnextbrFD,pcplus4F,pcbranchD;
	//decode stage
	wire [31:0] pcD;
	wire [31:0] pcplus4D,instrD;
	wire forwardaD,forwardbD;
	wire [4:0] rsD,rdD;
	wire flushD,stallD,stall_al;
	wire [31:0] signimmD,signimmshD;
	wire [31:0] srcaD,srca2D,srcbD,srcb2D;
	//execute stage
	wire [31:0] pcE;
	wire [1:0] forwardaE,forwardbE;
	wire [4:0] rsE,rtE,rdE;
	wire [4:0] writeregE;
	wire [31:0] signimmE;
	wire [31:0] srcaE,srca2E,srcbE,srcb2E,srcb3E;
	wire [31:0] aluoutE;
	//mem stage
	wire [31:0] pcM;
	wire [4:0] writeregM;
	//writeback stage
	
	wire [31:0] aluoutW,readdataW;
    //hilo
    wire [31:0] hiE,loE,hiM,loM,hi_oE,lo_oE;
    //alu
    wire overflow,zero,mult_stall;
	//hazard detection
	hazard h(
		//fetch stage
		stallF,
		//decode stage
		rsD,rtD,
		branchD,
		forwardaD,forwardbD,
		stallD,
		//execute stage
		rsE,rtE,
		writeregE,
		regwriteE,
		memtoregE,
		forwardaE,forwardbE,
		flushE,
		//mem stage
		writeregM,
		regwriteM,
		memtoregM,
		//write back stage
		writeregW,
		regwriteW
		);
	//next PC logic (operates in fetch an decode)
	mux2 #(32) pcbrmux(pcplus4F,pcbranchD,pcsrcD,pcnextbrFD);
	//需要修改
	wire [31:0]pcnextFD_temp;//存的是jumpD筛选后的pc值
	mux2 #(32) pcmux(pcnextbrFD,
		{pcplus4D[31:28],instrD[25:0],2'b00},
		jumpD,pcnextFD_temp);
	wire signal;
	assign signal=(pre_branch==4'b1010)|(pre_branch==4'b1011)?1'b1:1'b0;
	mux2 #(32) pcmux2(pcnextFD_temp,srca2D,signal,pcnextFD);

	//regfile (operates in decode and writeback)
	regfile rf(clk,regwriteW,rsD,rtD,writeregW,resultW,srcaD,srcbD);
    wire Hi_Lo_weE,Hi_Lo_weM;
//    assign Hi_Lo_we = (alucontrolE==`MULT_CONTROL)||(alucontrolE==`MULTU_CONTROL)||(alucontrolE==`DIV_CONTROL)||(alucontrolE==`DIVU_CONTROL);
    Hi_Lo hl(.clk(~clk),
             .rst(rst),
             .we(Hi_Lo_weM),
             .hi_i(hiM),
             .lo_i(loM),
             .hi_o(hi_oE),
             .lo_o(lo_oE)
    );
    
     wire jr_storeD;
     wire brs_storeD;
    assign stall=div_stall|stall_al|jr_storeD|brs_storeD;//对controller整体进行stall
	//fetch stage logic
	pc #(32) pcreg(clk,rst,~(stallF|div_stall|stall_al|jr_storeD|brs_storeD),pcnextFD,pcF);
	adder pcadd1(pcF,32'b100,pcplus4F);
	//decode stage
	flopenr #(32) r1D(clk,rst,~(stallD|div_stall|stall_al|jr_storeD|brs_storeD),pcplus4F,pcplus4D);
	flopenrc #(32) r2D(clk,rst,~(stallD|div_stall|stall_al|jr_storeD|brs_storeD),flushD,instrF,instrD);
	flopenrc #(32) r3D(clk,rst,~(stallD|div_stall|stall_al|jr_storeD|brs_storeD),flushD,pcF,pcD);//推pcW
	signext se(instrD[15:0],extend_signed,signimmD);
	sl2 immsh(signimmD,signimmshD);
	adder pcadd2(pcplus4D,signimmshD,pcbranchD);
	//a的前推
	wire [31:0]srca2D_temp;
	mux2 #(32) forwardamux(srcaD,aluoutM,forwardaD,srca2D_temp);//正常前推
	wire [31:0]pc8D,pc8E,pc8M,pc8W;
	wire link_storeD,link_storeE,link_storeM,link_storeW;
	mux2 #(32) forwardamux_1(srca2D_temp,pc8M,(link_storeM)&forwardaD,srca2D);//前推的基础上如果是link_store所涉及到的四条指令，则前推值为pc8M
	//b的前推
	wire [31:0]srcb2D_temp;
	mux2 #(32) forwardbmux(srcbD,aluoutM,forwardbD,srcb2D_temp);//正常前推
	mux2 #(32) forwardbmux_1(srcb2D_temp,pc8M,(link_storeM)&forwardbD,srcb2D);//前推的基础上如果是link_store所涉及到的四条指令，则前推值为pc8M

//	eqcmp comp(srca2D,srcb2D,equalD);
    comp_branch cb(srca2D,srcb2D,pre_branch,equalD);
	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];
    //sa
    wire[4:0] saD,saE;
    assign saD = instrD[10:6];
    //link类指令的操作

//    wire [1:0]dest_reg;//00,不变；01，31；10，rd
    wire jalrD,jalrE;
    assign jalrD=(pre_branch==4'b1011)?1:0;
    assign link_storeD= (pre_branch==4'b0110|pre_branch==4'b0111|pre_branch==4'b1001|pre_branch==4'b1011)? 1:0;//该信号是多路选择器
    //jr_sroreD不仅与JR类型有关，还与beq,bne有关
    assign jr_storeD= (pre_branch==4'b1010|pre_branch==4'b1011|pre_branch==4'b0000|pre_branch==4'b0001)&((rsD != 0 & rsD == writeregE & regwriteE)|(rtD != 0 & rtD == writeregE & regwriteE));
    assign brs_storeD= (pre_branch==4'b0010|pre_branch==4'b0011|pre_branch==4'b0100|pre_branch==4'b0101|pre_branch==4'b0110|pre_branch==4'b0111)&(rsD != 0 & rsD == writeregE & regwriteE);
    assign pc8D=pcplus4D+4;
    
    //al后出现写后读数据依赖产生stall逻辑
    assign stall_al = link_storeE&((rsD != 0 & rsD == writeregE & regwriteE)|(rtD != 0 & rtD == writeregE & regwriteE));
	//execute stage
	
	flopenrc #(5) offsetE(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD,saD,saE);
	flopenrc #(32) r1E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD,srcaD,srcaE);
	flopenrc #(32) r2E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD,srcbD,srcbE);
	flopenrc #(32) r3E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD,signimmD,signimmE);
	flopenrc #(5) r4E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD,rsD,rsE);
	flopenrc #(5) r5E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD,rtD,rtE);
	flopenrc #(5) r6E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD,rdD,rdE);
	flopenrc #(32) r7E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),stall_al|jr_storeD|brs_storeD,pc8D,pc8E);//PC8D_>E阶段的传输不能被flushE清楚，但是当stall后已经将该值流水到下一个阶段，此时可以清零 
    flopenrc #(1) r8E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),stall_al|jr_storeD|brs_storeD,link_storeD,link_storeE);//LINK_STORED_>E阶段的传输不能flush
    flopenrc #(1) r9E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),stall_al|jr_storeD|brs_storeD,jalrD,jalrE);//PC8D_>E阶段的传输不能被flush
    flopenrc #(32) r10D(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD,pcD,pcE);//推pcW
	mux3 #(32) forwardaemux(srcaE,resultW,aluoutM,forwardaE,srca2E);//DIV_STALL的过程中不能修改，所以暂停整条流水线
	mux3 #(32) forwardbemux(srcbE,resultW,aluoutM,forwardbE,srcb2E);//DIV_STALL的过程中该值不能被改变
	mux2 #(32) srcbmux(srcb2E,signimmE,alusrcE,srcb3E);
	
	//DIV的流水暂停修改
	wire div_stallM;
    flopr #(1) r8M(clk,rst,div_stall,div_stallM);
	reg [31:0] alu_a,alu_b;
	always@(*)
	begin
	   if(rst) 
	   begin alu_a<=0; alu_b<=0;end
	   else begin 
	   alu_a<=div_stallM? alu_a:srca2E;  
	   alu_b<=div_stallM? alu_b:srcb3E;
	   end
	end
//	alu alu(clk,rst,srca2E,srcb3E,alucontrolE,aluoutE);
	alu alu(
	.clk(clk),
	.rst(rst),
//	.a(srca2E),
//	.b(srcb3E), //a_rs,b_rt
    .a(alu_a),
	.b(alu_b), //a_rs,b_rt
	.op(alucontrolE), //ALUcontrol
	.y(aluoutE),
	.overflow(overflow),
	.zero(zero),
	.sa(saE), //move 指令的偏移量
	.HiLo({hiE,loE}), //乘除法结果
    .mult_stall(mult_stall),
    .div_stall(div_stall),
    .FlushE(flushE),
    .hi_in(hi_oE),
    .lo_in(lo_oE),
    .hilo_we(Hi_Lo_weE)
    );
    
    wire [4:0] writeregE_temp;
	mux2 #(5) wrmux(rtE,rdE,regdstE,writeregE_temp);//通过regest选择是rt/rd
	mux2 #(5) wrmux_2(writeregE_temp,5'b11111,link_storeE&~jalrE,writeregE);//通过是否为那四条存pc+8的指令来选取是正常情况下还是31
//	mux2 #(5) wrmux_3(writeregE_temp2,writeregE_temp,jalrE,writeregE);
    
    //mem stage
    flopr #(32) r0M(clk,rst,pcE,pcM);
	flopr #(32) r1M(clk,rst,srcb2E,writedataM);
	flopr #(32) r2M(clk,rst,aluoutE,aluoutM);
	flopr #(5) r3M(clk,rst,writeregE,writeregM);
    flopr #(1) r4M(clk,rst,Hi_Lo_weE,Hi_Lo_weM);
    flopr #(64) r5M(clk,rst,{hiE,loE},{hiM,loM});
    flopr #(32) r6M(clk,rst,pc8E,pc8M);
    flopr #(1) r7M(clk,rst,link_storeE,link_storeM);
    
    wire [31:0] data_extendedM;
    ls_extend extend_ls(aluoutM[1:0],readdataM,data_lengthM,ls_extend_signedM,data_extendedM);
    
	//writeback stage //此阶段由于cp0还会flush
	flopr #(32) r0W(clk,rst,pcM,pcW);
	flopr #(32) r1W(clk,rst,aluoutM,aluoutW);
	flopr #(32) r2W(clk,rst,data_extendedM,readdataW);
	flopr #(5) r3W(clk,rst,writeregM,writeregW);
	flopr #(32) r4W(clk,rst,pc8M,pc8W);
    flopr #(1) r5W(clk,rst,link_storeM,link_storeW);
    wire [31:0]result_tempW;//用来储存mem读出来的信息即运算器的输出选择后的结果
	mux2 #(32) resmux(aluoutW,readdataW,memtoregW,result_tempW);
	mux2 #(32) muxLink(result_tempW,pc8W,link_storeW,resultW);
endmodule
