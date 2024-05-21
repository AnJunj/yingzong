`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/02 14:52:16
// Design Name: 
// Module Name: alu
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

module alu(
	input wire clk,rst,
	input wire[31:0] a,b, //a_rs,b_rt
	input wire[4:0] op, //ALUcontrol
	output reg[31:0] y,
	output reg overflow,
	output wire zero,
	input wire[4:0] sa, //move 指令的偏移量
	output reg[63:0] HiLo, //乘除法结果
    
    output wire mult_stall,
    output wire div_stall,
    input FlushE,
    //hi_lo
    input wire[31:0] hi_in,
    input wire [31:0] lo_in,
    output wire hilo_we
//    input stallD
    );

	wire[31:0] s,bout;
	wire[31:0] and_result,or_result,xor_result,nor_result,LUI_result;
	//logic compute
	assign and_result = a & b;
	assign or_result = a | b;
	assign xor_result = a ^ b;
	assign nor_result = ~(a | b);
	assign LUI_result = {b[15:0],16'b0};
	//move
	wire[31:0] sll_result,sllv_result,sra_result,srav_result,srlv_result,srl_result;
	wire[63:0] sra_result64,srav_result64,srl_result64,srlv_result64;
	assign sll_result = b << sa;
	assign sllv_result = b << a[4:0];
	
	assign sra_result64={{32{b[31]}},b} >> sa; //大括号
	assign sra_result = sra_result64[31:0];
	
	assign srav_result64={{32{b[31]}},b} >> a[4:0]; //大括号
	assign srav_result = srav_result64[31:0];
	
	assign srl_result64 ={{32{1'b0}},b} >> sa;
	assign srl_result = srl_result64[31:0];
	
	assign srlv_result64 = {{32{1'b0}},b} >> a[4:0];
	assign srlv_result = srlv_result64[31:0];
	//add and sub,补码运算，统一为加法
	wire[31:0] add_a,add_b,add_result;
	wire to_sub,add_out;
	assign add_a=a;
	assign to_sub=(op==`SUB_CONTROL)|(op==`SUBU_CONTROL)|(op==`SLT_CONTROL)|(op==`SLTU_CONTROL);
	assign add_b=to_sub?(~b+1):b;
	assign {add_out,add_result}=add_a+add_b;
	
	//assign overflowE = (alu_add || alu_sub) & (adder_cout ^ alu_out_not_mul_div[31]) & !(adder_a[31] ^ adder_b[31]);
	wire[31:0] slt_result,sltu_result;
//	assign slt_result = {{31{1'b0}},(a[31] & ~b[31]) |
//                        (~(a[31]^b[31]) & add_result[31])};//直接比较add_result[31]可能被溢出干扰，比如正数减去负数计算的结果最高位为1，会导致判断结果相反
                                                        //所以单独判断了符号相异的成立情况
	assign slt_result = $signed(a)<$signed(b) ? 32'h0000_0001:32'h0000_0000;
	assign sltu_result = {1'b0,a}<{1'b0,b}?32'h0000_0001:32'h0000_0000;
	//slt需要外面的I型配合扩展
//	assign sltu_result = {{31{1'b0}},add_out};
    //mul in always
    //div
    wire signed_div,start_div,annul_div,ready_div;
    wire[63:0] div_result;
    assign signed_div = (op==`DIV_CONTROL);
    assign start_div = (op==`DIV_CONTROL)||(op==`DIVU_CONTROL);
    div_ref div(
        .clk(clk),
        .rst(rst | FlushE),
        .signed_div_i(signed_div),
        .opdata1_i(a),
        .opdata2_i(b),
        .start_i(div_stall),
        .annul_i(FlushE),
        .result_o(div_result),
        .ready_o(ready_div)
    );
    assign div_stall= start_div & (~ready_div);
    //MFHi MFLO MTHI
    assign hilo_we = (op==`MULT_CONTROL)||(op==`MULTU_CONTROL)||(op==`DIV_CONTROL)||(op==`DIVU_CONTROL)
                        ||(op==`MTHI_CONTROL)||(op==`MTLO_CONTROL); //使能要流水化
    
	// result
	always @(*) begin
	   case (op)
	       `AND_CONTROL: y <= and_result;
	       `OR_CONTROL : y <= or_result;
	       `XOR_CONTROL: y <= xor_result;
	       `NOR_CONTROL: y <= nor_result;
	       `LUI_CONTROL: y <= LUI_result;
	       `SLL_CONTROL: y <= sll_result;
	       `SLLV_CONTROL: y <= sllv_result;
	       `SRA_CONTROL: y <= sra_result;
	       `SRAV_CONTROL: y <= srav_result;
	       `SRL_CONTROL: y <= srl_result;
	       `SRLV_CONTROL: y <= srlv_result;
	       `ADD_CONTROL: y <= add_result;
	       `ADDU_CONTROL: y <= add_result;
	       `SUB_CONTROL: y <= add_result;
	       `SUBU_CONTROL: y<= add_result;
	       `SLT_CONTROL: y <= slt_result;
	       `SLTU_CONTROL: y <= sltu_result;
	       `MULT_CONTROL: HiLo <= $signed(a) * $signed(b);
           `MULTU_CONTROL:  HiLo <= {32'b0, a} * {32'b0, b};
           `DIV_CONTROL: HiLo <= div_result;
           `DIVU_CONTROL: HiLo <= div_result;
           `MFHI_CONTROL: y <= hi_in;
           `MFLO_CONTROL: y <= lo_in;
           `MTHI_CONTROL: HiLo <= {a,lo_in};
           `MTLO_CONTROL: HiLo <= {hi_in,a};
	       default:y <= 32'b0;
	   endcase     
	end
	
//	assign bout = op[2] ? ~b : b;
//	assign s = a + bout + op[2];
//	always @(*) begin
//		case (op[1:0])
//			2'b00: y <= a & bout;
//			2'b01: y <= a | bout;
//			2'b10: y <= s;
//			2'b11: y <= s[31];
//			default : y <= 32'b0;
//		endcase	
//	end
	assign zero = (y == 32'b0);

//	always @(*) begin
//		case (op[2:1])
//			2'b01:overflow <= a[31] & b[31] & ~s[31] |
//							~a[31] & ~b[31] & s[31];
//			2'b11:overflow <= ~a[31] & b[31] & s[31] |
//							a[31] & ~b[31] & ~s[31];
//			default : overflow <= 1'b0;
//		endcase	
//	end
endmodule
