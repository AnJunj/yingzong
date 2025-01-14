`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/26 21:25:26
// Design Name: 
// Module Name: pc
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


module pc #(parameter WIDTH = 8)(
	input wire clk,rst,en,exception,eret,
	input wire[WIDTH-1:0] d,
	input wire [WIDTH-1:0]epc,
	output reg[WIDTH-1:0] q
    );
	always @(posedge clk,posedge rst,posedge exception) begin
		if(rst) begin
			q <= 32'hbfc00000;
		end else if (eret) begin
		    q <= epc;  
		end else if (exception) begin
		    q <= 32'hbfc00380;  

		end else if(en) begin
			/* code */
			q <= d;
		end
	end
endmodule