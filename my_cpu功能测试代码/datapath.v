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
	output wire[4:0]rtD,
	output wire[4:0]rsD,
	input wire cp0_weM,
	input wire cp0_readW,
	input wire cp0_weD,
	input wire cp0_readD,
	input wire cp0_readE,
	input wire cp0_readM,
	input wire l_hD,
	input wire s_hD,
	input wire l_wD,
	input wire s_wD,
	input wire decode_fD,
	input wire[5:0] int_i,
	input wire break,
	input wire syscall,
	output wire flush_exceptionM,
	output wire flush_exceptionW
    );
    
	//fetch stage
	wire stallF;
	//FD
	wire [31:0] pcnextFD,pcnextbrFD,pcplus4F,pcbranchD;
	//decode stage
	wire [31:0] pcD;
	wire [31:0] pcplus4D,instrD;
	wire forwardaD,forwardbD;
	wire [4:0]rdD;
	wire flushD,stallD,stall_al;
	wire [31:0] signimmD,signimmshD;
	wire [31:0] srcaD,srca2D,srcbD,srcb2D;
	//execute stage
	wire [31:0] pcE;
	wire [1:0] forwardaE,forwardbE;
	wire [4:0] rsE,rtE,rdE,rdM;
	wire [4:0] writeregE;
	wire [31:0] signimmE;
	wire [31:0] srcaE,srca2E,srcbE,srcb2E,srcb3E;
	wire [31:0] aluoutE;
	//mem stage
	wire [31:0] pcM,srcbM;
	wire [4:0] writeregM;
	//writeback stage
	wire [31:0] epc_o;
	wire [31:0] aluoutW,readdataW;
    //hilo
    wire [31:0] hiE,loE,hiM,loM,hi_oE,lo_oE;
    //alu
    wire overflow,overflowM,zero,mult_stall;
    //exception
    wire pcaddr_exceptionF,pcaddr_exceptionD,pcaddr_exceptionE,pcaddr_exceptionM,memaddr_exception_l,memaddr_exception_s;
    wire l_hE,l_hM,l_wE,l_wM,s_hE,s_hM,s_wE,s_wM;
    wire decode_fE,decode_fM,breakE,breakM,syscallE,syscallM;
    //未在controller里面解码
    wire eretD,eretE,eretM;
    assign eretD = (instrD == 32'b01000010000000000000000000011000);
    wire nopD,nopE,nopM;
    assign nopD=(instrD==32'h0000_0000);
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
	wire [31:0]pcnextFD_temp,srca2D_t;//存的是jumpD筛选后的pc值
	mux2 #(32) pcmux(pcnextbrFD,
		{pcplus4D[31:28],instrD[25:0],2'b00},
		jumpD,pcnextFD_temp);
	wire signal;
	wire [31:0] pcnextFD_noex;
	assign signal=(pre_branch==4'b1010)|(pre_branch==4'b1011)?1'b1:1'b0; 
	mux2 #(32) pcmux2(pcnextFD_temp,srca2D_t,signal,pcnextFD);
    //增加信号判断是否处于延迟槽,需要传入延迟槽信号
    wire is_in_delayslot_iF,is_in_delayslot_iD,is_in_delayslot_iE,is_in_delayslot_iM;
    assign is_in_delayslot_iF = (pre_branch!=4'b1111)?1'b1:1'b0;
    
	//regfile (operates in decode and writeback)
//	assign regwriteW_o = (regwriteW & !flush_exceptionW);
	regfile rf(clk,(regwriteW & !flush_exceptionW),rsD,rtD,writeregW,resultW,srcaD,srcbD);
    wire Hi_Lo_weE,Hi_Lo_weM;
//    assign Hi_Lo_we = (alucontrolE==`MULT_CONTROL)||(alucontrolE==`MULTU_CONTROL)||(alucontrolE==`DIV_CONTROL)||(alucontrolE==`DIVU_CONTROL);
    Hi_Lo hl(.clk(~clk),
             .rst(rst),
             .we((Hi_Lo_weM & !flush_exceptionM)),
             .hi_i(hiM),
             .lo_i(loM),
             .hi_o(hi_oE),
             .lo_o(lo_oE)
    );
    
     wire jr_storeD;
     wire brs_storeD;
     wire mfc0_stallD,mfc0_bhE,mfc0_bhM;
     wire [31:0]data_o_cp0M;
    assign stall=div_stall|stall_al|jr_storeD|brs_storeD|mfc0_stallD;//对controller整体进行stall
	//fetch stage logic
	wire [31:0] pcF_t;
	pc #(32) pcreg(clk,rst,~(stallF|div_stall|stall_al|jr_storeD|brs_storeD),flush_exceptionM,eretM,pcnextFD,epc_o,pcF);
//    pc #(32) pcreg(clk,rst,~(stallF|div_stall|stall_al|jr_storeD|brs_storeD),pcnextFD,pcF);
//	assign pcF = flush_exceptionM? 32'hbfc00000:pcF_t;
	assign pcaddr_exceptionF = (pcF[1:0]!=2'b00)? 1'b1:1'b0;//取址地址错例外
	
	adder pcadd1(pcF,32'b100,pcplus4F);
	//decode stage |flush_exceptionW
	flopenrc #(32) r1D(clk,rst,~(stallD|div_stall|stall_al|jr_storeD|brs_storeD|mfc0_stallD),(flushD|flush_exceptionM),pcplus4F,pcplus4D);
	flopenrc #(32) r2D(clk,rst,~(stallD|div_stall|stall_al|jr_storeD|brs_storeD|mfc0_stallD),(flushD|flush_exceptionM),instrF,instrD);
	flopenrc #(32) r3D(clk,rst,~(stallD|div_stall|stall_al|jr_storeD|brs_storeD|mfc0_stallD),(flushD|flush_exceptionM),pcF,pcD);//推pcW
	flopenrc #(1) r4D(clk,rst,~(stallD|div_stall|stall_al|jr_storeD|brs_storeD|mfc0_stallD),(flushD|flush_exceptionM),is_in_delayslot_iF,is_in_delayslot_iD);
	flopenrc #(1) r5D(clk,rst,~(stallD|div_stall|stall_al|jr_storeD|brs_storeD|mfc0_stallD),(flushD|flush_exceptionM),pcaddr_exceptionF,pcaddr_exceptionD);
	signext se(instrD[15:0],extend_signed,signimmD);
	sl2 immsh(signimmD,signimmshD);
	adder pcadd2(pcplus4D,signimmshD,pcbranchD);
	//a的前推
	wire [31:0]srca2D_temp;
	mux2 #(32) forwardamux(srcaD,aluoutM,forwardaD,srca2D_temp);//正常前推
	wire [31:0]pc8D,pc8E,pc8M,pc8W;
	wire link_storeD,link_storeE,link_storeM,link_storeW;
	mux2 #(32) forwardamux_1(srca2D_temp,pc8M,(link_storeM)&forwardaD,srca2D_t);//前推的基础上如果是link_store所涉及到的四条指令，则前推值为pc8M
	mux2 #(32) forwardamux_2(srca2D_t,data_o_cp0M,(mfc0_bhM)&forwardaD,srca2D);
	//b的前推
	wire [31:0]srcb2D_temp,srcb2D_t;
	mux2 #(32) forwardbmux(srcbD,aluoutM,forwardbD,srcb2D_temp);//正常前推
	mux2 #(32) forwardbmux_1(srcb2D_temp,pc8M,(link_storeM)&forwardbD,srcb2D_t);//前推的基础上如果是link_store所涉及到的四条指令，则前推值为pc8M
    mux2 #(32) forwardbmux_2(srcb2D_t,data_o_cp0M,(mfc0_bhM)&forwardbD,srcb2D);
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
    //mtc0的数据依赖需要前推,产生前推的判断信号
    wire mtc0_hD,mtc0_hE,mtc0_hM,mtc0_h2D,mtc0_h2E;
    assign mtc0_hD = cp0_weD&(rtD != 0 & rtD == writeregE & regwriteE);
    assign mtc0_h2D = cp0_weD&(rtD != 0 & rtD == writeregM & regwriteM);
    //mfc0之后的指令需要写入寄存器的数据，导致冒险，需要前推处理
    //分两类来考虑，一类是E阶段执行的运算等指令，一类是D阶段执行的跳转
    //mfc0紧接着的下条指令为分支，需等到M阶段才可以得到正确的值,可以复用上面的暂停信号
    assign mfc0_bhE = cp0_readE & (jr_storeD|brs_storeD);//处理M->D的mux
    assign mfc0_stallD=cp0_readE & memtoregE & (rtE == rsD | rtE == rtD);//暂停信号
    
	//execute stage
	
	flopenrc #(5) offsetE(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD|flush_exceptionM,saD,saE);
	flopenrc #(32) r1E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD|flush_exceptionM,srcaD,srcaE);
	flopenrc #(32) r2E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD|flush_exceptionM,srcbD,srcbE);
	flopenrc #(32) r3E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD|flush_exceptionM,signimmD,signimmE);
	flopenrc #(5) r4E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD|flush_exceptionM,rsD,rsE);
	flopenrc #(5) r5E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD|flush_exceptionM,rtD,rtE);
	flopenrc #(5) r6E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD|flush_exceptionM,rdD,rdE);
	flopenrc #(32) r7E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD|flush_exceptionM,pc8D,pc8E);//PC8D_>E阶段的传输不能被flushE清楚，但是当stall后已经将该值流水到下一个阶段，此时可以清零 
    flopenrc #(1) r8E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD|flush_exceptionM,link_storeD,link_storeE);//LINK_STORED_>E阶段的传输不能flush
    flopenrc #(1) r9E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD|flush_exceptionM,jalrD,jalrE);//PC8D_>E阶段的传输不能被flush
    flopenrc #(32) r10D(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD|flush_exceptionM,pcD,pcE);//推pcW
	flopenrc #(1) r11E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD|flush_exceptionM,is_in_delayslot_iD,is_in_delayslot_iE);
	flopenrc #(1) r12E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD|flush_exceptionM,mtc0_hD,mtc0_hE);
	flopenrc #(1) r13E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD|flush_exceptionM,mtc0_h2D,mtc0_h2E);
	flopenrc #(1) r14E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD|flush_exceptionM,l_hD,l_hE);
	flopenrc #(1) r15E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD|flush_exceptionM,s_hD,s_hE);
	flopenrc #(1) r16E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD|flush_exceptionM,l_wD,l_wE);
	flopenrc #(1) r17E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD|flush_exceptionM,s_wD,s_wE);
	flopenrc #(1) r18E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD|flush_exceptionM,pcaddr_exceptionD,pcaddr_exceptionE);
	flopenrc #(1) r19E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD|flush_exceptionM,decode_fD,decode_fE);
	flopenrc #(1) r20E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD|flush_exceptionM,eretD,eretE);
	flopenrc #(1) r21E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD|flush_exceptionM,break,breakE);
	flopenrc #(1) r22E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD|flush_exceptionM,syscall,syscallE);
	flopenrc #(1) r23E(clk,rst,~(div_stall|stall_al|jr_storeD|brs_storeD),flushE|stall_al|jr_storeD|brs_storeD|flush_exceptionM,nopD,nopE);
	mux3 #(32) forwardaemux(srcaE,resultW,aluoutM,forwardaE,srca2E);//DIV_STALL的过程中不能修改，所以暂停整条流水线
	mux3 #(32) forwardbemux(srcbE,resultW,aluoutM,forwardbE,srcb2E);//DIV_STALL的过程中该值不能被改变
	mux2 #(32) srcbmux(srcb2E,signimmE,alusrcE,srcb3E);
	
	//DIV的流水暂停修改 (写法诡异,一眼看上去像一个时序逻辑)
	wire div_stallM;
    flopr #(1) r8M(clk,rst,div_stall,div_stallM);
	reg [31:0] alu_a,alu_b;
	always@(*)//原本为*
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
	.overflow(overflow),//溢出例外的信号
	.zero(zero),
	.sa(saE), //move 指令的偏移量
	.HiLo({hiE,loE}), //乘除法结果
    .mult_stall(mult_stall),
    .div_stall(div_stall),
    .FlushE(flushE),
    .flush_exceptionM(flush_exceptionM),
    .hi_in(hi_oE),
    .lo_in(lo_oE),
    .hilo_we(Hi_Lo_weE)
    );
    
    wire [4:0] writeregE_temp;
	mux2 #(5) wrmux(rtE,rdE,regdstE,writeregE_temp);//通过regest选择是rt/rd
	mux2 #(5) wrmux_2(writeregE_temp,5'b11111,link_storeE&~jalrE,writeregE);//通过是否为那四条存pc+8的指令来选取是正常情况下还是31
//	mux2 #(5) wrmux_3(writeregE_temp2,writeregE_temp,jalrE,writeregE);
    //mtc0 hazard 2 D M
    wire [31:0] srcbE_f;
    assign srcbE_f = mtc0_h2E? resultW:srcbE;
    //mem stage
    floprc #(32) r0M(clk,rst,flush_exceptionM,pcE,pcM);
	floprc #(32) r1M(clk,rst,flush_exceptionM,srcb2E,writedataM);
	floprc #(32) r2M(clk,rst,flush_exceptionM,aluoutE,aluoutM);
	floprc #(5) r3M(clk,rst,flush_exceptionM,writeregE,writeregM);
    floprc #(1) r4M(clk,rst,flush_exceptionM,Hi_Lo_weE,Hi_Lo_weM);
    floprc #(64) r5M(clk,rst,flush_exceptionM,{hiE,loE},{hiM,loM});
    floprc #(32) r6M(clk,rst,flush_exceptionM,pc8E,pc8M);
    floprc #(1) r7M(clk,rst,flush_exceptionM,link_storeE,link_storeM);
    floprc #(1) r9M(clk,rst,flush_exceptionM,is_in_delayslot_iE,is_in_delayslot_iM);
    floprc #(5) r10M(clk,rst,flush_exceptionM,rdE,rdM);
    floprc #(32) r11M(clk,rst,flush_exceptionM,srcbE_f,srcbM);
    floprc #(1) r12M(clk,rst,flush_exceptionM,mtc0_hE,mtc0_hM);
    floprc #(1) r13M(clk,rst,flush_exceptionM,mfc0_bhE,mfc0_bhM);
    floprc #(1) r14M(clk,rst,flush_exceptionM,l_hE,l_hM);
    floprc #(1) r15M(clk,rst,flush_exceptionM,s_hE,s_hM);
    floprc #(1) r16M(clk,rst,flush_exceptionM,l_wE,l_wM);
    floprc #(1) r17M(clk,rst,flush_exceptionM,s_wE,s_wM);
    floprc #(1) r18M(clk,rst,flush_exceptionM,pcaddr_exceptionE,pcaddr_exceptionM);
    floprc #(1) r19M(clk,rst,flush_exceptionM,overflow,overflowM);
    floprc #(1) r20M(clk,rst,flush_exceptionM,decode_fE,decode_fM);
    floprc #(1) r21M(clk,rst,flush_exceptionM,eretE,eretM);
    floprc #(1) r22M(clk,rst,flush_exceptionM,breakE,breakM);
    floprc #(1) r23M(clk,rst,flush_exceptionM,syscallE,syscallM);
    floprc #(1) r24M(clk,rst,flush_exceptionM,nopE,nopM);
    //mem exception 
    assign memaddr_exception_l=(l_hM & aluoutM[0]!=1'b0)||(l_wM & aluoutM[1:0]!=2'b00);
    assign memaddr_exception_s=(s_hM & aluoutM[0]!=1'b0)||(s_wM & aluoutM[1:0]!=2'b00);
    wire [31:0] data_extendedM;
    ls_extend extend_ls(aluoutM[1:0],readdataM,data_lengthM,ls_extend_signedM,data_extendedM);
    //mem stage cp0
    wire [4:0] waddr_cp0,raddr_cp0;
    wire [31:0] data_cp0,current_inst_addr_i,bad_addr_cp0;
    wire [5:0] int_i_cp0;
    assign data_cp0= mtc0_hM? resultW:srcbM;//输入cp0的数据为rt寄存器读出的数据    新的冒险需要处理
    assign bad_addr_cp0 = pcaddr_exceptionM?pcM:aluoutM; //记录发生地址错例外的虚地址
    wire [31:0] data_o_cp0W,count_o_cp0,compare_o_cp0,status_o_cp0,cause_o_cp0,config_o,prid_o,badvaddr;
    wire timer_int_o;
    wire interrupM,interrupW;
    //本实验只需实现软中断
    assign interrupM = status_o_cp0[0] && ~status_o_cp0[1] && (
                     //IM                 //IP
                  ( |(status_o_cp0[9:8] & cause_o_cp0[9:8]) ) ||        //soft interupt
                  ( |(status_o_cp0[15:10] & cause_o_cp0[15:10]) ));
    //根据信号判断异常种类
    reg [31:0] excepttype_i;
    reg excep_pc,eret_pc;
    always @(*) begin
        if (rst) begin
            excepttype_i<=0;
            excep_pc <=0;
            eret_pc <=0;
        end
        else begin
        excepttype_i<=(interrupM==1)?32'h00000001:
                        ((memaddr_exception_l|pcaddr_exceptionM)==1)?32'h00000004:
                        (memaddr_exception_s==1)?32'h00000005:
                        (syscallM==1)?32'h00000008:
                        (breakM==1)?32'h00000009:
                        ((decode_fM & !eretM & !nopM)==1)?32'h0000000a:
                        (overflowM==1)?32'h0000000c:
                        (eretM==1)?32'h0000000e:32'h00000000;
       excep_pc <=  interrupW|(memaddr_exception_l|pcaddr_exceptionM)|memaddr_exception_s|syscallM|breakM|(decode_fM && !eretM && !nopM)| overflowM;
       eret_pc <= eretM;              
      end      
    end
    //exception flush
    assign flush_exceptionM = (excepttype_i!=32'h00000000);
    assign exception_occur = flush_exceptionM;                 
    cp0_reg cp0(
       .clk(clk),
	   .rst(rst),
       .we_i(cp0_weM),//cp0的写使能
	   .waddr_i(rdM),
	   .raddr_i(rdM),
	   .data_i(data_cp0),
	   
	   .int_i(int_i),//外部输入

	   .excepttype_i(excepttype_i),//需生成
	   .current_inst_addr_i(pcM),
	   .is_in_delayslot_i(is_in_delayslot_iM),
	   .bad_addr_i(bad_addr_cp0),//记录发生地址错例外的虚地址

	   .data_o(data_o_cp0M),
	   .count_o(count_o_cp0),
	   .compare_o(compare_o_cp0),
	   .status_o(status_o_cp0),
	   .cause_o(cause_o_cp0),
	   .epc_o(epc_o),
	   .config_o(config_o),
	   .prid_o(prid_o),
	   .badvaddr(badvaddr),
	   .timer_int_o(timer_int_o)
    ); 
    //exception jump in mem stage
//    wire [31:0] pcnextFD_noer;
//    mux2 #(32) exceptionpc(pcnextFD_noex,32'hbfc00380,excep_pc,pcnextFD_noer);
//    mux2 #(32) eretpc(pcnextFD_noer,epc_o,eret_pc,pcnextFD);
	//writeback stage //此阶段由于cp0还会flush
	flopr #(32) r0W(clk,rst,pcM,pcW);
	flopr #(32) r1W(clk,rst,aluoutM,aluoutW);
	flopr #(32) r2W(clk,rst,data_extendedM,readdataW);
	flopr #(5) r3W(clk,rst,writeregM,writeregW);
	flopr #(32) r4W(clk,rst,pc8M,pc8W);
    flopr #(1) r5W(clk,rst,link_storeM,link_storeW);
    flopr #(32) r6W(clk,rst,data_o_cp0M,data_o_cp0W);//读取cp0得到的结果的流水
    flopr #(1) r7W(clk,rst,interrupM,interrupW);
    flopr #(1) r8W(clk,rst,flush_exceptionM,flush_exceptionW);//防止回写
    wire [31:0]result_tempW;//用来储存mem读出来的信息即运算器的输出选择后的结果
    wire [31:0]result_tW;
	mux2 #(32) resmux(aluoutW,readdataW,memtoregW,result_tempW);
	mux2 #(32) muxLink(result_tempW,pc8W,link_storeW,result_tW);
	mux2 #(32) muxcp0(result_tW,data_o_cp0W,cp0_readW,resultW);//选择读取的数据是否为cp0
endmodule
