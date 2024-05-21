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
	input wire[5:0] int_i,
	
	output inst_sram_en,//����źŻ�û�н��и�ֵ�����ź��߼���?57��ָ���е�
	output wire[31:0] pcF,
	input wire[31:0] instrF,
	
	output wire [3:0]memwriteM_result,
	output wire[31:0] aluoutM,writedataM_result,
	input wire[31:0] readdataM,
	output wire data_sram_en,
	
	output wire [31:0]pcW,
	output wire regwriteW,//REGдʹ���ź�
	output wire [4:0]writeregW,//Ŀ�ļĴ�����ַ
	output wire [31:0]resultW,//д��ֵ
	
	input wire i_stall,//mips����δ���ߣ���cache�й�
	input wire d_stall,//mips����δ���ߣ���cache�й�
	output wire mips_stall,//������Ҫ�޸ģ������ӵ�57��ָ��ʱ
    output wire stall,
    output flushE
    );
	
    reg pre_inst_sram_en;
    assign inst_sram_en = pre_inst_sram_en;
    always @(*) begin//
        if(rst) begin
            pre_inst_sram_en <= 0;
        end
        else begin
            pre_inst_sram_en <= ~stall&~(regwriteM&stall);
        end
    end
    
    


    
	wire [5:0] opD,functD;
	wire regdstE,alusrcE,pcsrcD,memtoregE,memtoregM,memtoregW,
			regwriteE,regwriteM;
	wire [4:0] alucontrolE;
	wire equalD;
	wire extend_signedD,div_stall;
	wire [1:0]data_lengthM;
	wire ls_extend_signedM;
	wire [3:0]pre_branchD;
	wire [4:0]rtD;
    //�˴��Ǵ�����ʱƫ����������
    wire [31:0]writedataM;//datapath�����?
	wire [3:0]memwriteM;//datapath�����?
    reg [3:0]memwrite_result;
    reg [31:0]writedata_result;
    assign data_sram_en = (memtoregM|memwriteM);
//   assign data_sram_en = |memwriteM;
    wire id_stall;
    assign id_stall=i_stall|d_stall;        //��Ҫ�����޸�
    assign mips_stall=id_stall|stall;
    always@(*)
    begin
        case(memwriteM)
        4'b0001:
        begin
            case(aluoutM[1:0])
                2'b00: begin memwrite_result<=4'b0001; writedata_result<=writedataM;end//��ʼ���Ǹ���writedata_resultֵ��
                2'b01: begin memwrite_result<=4'b0010; writedata_result<={16'b0,writedataM[7:0],8'b0};end
                2'b10: begin memwrite_result<=4'b0100;writedata_result<={8'b0,writedataM[7:0],16'b0};end
                2'b11: begin memwrite_result<=4'b1000;writedata_result<={writedataM[7:0],24'b0};end
                default: begin memwrite_result<=4'b0000; writedata_result<=writedataM;end
            endcase
        end
        4'b0011:
            begin
            memwrite_result<= aluoutM[1]? 4'b1100:4'b0011;
            writedata_result<= aluoutM[1]? {writedataM[15:0],16'b0}:writedataM;
            end
        4'b1111: begin memwrite_result<=4'b1111;writedata_result<=writedataM;end 
        default: begin memwrite_result<=4'b0000;writedata_result<=writedataM;end
        endcase
    end
    assign memwriteM_result=memwrite_result;
    assign writedataM_result=writedata_result;
    

	controller c(
		clk,rst,
		//decode stage
		opD,functD,
		pcsrcD,branchD,equalD,jumpD,
		extend_signedD,
		pre_branchD,
		rtD,
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
		id_stall
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
		id_stall
	    );
	
endmodule
