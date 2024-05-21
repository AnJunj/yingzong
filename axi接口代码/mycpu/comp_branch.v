`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/23 22:57:01
// Design Name: 
// Module Name: eqcmp
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


module comp_branch(
	input wire [31:0] a,b,
	input wire [3:0]pre_branch,
	output wire y
    );
//    `BEQ:pre_branch<=4'b0000;
//			`BNE:pre_branch<=4'b0001;
//			`BGEZ:pre_branch<=4'b0010;
//			`BGTZ:pre_branch<=4'b0011;
//            `BLEZ:pre_branch<=4'b0100;
//            `BLTZ:pre_branch<=4'b0101;
//            `BGEZAL:pre_branch<=4'b0110;
    reg temp;
    always@(*)
    begin
        case(pre_branch)
        4'b0000: temp<= (a == b) ? 1 : 0;
        4'b0001: temp<= (a == b) ? 0 : 1;
        4'b0010: temp<= ( $signed(a) >= 0) ? 1 : 0;
        4'b0011: temp<= ( $signed(a) > 0) ? 1 : 0;
        4'b0100: temp<= ( $signed(a) <= 0) ? 1 : 0;
        4'b0101: temp<= ($signed(a) < 0) ? 1 : 0;
        4'b0110: temp<= ($signed(a) >= 0) ? 1 : 0;
        4'b0111:temp<=  ($signed(a) < 0) ? 1 : 0;
        default: temp<=0;
        endcase
    end
	assign y = temp;
endmodule
