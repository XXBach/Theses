`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/23/2025 09:14:37 AM
// Design Name: 
// Module Name: ASIP_one_one
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

module ASIP_one_one#(
    parameter INSTRUCTION_WIDTH = 32,
    parameter MCMEM_SIZE = 4096,
    parameter DATA_WIDTH_MC = 32,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH_DNN_CORE = 16,
    parameter DECIMAL_BIT = 8,
    parameter INSTRUCTION_WIDTH_DNN_CORE = 212,
    parameter BUFFER_SIZE = 512,
    parameter SCRATCHPAD_SIZE = 512,
    parameter BLOCKS_PER_ROW = 64,
    parameter MODEL = `ONE_ONE,
    parameter IS_FIRST_ROW = 1,
    parameter IS_FIRST_COL = 1,
    parameter BASE_DATA_OM = 32'h00010000
)(
    // Inputs
    input wire clk,
    input wire rst,
    input wire start,
    input wire wen_MCMem_1, wen_MCMem_2,
    input wire [$clog2(MCMEM_SIZE)-1:0] addr_w_MCMem_1, addr_w_MCMem_2,
    input wire [INSTRUCTION_WIDTH-1:0] data_w_MCMem_1, data_w_MCMem_2,
    input wire vsync_in_1, vsync_in_2,
    input wire hsync_in_1, hsync_in_2,
    //bit all_DNN_done_signal;
    output wire vsync_out_1, vsync_out_2,
    output wire hsync_out_1, hsync_out_2,
    output wire start_DNN_core_1, start_DNN_core_2,
    output wire end_flag_1, end_flag_2,
    
    //PORT0 ==============
    input wire [67:0] command_P0_in_1, command_P0_in_2,
    input wire [15:0] data_P0_in_1, data_P0_in_2,
    output wire [67:0] command_P0_out_1, command_P0_out_2,
    output wire [15:0] data_P0_out_1, data_P0_out_2,
    
    //PORT1
    input wire [67:0] command_P1_in_1, command_P1_in_2,
    input wire [15:0] data_P1_in_1, data_P1_in_2,
    output wire [67:0] command_P1_out_1, command_P1_out_2,
    output wire [15:0] data_P1_out_1, data_P1_out_2,
    
    
    //PORT OM
    output wire [31:0] addr_OM_1, addr_OM_2,
    output wire wen_OM_1, wen_OM_2,
    output wire ren_OM_1, ren_OM_2,
    input wire [31:0] data_r_OM_1, data_r_OM_2,
    output wire [31:0] data_w_OM_1, data_w_OM_2,
    output wire ren_OM_inst_1, ren_OM_inst_2,
    input wire [211:0] inst_r_OM_1, inst_r_OM_2,
    
    //PORT DNN core
    output wire [8:0] addr_DNN_1, addr_DNN_2,
    output wire wen_inst_mem_1, wen_inst_mem_2,
    output wire [63:0] wen_IB_1, wen_IB_2,
    output wire [63:0] wen_KSP_1, wen_KSP_2,
    output wire wen_BSP_1, wen_BSP_2,
    output wire ren_OB_1, ren_OB_2,
    output wire [31:0] data_w_DNN_1, data_w_DNN_2,
    output wire [211:0] inst_w_DNN_1, inst_w_DNN_2,
    input wire done_transfer_prev_1, done_transfer_prev_2,
    output wire done_transfer_1, done_transfer_2,
    
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB_1, addr_write_OB_2,
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OB_1, addr_read_OB_2,
    
    input wire [7:0] select_1, select_2,
    
    output wire [DATA_WIDTH_DNN_CORE - 1 : 0] NEOA_read_out_1, NEOA_read_out_2,
    output wire sel_lut_1, sel_lut_2,
    
    output wire [DATA_WIDTH_DNN_CORE - 1 : 0] li_data_out_1, li_data_out_2,
    
    output wire [DATA_WIDTH_DNN_CORE - 1 : 0] POA_read_out_1, POA_read_out_2,
    
    
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_ML_out_1, addr_write_OSP_ML_out_2,
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_CONV_out_1, addr_write_OSP_CONV_out_2,
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_FCSP_ML_out_1, addr_write_FCSP_ML_out_2,
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB_ML_out_1, addr_write_OB_ML_out_2,
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OB_ML_out_1, addr_read_OB_ML_out_2,
    output wire [DATA_WIDTH_DNN_CORE - 1 : 0] OB_read_out_1, OB_read_out_2,
    output wire [DATA_WIDTH_DNN_CORE - 1 : 0] MEM_read_out_1, MEM_read_out_2,
    
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_IB_1, addr_read_IB_2,
    output wire done_DNN_1, done_DNN_2,
    
    output wire DSIP_done_1, DSIP_done_2
    );
    wire hsync_in_all = hsync_out_1 & hsync_out_2;
    ASIP #(
    .INSTRUCTION_WIDTH(INSTRUCTION_WIDTH),
    .MCMEM_SIZE(MCMEM_SIZE),
    .DATA_WIDTH_MC(DATA_WIDTH_MC),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH_DNN_CORE(DATA_WIDTH_DNN_CORE),
    .DECIMAL_BIT(DECIMAL_BIT),
    .INSTRUCTION_WIDTH_DNN_CORE(INSTRUCTION_WIDTH_DNN_CORE),
    .BUFFER_SIZE(BUFFER_SIZE),
    .SCRATCHPAD_SIZE(SCRATCHPAD_SIZE),
    .BLOCKS_PER_ROW(BLOCKS_PER_ROW),
    .BASE_DATA_OM(BASE_DATA_OM),
    .MODEL(MODEL),
    .IS_FIRST_ROW(1),
    .IS_FIRST_COL(IS_FIRST_COL)
) uut1 (
    .clk(clk),
    .rst(rst),
    .start(start),
    .wen_MCMem(wen_MCMem_1),
    .addr_w_MCMem(addr_w_MCMem_1),
    .data_w_MCMem(data_w_MCMem_1),
    
    .vsync_in(vsync_out_1),             // do chỉ có 1 ASIP trên 1 cột nên vsync_in = vsync_out
    .hsync_in(hsync_in_all),
    .vsync_out(vsync_out_1),
    .hsync_out(hsync_out_1),
    .start_DNN_core(start_DNN_core_1),
    .end_flag(end_flag_1),
//PORT0 ==============
    .command_P0_in(command_P0_in_1),
    .data_P0_in(data_P0_in_1),
    .command_P0_out(command_P0_out_1),
    .data_P0_out(data_P0_out_1),
//PORT1
    .command_P1_in(command_P1_in_1),
    .data_P1_in(data_P1_in_1),
    .command_P1_out(command_P1_out_1),
    .data_P1_out(data_P1_out_1),
//PORT OM
    .addr_OM(addr_OM_1),
    .wen_OM(wen_OM_1),
    .ren_OM(ren_OM_1),
    .data_r_OM(data_r_OM_1),
    .data_w_OM(data_w_OM_1),
    .ren_OM_inst(ren_OM_inst_1),
    .inst_r_OM(inst_r_OM_1),
//PORT DNN core
    .addr_DNN(addr_DNN_1),
    .wen_inst_mem(wen_inst_mem_1),
    .wen_IB(wen_IB_1),
    .wen_KSP(wen_KSP_1),
    .wen_BSP(wen_BSP_1),
    .ren_OB(ren_OB_1),
    .data_w_DNN(data_w_DNN_1),
    .inst_w_DNN(inst_w_DNN_1),
    .done_transfer_prev(done_transfer_prev_1),
    .done_transfer(done_transfer_1),

    .done_DNN(done_DNN_1),
    .DSIP_done(DSIP_done_1)
);

ASIP #(
    .INSTRUCTION_WIDTH(INSTRUCTION_WIDTH),
    .MCMEM_SIZE(MCMEM_SIZE),
    .DATA_WIDTH_MC(DATA_WIDTH_MC),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH_DNN_CORE(DATA_WIDTH_DNN_CORE),
    .DECIMAL_BIT(DECIMAL_BIT),
    .INSTRUCTION_WIDTH_DNN_CORE(INSTRUCTION_WIDTH_DNN_CORE),
    .BUFFER_SIZE(BUFFER_SIZE),
    .SCRATCHPAD_SIZE(SCRATCHPAD_SIZE),
    .BLOCKS_PER_ROW(BLOCKS_PER_ROW),
    .BASE_DATA_OM(BASE_DATA_OM),
    .MODEL(MODEL),
    .IS_FIRST_ROW(IS_FIRST_ROW),
    .IS_FIRST_COL(0)
) uut2 (
    .clk(clk),
    .rst(rst),
    .start(start),
    .wen_MCMem(wen_MCMem_2),
    .addr_w_MCMem(addr_w_MCMem_2),
    .data_w_MCMem(data_w_MCMem_2),
    
    .vsync_in(vsync_out_2),             // do chỉ có 1 ASIP trên 1 cột nên vsync_in = vsync_out
    .hsync_in(hsync_in_all),
    .vsync_out(vsync_out_2),
    .hsync_out(hsync_out_2),
    .start_DNN_core(start_DNN_core_2),
    .end_flag(end_flag_2),
//PORT0 ==============
    .command_P0_in(command_P0_out_1),       // ASIP 1 PORT0 out -> ASIP 2 PORT0 in
    .data_P0_in(data_P0_out_1),
    .command_P0_out(command_P0_out_2),
    .data_P0_out(data_P0_out_2),
//PORT1
    .command_P1_in(command_P1_in_2),
    .data_P1_in(data_P1_in_2),
    .command_P1_out(command_P1_out_2),
    .data_P1_out(data_P1_out_2),
//PORT OM
    .addr_OM(addr_OM_2),
    .wen_OM(wen_OM_2),
    .ren_OM(ren_OM_2),
    .data_r_OM(data_r_OM_2),
    .data_w_OM(data_w_OM_2),
    .ren_OM_inst(ren_OM_inst_2),
    .inst_r_OM(inst_r_OM_2),
//PORT DNN core
    .addr_DNN(addr_DNN_2),
    .wen_inst_mem(wen_inst_mem_2),
    .wen_IB(wen_IB_2),
    .wen_KSP(wen_KSP_2),
    .wen_BSP(wen_BSP_2),
    .ren_OB(ren_OB_2),
    .data_w_DNN(data_w_DNN_2),
    .inst_w_DNN(inst_w_DNN_2),
    .done_transfer_prev(done_transfer_1),       // = done transfer của ASIP trước
    .done_transfer(done_transfer_2),

    .done_DNN(done_DNN_2),
    .DSIP_done(DSIP_done_2)
);
endmodule
