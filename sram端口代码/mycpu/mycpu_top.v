module mycpu_top(
    input clk,
    input resetn,  //low active
    input [5:0]ext_int,  //interrupt,high active
    //cpu inst sram
    output        inst_sram_en   ,
    output [3 :0] inst_sram_wen  ,
    output [31:0] inst_sram_addr ,
    output [31:0] inst_sram_wdata,
    input  [31:0] inst_sram_rdata,
    //cpu data sram
    output        data_sram_en   ,
    output [3 :0] data_sram_wen  ,
    output [31:0] data_sram_addr ,
    output [31:0] data_sram_wdata,
    input  [31:0] data_sram_rdata,
    //debug
    output [31:0]debug_wb_pc,
    output wire [3 :0] debug_wb_rf_wen,
    output wire [4 :0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);
wire clk_temp;
assign clk_temp=~clk;
wire cache;
wire [31:0] data_sram_addr_temp;
wire [31:0] inst_sram_addr_temp;

mmu mmu(
    .inst_vaddr(inst_sram_addr_temp),
    .inst_paddr(inst_sram_addr),
    .data_vaddr(data_sram_addr_temp),
    .data_paddr(data_sram_addr),
    .no_dcache(cache)    //鏄惁缁忚繃d cache
);
// 涓?涓緥瀛?
	wire [31:0] pc;
	wire [31:0] instr;
	wire [3:0]memwrite;
	wire [31:0] aluout, writedata, readdata;
	wire regwriteW;
    mips mips(
        .clk(clk_temp),
        .rst(~resetn),
        //instr
        // .inst_en(inst_en),
        .pcF(pc),                    //pcF
        .instrF(instr),              //instrF
        //data
        // .data_en(data_en),
        .memwriteM(memwrite),
        .aluoutM(aluout),
        .writedataM(writedata),
        .readdataM(readdata),
        .pcW(debug_wb_pc),
        .regwriteW(regwriteW),
        .writeregW(debug_wb_rf_wnum),
        .resultW(debug_wb_rf_wdata)
    );
    //Debug寄存器写使能信号
    assign debug_wb_rf_wen={4{regwriteW}};
    
    
    
    assign inst_sram_en = 1'b1;     //濡傛灉鏈塱nst_en锛屽氨鐢╥nst_en
    assign inst_sram_wen = 4'b0;
    assign inst_sram_addr_temp = pc;
    assign inst_sram_wdata = 32'b0;
    assign instr = inst_sram_rdata;

    assign data_sram_en = 1'b1;     //濡傛灉鏈塪ata_en锛屽氨鐢╠ata_en
    //此处是处理存时偏移量的问题
    reg [3:0]memwrite_result;
    reg [31:0]writedata_result;
    always@(*)
    begin
        case(memwrite)
        4'b0001:
        begin
            case(data_sram_addr[1:0])
                2'b00: begin memwrite_result<=4'b0001; writedata_result<=writedata;end//开始忘记付给writedata_result值了
                2'b01: begin memwrite_result<=4'b0010; writedata_result<={16'b0,writedata[7:0],8'b0};end
                2'b10: begin memwrite_result<=4'b0100;writedata_result<={8'b0,writedata[7:0],16'b0};end
                2'b11: begin memwrite_result<=4'b1000;writedata_result<={writedata[7:0],24'b0};end
                default: begin memwrite_result<=4'b0000; writedata_result<=writedata;end
            endcase
        end
        4'b0011:
            begin
            memwrite_result<= data_sram_addr[1]? 4'b1100:4'b0011;
            writedata_result<= data_sram_addr[1]? {writedata[15:0],16'b0}:writedata;
            end
        4'b1111: begin memwrite_result<=4'b1111;writedata_result<=writedata;end 
        default: begin memwrite_result<=4'b0000;writedata_result<=writedata;end
        endcase
    end
    assign data_sram_wen = memwrite_result;
    assign data_sram_addr_temp = aluout;
    assign data_sram_wdata = writedata_result;
    assign readdata = data_sram_rdata;

    //ascii
    instdec instdec(
        .instr(instr)
    );

endmodule