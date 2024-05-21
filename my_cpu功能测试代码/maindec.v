`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:21:30
// Design Name: 
// Module Name: maindec
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

module maindec(
	input wire[5:0] op,
	input wire[5:0] funct,
	input wire[4:0] rt,
	input wire[4:0] rs,
	output wire memtoreg,
	output wire [3:0]memwrite,
	output wire branch,alusrc,
	output wire regdst,regwrite,
	output wire jump,
	output wire extend_signed,//0为无符号，1为无符号数
	output wire[3:0] aluop,
	output wire[1:0] data_length,
	output wire ls_extend_signed,
	output wire [3:0]pre_branch_result,
	output wire cp0_we,
	output wire cp0_read,//控制最后回写阶段的多路选择器
	output wire l_h,
	output wire s_h,
	output wire l_w,
	output wire s_w,
	output wire decode_f,
	output wire break,
	output wire syscall
    );
    //注意eret不在这里解码
	reg[17:0] controls;
	reg[3:0] pre_branch;
	reg decode_fail;
    wire lh,lhu,lw,sh,sw;
    assign lh=(op==`LH);
    assign lhu=(op==`LHU);
    assign lw=(op==`LW);
    assign sh=(op==`SH);
    assign sw=(op==`SW);
    assign l_h=lh | lhu;
    assign s_h=sh;
    assign l_w=lw;
    assign s_w=sw;
    assign decode_f=decode_fail;
    
    assign break = (op == 6'b000000 && funct == 6'b001101);
    assign syscall = (op == 6'b000000 && funct == 6'b001100);
    
    assign cp0_we=(op==`SPECIAL3_INST)&(rs==`MTC0)?1'b1:1'b0;//产生cp0写使能
    assign cp0_read=(op==`SPECIAL3_INST)&(rs==`MFC0);
	assign pre_branch_result=pre_branch;
	assign {data_length,ls_extend_signed,extend_signed,regwrite,regdst,alusrc,branch,memwrite,memtoreg,jump,aluop} = controls;
	always @(*) begin
		decode_fail<=1'b0;
		case(op)
			`R_TYPE:
			begin
			     case(funct)
			     `JR: controls <= {14'b10_0_0_0_1_0_0_0000_0_1,`R_TYPE_OP};
			     `JALR: controls <= {14'b10_0_0_1_1_0_0_0000_0_1,`R_TYPE_OP};
			     `BREAK:controls <= {14'b10_0_0_0_0_0_0_0000_0_0,`R_TYPE_OP};
			     `SYSCALL:controls <= {14'b10_0_0_0_0_0_0_0000_0_0,`R_TYPE_OP};//待检查
			     default: controls <= {14'b10_0_0_1_1_0_0_0000_0_0,`R_TYPE_OP};
//			     controls <= {14'b10_0_0_1_1_0_0_0000_0_0,`R_TYPE_OP};
                 endcase
			end
			`ANDI:controls <={14'b01_0_0_1_0_1_0_0000_0_0,`ANDI_OP};
			`LUI:controls<={14'b01_0_0_1_0_1_0_0000_0_0,`LUI_OP};
			`ORI:controls<={14'b01_0_0_1_0_1_0_0000_0_0,`ORI_OP};
			`XORI:controls<={14'b01_0_0_1_0_1_0_0000_0_0,`XORI_OP};
			`ADDI:controls<={14'b01_0_1_1_0_1_0_0000_0_0,`ADDI_OP};
			`ADDIU:controls<={14'b01_0_1_1_0_1_0_0000_0_0,`ADDIU_OP};
			`SLTI:controls<={14'b01_0_1_1_0_1_0_0000_0_0,`SLTI_OP};
			`SLTIU:controls<={14'b01_0_1_1_0_1_0_0000_0_0,`SLTIU_OP};
			`LB:controls<={14'b00_1_1_1_0_1_0_0000_1_0,`ADDI_OP};
			`LBU:controls<={14'b00_0_1_1_0_1_0_0000_1_0,`ADDI_OP};
			`LH:controls<={14'b01_1_1_1_0_1_0_0000_1_0,`ADDI_OP};
			`LHU:controls<={14'b01_0_1_1_0_1_0_0000_1_0,`ADDI_OP};
			`LW:controls<={14'b10_1_1_1_0_1_0_0000_1_0,`ADDI_OP};
			`SB:controls<={14'b00_1_1_0_0_1_0_0001_0_0,`ADDI_OP};
			`SH:controls<={14'b01_1_1_0_0_1_0_0011_0_0,`ADDI_OP};
			`SW:controls<={14'b10_0_1_0_0_1_0_1111_0_0,`ADDI_OP};
			`BEQ:controls<={14'b10_0_1_0_0_0_1_0000_0_0,`USELESS_OP};
			`BNE:controls<={14'b10_0_1_0_0_0_1_0000_0_0,`USELESS_OP};
			`REGIMM_INST:
			begin
			     case(rt)
			     `BGEZ:controls<={14'b10_0_1_0_0_0_1_0000_0_0,`USELESS_OP};
			     `BLTZ:controls<={14'b10_0_1_0_0_0_1_0000_0_0,`USELESS_OP};
			     `BGEZAL:controls<={14'b10_0_1_1_0_0_1_0000_0_0,`USELESS_OP};
                 `BLTZAL:controls<={14'b10_0_1_1_0_0_1_0000_0_0,`USELESS_OP};
                 default:  begin controls <= {14'b10000000000000,`USELESS_OP}; decode_fail<=1'b1; end
                 endcase
			end
			`BGTZ:controls<={14'b10_0_1_0_0_0_1_0000_0_0,`USELESS_OP};
            `BLEZ:controls<={14'b10_0_1_0_0_0_1_0000_0_0,`USELESS_OP};
            `J:controls<={14'b10_0_0_0_0_0_0_0000_0_1,`USELESS_OP};
            `JAL:controls<={14'b10_0_0_1_0_0_0_0000_0_1,`USELESS_OP};
            `SPECIAL3_INST: begin
                case(rs) 
                    `MTC0:controls<={14'b10_0_0_0_0_0_0_0000_0_0,`USELESS_OP};//触发软件中断，md文档有注意事项
                    `MFC0:controls<={14'b10_0_0_1_0_0_0_0000_1_0,`USELESS_OP}; //resultW要和从cp0读出的数据进行选择，增加多路选择器,增加输出信号
                    `ERET:controls<={14'b10_0_0_0_0_0_0_0000_0_0,`USELESS_OP};//未修改
                    default:  begin controls <= {14'b10000000000000,`USELESS_OP}; decode_fail<=1'b1; end//illegal op
                endcase    
            end
			default: begin controls <= {14'b10000000000000,`USELESS_OP}; decode_fail<=1'b1; end//illegal op
		endcase
	end	
	//分支提前的控制信号
	always @(*) begin
		case(op)
			`BEQ:pre_branch<=4'b0000;
			`BNE:pre_branch<=4'b0001;
			`BGTZ:pre_branch<=4'b0011;
            `BLEZ:pre_branch<=4'b0100;
            `J:pre_branch<=4'b1000;
            `JAL:pre_branch<=4'b1001;
            `R_TYPE: pre_branch<=(funct==`JR)?4'b1010:
                                 (funct==`JALR)?4'b1011:4'b1111;
            `REGIMM_INST:
			begin
			     case(rt)
			     `BGEZ:pre_branch<=4'b0010;
			     `BLTZ:pre_branch<=4'b0101;
			     `BGEZAL:pre_branch<=4'b0110;
                 `BLTZAL:pre_branch<=4'b0111;
                 endcase
			end
			default: pre_branch<=4'b1111;
		endcase
	end	
endmodule

//module maindec(
//	input wire[5:0] op,

//	output wire memtoreg,memwrite,
//	output wire branch,alusrc,
//	output wire regdst,regwrite,
//	output wire jump,
//	output wire[1:0] aluop
//    );
//	reg[8:0] controls;
//	assign {regwrite,regdst,alusrc,branch,memwrite,memtoreg,jump,aluop} = controls;
//	always @(*) begin
//		case (op)
//			6'b000000:controls <= 9'b110000010;//R-TYRE
//			6'b100011:controls <= 9'b101001000;//LW
//			6'b101011:controls <= 9'b001010000;//SW
//			6'b000100:controls <= 9'b000100001;//BEQ
//			6'b001000:controls <= 9'b101000000;//ADDI
			
//			6'b000010:controls <= 9'b000000100;//J
//			default:  controls <= 9'b000000000;//illegal op
//		endcase
//	end
//endmodule
