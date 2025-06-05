`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/16/2025 10:20:38 PM
// Design Name: 
// Module Name: ASIP
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
`define SINGLE 1
`define ONE_ONE 2
`define TWO_TWO 3

module ASIP #(
    // Controller parameter
    parameter MODEL = `ONE_ONE,
    parameter IS_FIRST_ROW = 1,
    parameter IS_FIRST_COL = 1, 
    parameter INSTRUCTION_WIDTH = 32,               
    parameter MCMEM_SIZE = 4096,
    parameter DATA_WIDTH_MC = 32,
    parameter ADDR_WIDTH = 32,
    parameter BASE_DATA_OM = 32'h00010000,
    
    // DNN core parameter
    parameter DATA_WIDTH_DNN_CORE = 16,
    parameter DECIMAL_BIT = 8,                       // DECLARE NUMBER OF BITS DECIMAL PART
    parameter INSTRUCTION_WIDTH_DNN_CORE = 212,
    parameter BUFFER_SIZE = 512,
    parameter SCRATCHPAD_SIZE = 512,
    parameter BLOCKS_PER_ROW = 64
    
    
)(
    input wire clk,                         // clock   
    input wire rst,                         // reset
    input wire start,                       // tin hieu kich hoat cac ASIP hoat dong
//    output wire ASIP_done,                   // tin hieu cho biet ASIP da hoan tat cong viec
    input wire wen_MCMem,
    input wire [$clog2(MCMEM_SIZE)-1:0] addr_w_MCMem,
    input wire [INSTRUCTION_WIDTH-1:0] data_w_MCMem,
    

    // MODE controller
    input wire vsync_in,                            // tin hieu dong bo theo chieu doc  = all vsync_out
    input wire hsync_in,                            // tin hieu dong bo theo chieu ngang    
//    input wire DNN_done_signal,                    // DNN core trong DSIP nay da hoan thanh cong viec
//    input wire DNN_done,                   // = all DNN_done_signal
    output wire vsync_out,                          // tin hieu vsync de dong bo cac DSIP subsequence
    output wire hsync_out,
    output wire start_DNN_core,
    output wire end_flag,
    
    
    //PORT0 ==============
    input wire [67:0] command_P0_in,
    input wire [15:0] data_P0_in,
    output wire [67:0] command_P0_out,
    output wire [15:0] data_P0_out,
    
    //PORT1
    input wire [67:0] command_P1_in,
    input wire [15:0] data_P1_in,
    output wire [67:0] command_P1_out,
    output wire [15:0] data_P1_out,
    
    
    //PORT OM
    output wire [31:0] addr_OM,
    output wire wen_OM,
    output wire ren_OM,
    input wire [31:0] data_r_OM,
    output wire [31:0] data_w_OM,
    output wire ren_OM_inst,
    input wire [211:0] inst_r_OM, 
    
    //PORT DNN core
    output wire [8:0] addr_DNN,
    output wire wen_inst_mem,
    output wire [63:0] wen_IB,
    output wire [63:0] wen_KSP,
    output wire wen_BSP,
    output wire ren_OB,
    output wire [31:0] data_w_DNN,
    output wire [211:0] inst_w_DNN,
    input wire done_transfer_prev,
    output wire done_transfer,
    
    
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB,
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OB,
    
    input wire [7:0] select,

    output wire [DATA_WIDTH_DNN_CORE - 1 : 0] NEOA_read_out,
    output wire sel_lut,

    output wire [DATA_WIDTH_DNN_CORE - 1 : 0] li_data_out,
    
    output wire [DATA_WIDTH_DNN_CORE - 1 : 0] POA_read_out,

    
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_ML_out,
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_CONV_out,
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_FCSP_ML_out,
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_FCSP_CONV_out,
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB_ML_out,
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB_CONV_out,
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OB_ML_out,
    output wire [DATA_WIDTH_DNN_CORE - 1 : 0] OB_read_out,
    output wire [DATA_WIDTH_DNN_CORE - 1 : 0] MEM_read_out,

    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_IB,
    output wire done_DNN,

    output wire DSIP_done
    );
    wire [31:0] data_r_DNN;

master_core  #(
    .INSTRUCTION_WIDTH(INSTRUCTION_WIDTH),
    .MCMEM_SIZE(MCMEM_SIZE),
    .DATA_WIDTH(DATA_WIDTH_MC),
    .ADDR_WIDTH(ADDR_WIDTH),
    .BASE_DATA_OM(BASE_DATA_OM),
    .MODEL(MODEL),
    .IS_FIRST_ROW(IS_FIRST_ROW),
    .IS_FIRST_COL(IS_FIRST_COL)
) controller(
    .clk(clk),                         // clock   
    .rst(rst),                         // reset
    .start(start),                       // tin hieu kich hoat cac ASIP hoat dong
//    output wire ASIP_done,                   // tin hieu cho biet ASIP da hoan tat cong viec
    .wen_MCMem(wen_MCMem),
    .addr_w_MCMem(addr_w_MCMem),
    .data_w_MCMem(data_w_MCMem),
    

    // MODE controller
    .vsync_in(vsync_in),                            // tin hieu dong bo theo chieu doc  = all vsync_out
    .hsync_in(hsync_in),                            // tin hieu dong bo theo chieu ngang    
//    input wire DNN_done_signal,                    // DNN core trong DSIP nay da hoan thanh cong viec
    .DNN_done(done_DNN),                   // = all DNN_done_signal
    .vsync_out(vsync_out),                          // tin hieu vsync de dong bo cac DSIP subsequence
    .hsync_out(hsync_out),
    .start_DNN_core(start_DNN_core),
    .end_flag(end_flag),
    
    
    //PORT0 ==============
    .command_P0_in(command_P0_in),
    .data_P0_in(data_P0_in),
    .command_P0_out(command_P0_out),
    .data_P0_out(data_P0_out),
    
    //PORT1
    .command_P1_in(command_P1_in),
    .data_P1_in(data_P1_in),
    .command_P1_out(command_P1_out),
    .data_P1_out(data_P1_out),
    
    
    //PORT OM
    .addr_OM(addr_OM),
    .wen_OM(wen_OM),
    .ren_OM(ren_OM),
    .data_r_OM(data_r_OM),
    .data_w_OM(data_w_OM),
    .ren_OM_inst(ren_OM_inst),
    .inst_r_OM(inst_r_OM), 
    
    //PORT DNN core
    .addr_DNN(addr_DNN),
    .wen_inst_mem(wen_inst_mem),
    .wen_IB(wen_IB),
    .wen_KSP(wen_KSP),
    .wen_BSP(wen_BSP),
    .ren_OB(ren_OB),
    .data_w_DNN(data_w_DNN),
    .data_r_DNN(data_r_DNN),
    .inst_w_DNN(inst_w_DNN),
    
    .done_transfer_prev(done_transfer_prev),
    .done_transfer(done_transfer)
);


slave_core #(
    .DATA_WIDTH(DATA_WIDTH_DNN_CORE),
    .DECIMAL_BIT(DECIMAL_BIT),                       // DECLARE NUMBER OF BITS DECIMAL PART
    .INSTRUCTION_WIDTH(INSTRUCTION_WIDTH_DNN_CORE),
    .BUFFER_SIZE(BUFFER_SIZE),
    .SCRATCHPAD_SIZE(SCRATCHPAD_SIZE),
    .BLOCKS_PER_ROW(BLOCKS_PER_ROW)
) dnn_core(
    .clk(clk),
    .rst(rst),
    .start(start_DNN_core),   
    .en_write_SC(wen_inst_mem),
    .SC_addr_w(addr_DNN),
    .inst_SC_w(inst_w_DNN),
    .en_write_IB(wen_IB),
    .addr_write_IB(addr_DNN),  
    .en_write_KSP(wen_KSP),
    .addr_write_KSP(addr_DNN),   
    .en_write_BSP(wen_BSP),
    .addr_write_BSP(addr_DNN),
    .data_write(data_w_DNN),
    .addr_write_OB(addr_write_OB),
    .addr_read_OB(addr_read_OB),
    
    .select(select),

    .NEOA_read_out(NEOA_read_out),
    .sel_lut(sel_lut),

    .li_data_out(li_data_out),
    
    .POA_read_out(POA_read_out),

    
    .addr_write_OSP_ML_out(addr_write_OSP_ML_out),
    .addr_write_OSP_CONV_out(addr_write_OSP_CONV_out),
    .addr_write_FCSP_ML_out(addr_write_FCSP_ML_out),
    .addr_write_FCSP_CONV_out(addr_write_FCSP_CONV_out),
    .addr_write_OB_ML_out(addr_write_OB_ML_out),
    .addr_write_OB_CONV_out(addr_write_OB_CONV_out),
    .addr_read_OB_ML_out(addr_read_OB_ML_out),
    .OB_read_out(OB_read_out),
    .MEM_read_out(MEM_read_out),
    .en_MC_read_OB(ren_OB),
    .addr_MC_read_OB(addr_DNN),   
    .data_MC_read_OB(data_r_DNN),
    .addr_read_IB(addr_read_IB),
    .done_DNN(done_DNN)

    );



assign DSIP_done = (end_flag & done_DNN);



endmodule
