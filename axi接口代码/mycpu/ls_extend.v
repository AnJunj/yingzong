`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/02 14:29:33
// Design Name: 
// Module Name: signext
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


module ls_extend(
    input wire [1:0]offset,
	input wire[31:0] a,
	input wire[1:0] length,
	input wire extend_signed,
	output reg[31:0] y
    );
    always@(*)
    begin
        if(length[1]==1'b1)
        begin
            y<=a;
        end
        else begin
            if(length[0]==1'b1)
            begin
                case(offset[1])
                1'b0: y<= extend_signed ? {{16{a[15]}},a[15:0]}:{{16{1'b0}},a[15:0]};
                1'b1: y<= extend_signed ? {{16{a[31]}},a[31:16]}:{{16{1'b0}},a[31:16]};
                default: y<=0;
                endcase
            end
            else begin
                case(offset)
                2'b00: y<= extend_signed ? {{24{a[7]}},a[7:0]}:{{24{1'b0}},a[7:0]};
                2'b01: y<= extend_signed ? {{24{a[15]}},a[15:8]}:{{24{1'b0}},a[15:8]};
                2'b10: y<= extend_signed ? {{24{a[23]}},a[23:16]}:{{24{1'b0}},a[23:16]};
                2'b11: y<= extend_signed ? {{24{a[31]}},a[31:24]}:{{24{1'b0}},a[31:24]};
                default: y<=0;
                endcase
            end
        end
    end
endmodule
