// module top(
// 	input wire clk,rst,
// 	output wire[31:0] writedata,dataadr,
// 	output wire memwrite
//     );
// 	// wire clk;
// 	wire[31:0] pc,instr,readdata;

// 	//   clk_div instance_name(
//  //    	// Clock out ports
// 	//     .clk_out1(hclk),     // output clk_out1
// 	//    // Clock in ports
// 	//     .clk_in1(clk)
//  //    	); 
   	

// 	mips mips(clk,rst,pc,instr,memwrite,dataadr,writedata,readdata);
// 	inst_mem imem(clk,pc[7:2],instr);
// 	data_mem dmem(clk,memwrite,dataadr,writedata,readdata);
// endmodule

/**
使用下面的top
*/

//SoC top
module top(
	input clk,resetn
);

//cpu inst sram
wire        cpu_inst_en;
wire [3 :0] cpu_inst_wen;
wire [31:0] cpu_inst_addr;
wire [31:0] cpu_inst_wdata;
wire [31:0] cpu_inst_rdata;
//cpu data sram
wire        cpu_data_en;
wire [3 :0] cpu_data_wen;
wire [31:0] cpu_data_addr;
wire [31:0] cpu_data_wdata;
wire [31:0] cpu_data_rdata;

wire [31:0] debug_wb_pc;
wire [3 :0] debug_wb_rf_wen;
wire [4 :0] debug_wb_rf_wnum;
wire [31:0] debug_wb_rf_wdata;
//cpu
mycpu_top cpu(
    .clk              (~clk      ),  //相当于对inst_ram和data_ram时钟取反
    .resetn           (resetn    ),  //low active
    .ext_int          (6'b000000),
    .inst_sram_en     (cpu_inst_en   ),
    .inst_sram_wen    (cpu_inst_wen  ),
    .inst_sram_addr   (cpu_inst_addr ),
    .inst_sram_wdata  (cpu_inst_wdata),
    .inst_sram_rdata  (cpu_inst_rdata),
    
    .data_sram_en     (cpu_data_en   ),
    .data_sram_wen    (cpu_data_wen  ),
    .data_sram_addr   (cpu_data_addr ),
    .data_sram_wdata  (cpu_data_wdata),
    .data_sram_rdata  (cpu_data_rdata),
    
        //debug
    .debug_wb_pc      (debug_wb_pc      ),
    .debug_wb_rf_wen  (debug_wb_rf_wen  ),
    .debug_wb_rf_wnum (debug_wb_rf_wnum ),
    .debug_wb_rf_wdata(debug_wb_rf_wdata)
    //debug
    
);

//inst ram
inst_ram inst_ram
(
    .clka  (clk                ),   
    .ena   (cpu_inst_en        ),
    .wea   (cpu_inst_wen       ),
    .addra (cpu_inst_addr      ),
    .dina  (cpu_inst_wdata     ),
    .douta (cpu_inst_rdata     ) 
);

//data ram
data_ram data_ram
(
    .clka  (clk                 ),   
    .ena   (cpu_data_en         ),
    .wea   (cpu_data_wen        ),
    .addra (cpu_data_addr       ),
    .dina  (cpu_data_wdata      ),
    .douta (cpu_data_rdata      ) 
);
endmodule