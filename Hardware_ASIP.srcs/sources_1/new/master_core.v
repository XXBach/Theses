`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/10/2025 09:37:39 PM
// Design Name: 
// Module Name: master_core
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

module master_core #(
    parameter INSTRUCTION_WIDTH = 32,
    parameter MCMEM_SIZE = 32,
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter BASE_DATA_OM = 32'h00010000,
    // PARAM OF MODE CONTROLLER
    parameter MODEL = `ONE_ONE,
    parameter IS_FIRST_ROW = 1,
    parameter IS_FIRST_COL = 1
    
    
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
    input wire DNN_done,                   // = all DNN_done_signal
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
    input wire [31:0] data_r_DNN,
    output wire [211:0] inst_w_DNN,
    
    input wire done_transfer_prev,
    output wire done_transfer
    
    );
    reg start_flag;
    // Tín hiệu start chỉ để 1 chu kỳ
    always @(posedge clk or posedge rst) begin
        if(rst) start_flag = 0;
        else if(start) start_flag = ~start_flag;
//        else if(end_flag) start_flag = 0;
    end
    
    wire PC_sel;
    wire [15:0] imm16;
    wire [DATA_WIDTH - 1:0] extend_imm16;
    wire [DATA_WIDTH - 1:0] extend_imm16_shift;
    // Khai bao PC
    reg [$clog2(MCMEM_SIZE)-1:0] PC;
    wire enable_PC;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            PC = 0;
        end
        else if(end_flag) PC = 0;
        else if(start_flag) begin
            if(enable_PC) begin
                if(!PC_sel) PC = PC + 1;
                else PC = imm16;
            end
            else begin
                PC = PC;
            end
        end
        
    end
    wire [DATA_WIDTH-1:0] instruction; 
    
    // Khai bao MCMem
    memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .SIZE(MCMEM_SIZE),
        .EN_OUT_FF(0)) MCMem(.clk(clk),
                             .wen(wen_MCMem),
                             .ren(1'b1),
                             .addr_w(addr_w_MCMem),
                             .addr_r(PC),
                             .din(data_w_MCMem),
                             .dout(instruction));
           

    wire [4:0] RD;
    wire [4:0] RA;
    wire [4:0] RB;
    wire [4:0] Rtemp;

//    wire [4:0] shamt;
    wire [2:0] alu_op;
    wire [1:0] select_alu_operand_1;
    wire [2:0] select_alu_operand_2;
    wire br_signal;                  // br jump signal
    wire cbr_signal;                 // cbr jump signal
    wire wen_rf;                    // enable write Register File
    wire [3:0] type_access;
    MC_decoder #(.INSTRUCTION_WIDTH(INSTRUCTION_WIDTH)) mcdecoder(
        .instruction(instruction),                              // lenh
        .RD(RD),                                                // 
        .RA(RA),
        .RB(RB),
        .Rtemp(Rtemp),
//        .shamt(shamt),
        .imm16(imm16),
        .alu_op(alu_op),
        .select_alu_operand_1(select_alu_operand_1),
        .select_alu_operand_2(select_alu_operand_2),
        .br_signal(br_signal),                  // br jump signal
        .cbr_signal(cbr_signal),                 // cbr jump signal
        .wen_rf(wen_rf),
        .type_access(type_access)
); 

    wire [DATA_WIDTH - 1:0] r_data_RA;
    wire [DATA_WIDTH - 1:0] r_data_RB;
    wire [DATA_WIDTH - 1:0] r_data_RD;
    wire wen_rf_reg;
    wire [DATA_WIDTH - 1:0] alu_result;
    wire [4:0] RD_reg;
    wire [DATA_WIDTH - 1:0] alu_result_reg;
    wire wen_rf_reg_2;
    wire [4:0] RD_reg_2;
    wire [DATA_WIDTH - 1:0] r_data_Rtemp;
    
    // Khai bao register file
    register_file #(
        .SIZE(32),
        .DATA_WIDTH(DATA_WIDTH)
 )rf (
    .clk(clk),
    .rst(rst),
    .RA(RA),
    .RB(RB),
    .RD_r(RD),
    .Rtemp(Rtemp),
    .RD_w(RD_reg_2),
    .wen(wen_rf_reg_2),
    .w_data(alu_result_reg),
    .r_data_RA(r_data_RA),
    .r_data_RB(r_data_RB),
    .r_data_RD(r_data_RD),
    .r_data_Rtemp(r_data_Rtemp)
 );       
    
    assign extend_imm16 = {16'b0, imm16};
    assign extend_imm16_shift = extend_imm16<<16;
    
    //Region A ========================================================================================
    branch_decision #(.DATA_WIDTH(DATA_WIDTH))
        decide_pc(.r_data_RA(r_data_RA),
        .br(br_signal),
        .cbr(cbr_signal),
        .PC_sel(PC_sel)
        );
    
    
    wire [DATA_WIDTH - 1:0] alu_operand_1;
    wire [DATA_WIDTH - 1:0] alu_operand_2;
//    assign alu_operand_1 = (select_alu_operand_1 == 0) ? r_data_RA:
//                           (select_alu_operand_1 == 1) ? r_data_RD:
//                           (select_alu_operand_1 == 2) ? 'b0:'bz;
    mux4_32bit mux_sel_operand_1(
        .data_in0(r_data_RA), 
        .data_in1('bz), 
        .data_in2('b0), 
        .data_in3('bz), 
        .sel(select_alu_operand_1),       
        .data_out(alu_operand_1));
                           
//    assign alu_operand_2 = (select_alu_operand_2 == 0) ? r_data_RB:
//                           (select_alu_operand_2 == 1) ? extend_imm16:
//                           (select_alu_operand_2 == 2) ? 0:
//                           (select_alu_operand_2 == 3) ? 1:
//                           (select_alu_operand_2 == 4) ? extend_imm16_shift:'bz;
     
    mux8_32bit mux_sel_operand_2(
        .data_in0(r_data_RB), 
        .data_in1(extend_imm16), 
        .data_in2('b0), 
        .data_in3(1), 
        .data_in4(extend_imm16_shift), 
        .data_in5('bz), 
        .data_in6('bz), 
        .data_in7('bz), 
        .sel(select_alu_operand_2),       
        .data_out(alu_operand_2));
                       
    wire [DATA_WIDTH - 1:0] alu_operand_1_reg;
    wire [DATA_WIDTH - 1:0] alu_operand_2_reg;
    wire [2:0] alu_op_reg;
    wire [4:0] RA_reg;
    wire [4:0] RB_reg;
   
    //thanh ghi chot operand 1   
    register #(.DATA_WIDTH(DATA_WIDTH)) DRA(.clk(!clk), .rst(rst), .wen(1'b1), .data_in(alu_operand_1), .data_out(alu_operand_1_reg));      
    //thanh ghi chot operand 2 
    register #(.DATA_WIDTH(DATA_WIDTH)) DRB(.clk(!clk), .rst(rst), .wen(1'b1), .data_in(alu_operand_2), .data_out(alu_operand_2_reg));
    //thanh ghi chot dia chi dich
    register #(.DATA_WIDTH(5)) ARD(.clk(!clk), .rst(rst), .wen(1'b1), .data_in(RD), .data_out(RD_reg));
    //thanh ghi chot tin hieu wen register file
    register #(.DATA_WIDTH(1)) WENRF(.clk(!clk), .rst(rst), .wen(1'b1), .data_in(wen_rf), .data_out(wen_rf_reg));
    //thanh ghi chot alu_op 
    register #(.DATA_WIDTH(3)) ALUOPREG(.clk(!clk), .rst(rst), .wen(1'b1), .data_in(alu_op), .data_out(alu_op_reg));
    //thanh ghi chot dia chi nguon RA
    register #(.DATA_WIDTH(5)) ARA(.clk(!clk), .rst(rst), .wen(1'b1), .data_in(RA), .data_out(RA_reg));
    //thanh ghi chot dia chi nguon RB
    register #(.DATA_WIDTH(5)) ARB(.clk(!clk), .rst(rst), .wen(1'b1), .data_in(RB), .data_out(RB_reg));
    
    wire [5:0] opcode_reg;
    register #(.DATA_WIDTH(6)) OPR(.clk(!clk), .rst(rst), .wen(1'b1), .data_in(instruction[31:26]), .data_out(opcode_reg));
    
    wire sel_RA_forw;
    wire sel_RB_forw;
    control_forward #(
    .DATA_WIDTH(DATA_WIDTH)
        ) forwarding_block(
                            .opcode(opcode_reg),
                            .RD_before(RD_reg_2),
                            .RA(RA_reg),
                            .RB(RB_reg),
                            .sel_RA_forw(sel_RA_forw),
                            .sel_RB_forw(sel_RB_forw));
    
    wire [DATA_WIDTH - 1:0] alu_operand_1_final;
    wire [DATA_WIDTH - 1:0] alu_operand_2_final;
    assign alu_operand_1_final = (sel_RA_forw == 0) ? alu_operand_1_reg : alu_result_reg;
    assign alu_operand_2_final = (sel_RB_forw == 0) ? alu_operand_2_reg : alu_result_reg;

    MC_ALU #(
    .DATA_WIDTH(DATA_WIDTH)
    ) alu(
        .operand_1(alu_operand_1_final),  // RA(0), RD(1), 0(2)
        .operand_2(alu_operand_2_final),   // RB(0), imm16(1), 0(2), 1(3), imm16<<16(4)
        .alu_op(alu_op_reg),
        .result(alu_result)
    );
    
    register #(.DATA_WIDTH(DATA_WIDTH)) ALUREG(.clk(!clk), .rst(rst), .wen(1'b1), .data_in(alu_result), .data_out(alu_result_reg));
    register #(.DATA_WIDTH(1)) WENRF2(.clk(!clk), .rst(rst), .wen(1'b1), .data_in(wen_rf_reg), .data_out(wen_rf_reg_2));
    register #(.DATA_WIDTH(5)) ARD2(.clk(!clk), .rst(rst), .wen(1'b1), .data_in(RD_reg), .data_out(RD_reg_2));    


    // Regison B =============================================================================================================
    wire [DATA_WIDTH - 1:0] addr_base_src = r_data_RD;
    wire [DATA_WIDTH - 1:0] addr_offset_src = r_data_RA;
    wire [DATA_WIDTH - 1:0] addr_base_dest = r_data_RB;
    wire [DATA_WIDTH - 1:0] addr_offset_dest = r_data_Rtemp;
    wire [3:0] type_access_reg;
    wire [DATA_WIDTH - 1:0] addr_base_src_reg;
    wire [DATA_WIDTH - 1:0] addr_offset_src_reg;
    wire [DATA_WIDTH - 1:0] addr_base_dest_reg;
    wire [DATA_WIDTH - 1:0] addr_offset_dest_reg;

    register #(.DATA_WIDTH(4)) IR(.clk(!clk), .rst(rst), .wen(1'b1), .data_in(type_access), .data_out(type_access_reg));
    register #(.DATA_WIDTH(DATA_WIDTH)) DR_Base_OM(.clk(!clk), .rst(rst), .wen(1'b1), .data_in(addr_base_src), .data_out(addr_base_src_reg));
    register #(.DATA_WIDTH(DATA_WIDTH)) DR_Offset_OM(.clk(!clk), .rst(rst), .wen(1'b1), .data_in(addr_offset_src), .data_out(addr_offset_src_reg));
    register #(.DATA_WIDTH(DATA_WIDTH)) DR_Base_DNN(.clk(!clk), .rst(rst), .wen(1'b1), .data_in(addr_base_dest), .data_out(addr_base_dest_reg));
    register #(.DATA_WIDTH(DATA_WIDTH)) DR_Offset_DNN(.clk(!clk), .rst(rst), .wen(1'b1), .data_in(addr_offset_dest), .data_out(addr_offset_dest_reg));
    
    wire [67:0] command;  
    //MACG
    MemAccess_Generator #(
        .DATA_WIDTH(DATA_WIDTH)
    ) macg_block(
        .base_addr_src(addr_base_src_reg),         
        .offset_addr_src(addr_offset_src_reg),
        .base_addr_dest(addr_base_dest_reg),    
        .offset_addr_dest(addr_offset_dest_reg),
        .type_access(type_access_reg),
        .command(command));
          
    wire [67:0] command_reg;
    // Khai bao CMD Register
    register #(.DATA_WIDTH(68)) CMD_REG(.clk(!clk), .rst(rst), .wen(1'b1), .data_in(command), .data_out(command_reg));
    
    memory_controller_2 #(
        .BASE_DATA_OM(BASE_DATA_OM)
    )mctrl(
        .clk(clk),
        .rst(rst),


    // command from controller
        .command_mc(command_reg),
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
        .inst_w_DNN(inst_w_DNN)
);
    

    
    // Region C ==========================================================================================
    generate
        if(MODEL == `SINGLE) begin
                mode_controller_2 mode_ctr(
                    .opcode(instruction[31:26]),            
                    .clk(!clk),
                    .rst(rst),    
                    .start(start),                       // tin hieu bat dau DSIP
                    .vsync_in(vsync_in),                    // tin hieu dong bo chieu doc tu cac DSIP subsequence
                    .DNN_done(DNN_done),
                    .vsync_out(vsync_out),
                    .start_DNN_core(start_DNN_core),                  // tin hieu dau ra de bat dau kich hoat cho DNN core hoat dong
                    .end_flag(end_flag),                    // tin hieu bao rang ket thuc lenh
                    .enable_PC(enable_PC)
            );
        end
        else if(MODEL == `ONE_ONE) begin
                mode_controller_3  #(
                    .IS_FIRST_ROW(IS_FIRST_ROW),
                    .IS_FIRST_COL(IS_FIRST_COL)
                ) mode_ctr(
                    .opcode(instruction[31:26]),            
                    .clk(!clk),
                    .rst(rst),    
                    .start(start),                       // tin hieu bat dau DSIP
                    .vsync_in(vsync_in),
                    .hsync_in(hsync_in),
                    .DNN_done(DNN_done),
                    .vsync_out(vsync_out),
                    .hsync_out(hsync_out),
                    .start_DNN_core(start_DNN_core),
                    .enable_PC(enable_PC),
                    .end_flag(end_flag),
                    .done_transfer_prev(done_transfer_prev),
                    .done_transfer(done_transfer)
                );
        end 
    endgenerate 
endmodule

//==========================================================================================================================================
//==========================================================================================================================================
//==========================================================================================================================================
//==========================================================================================================================================
//==========================================================================================================================================
//==========================================================================================================================================
module register_file #(
    parameter SIZE = 32,
    parameter DATA_WIDTH = 32
)(
    input wire clk,
    input wire rst,
    input wire [4:0] RA,        // addr read RA
    input wire [4:0] RB,        // addr read RB
    input wire [4:0] RD_r,      // addr read RD
    input wire [4:0] Rtemp,
    input wire [4:0] RD_w,      // addr write RD
    input wire wen,
    input wire [DATA_WIDTH-1:0] w_data,
    output wire [DATA_WIDTH-1:0] r_data_RA,
    output wire [DATA_WIDTH-1:0] r_data_RB,
    output wire [DATA_WIDTH-1:0] r_data_RD,
    output wire [DATA_WIDTH-1:0] r_data_Rtemp

    );
    
    reg [DATA_WIDTH - 1 : 0] mem [SIZE - 1 : 0];
    integer i;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            for(i = 0; i < SIZE; i = i + 1) mem[i] <= 0;
        end
        else begin
            
            if(wen)
                if(RD_w != 0)
                    mem[RD_w] <= w_data;
        end
    end
    assign r_data_RA = mem[RA];
    assign r_data_RB = mem[RB];
    assign r_data_RD = mem[RD_r];
    assign r_data_Rtemp = mem[Rtemp];

endmodule

//==========================================================================================================================================
module MC_decoder #(
    parameter INSTRUCTION_WIDTH = 32
)(
    input wire [INSTRUCTION_WIDTH-1:0] instruction,
    output wire [4:0] RD,
    output wire [4:0] RA,
    output wire [4:0] RB,
    output wire [4:0] Rtemp,
    //    output wire [4:0] shamt,
    output wire [15:0] imm16,
    output reg [2:0] alu_op,
    output reg [1:0] select_alu_operand_1,
    output reg [2:0] select_alu_operand_2,
    output wire br_signal,                  // br jump signal
    output wire cbr_signal,                 // cbr jump signal
//    output wire [4:0] base_s,               // base addr source
//    output wire [4:0] offset_s,             // offset addr source
//    output wire [4:0] base_d,               // base addr destination
//    output wire [4:0] offset_d,             // offset addr destination,
    output reg wen_rf,                      // enable write Register File
    output wire [3:0] type_access                   // load or store OM
);
    wire [5:0] opcode;
    assign opcode = instruction[31:26];
    
    assign RD = instruction[25:21];
    assign RA = instruction[20:16];
    assign RB = instruction[15:11];
    assign Rtemp = instruction[10:6];
//    assign shamt = instruction[10:6];
    assign imm16 = instruction[15:0];
//    assign base_s = instruction[25:21];
//    assign offset_s = instruction[20:16];
//    assign base_d = instruction[15:11];
//    assign offset_d = instruction[10:6];
    
    assign br_signal = (opcode == 6'b010011) ? 1'b1 : 1'b0;
    assign cbr_signal = (opcode == 6'b010100) ? 1'b1 : 1'b0;
    
    assign type_access = (opcode == 6'b100000) ? 4'b0001:
                         (opcode == 6'b100001) ? 4'b0010:
                         (opcode == 6'b100010) ? 4'b0011:
                         (opcode == 6'b100011) ? 4'b0100: 4'b0000;
    always @(*) begin
        case(opcode)
            6'b000000: begin            // RD = RA + RB
                alu_op = 0; select_alu_operand_2 = 0; select_alu_operand_1 = 0; wen_rf = 1;
            end
            6'b000001: begin            // RD = RA - RB
                alu_op = 1; select_alu_operand_2 = 0; select_alu_operand_1 = 0; wen_rf = 1;
            end
            6'b000010: begin            // RD = RA x RB
                alu_op = 2; select_alu_operand_2 = 0; select_alu_operand_1 = 0; wen_rf = 1;
            end
            6'b000011: begin            // RD = RA & RB
                alu_op = 4; select_alu_operand_2 = 0; select_alu_operand_1 = 0; wen_rf = 1;
            end 
            6'b000100: begin            // RD = RA | RB
                alu_op = 5; select_alu_operand_2 = 0; select_alu_operand_1 = 0; wen_rf = 1;
            end
            6'b000101: begin            // RD = RA + 1
                alu_op = 0; select_alu_operand_2 = 3; select_alu_operand_1 = 0; wen_rf = 1;
            end
            6'b000110: begin            // RD = RA - 1
                alu_op = 1; select_alu_operand_2 = 3; select_alu_operand_1 = 0; wen_rf = 1;
            end
            6'b000111: begin            //RD = RA >> imm16
                alu_op = 3; select_alu_operand_2 = 1; select_alu_operand_1 = 0; wen_rf = 1;
            end
            6'b001000: begin            //RD = RA + imm16
                alu_op = 0; select_alu_operand_2 = 1; select_alu_operand_1 = 0; wen_rf = 1;
            end
            6'b001001: begin            //RD = RA - imm16
                alu_op = 1; select_alu_operand_2 = 1; select_alu_operand_1 = 0; wen_rf = 1;
            end
            6'b001010: begin            //RD = RA x imm16
                alu_op = 2; select_alu_operand_2 = 1; select_alu_operand_1 = 0; wen_rf = 1;
            end 
            6'b001011: begin            //RD = RA & imm16
                alu_op = 4; select_alu_operand_2 = 1; select_alu_operand_1 = 0; wen_rf = 1;
            end 
            6'b001100: begin            //RD = RA | imm16
                alu_op = 5; select_alu_operand_2 = 1; select_alu_operand_1 = 0; wen_rf = 1;
            end  
            6'b001101: begin            // RD = RA
                alu_op = 0; select_alu_operand_2 = 2; select_alu_operand_1 = 0; wen_rf = 1;
            end
            6'b001110: begin            //RD = imm16
                alu_op = 0; select_alu_operand_2 = 1; select_alu_operand_1 = 2; wen_rf = 1;
            end
            6'b001111: begin            //RD = (imm16<16)
                alu_op = 0; select_alu_operand_2 = 4; select_alu_operand_1 = 2; wen_rf = 1;
            end
            default: begin
                alu_op = 0; select_alu_operand_2 = 0; select_alu_operand_1 = 0; wen_rf = 0;
            end
        endcase
    end
endmodule


//==========================================================================================================================================
//operator: +, -, *, >>, &, |
module MC_ALU #(
    parameter DATA_WIDTH = 32
)(
    input wire [DATA_WIDTH - 1 : 0] operand_1,  // RA(0), RD(1), 0(2)
    input wire [DATA_WIDTH - 1: 0] operand_2,   // RB(0), imm16(1), 0(2), 1(3), imm16<<16(4)
    input wire [2:0] alu_op,
    output reg [DATA_WIDTH - 1:0] result
);
    reg [DATA_WIDTH * 2 - 1:0] mul_result_temp;
    always @(*) begin
        if(alu_op == 0) result =  operand_1 + operand_2;
        else if(alu_op == 1) result = operand_1 - operand_2;
        else if(alu_op == 2) begin
             mul_result_temp = operand_1 * operand_2;
             result = mul_result_temp[31:0];
        end
        else if(alu_op == 3) result = operand_1 >>> operand_2;
        else if(alu_op == 4) result = operand_1 & operand_2;
        else if(alu_op == 5) result = operand_1 | operand_2;
        else result = 'bz;
    end
endmodule

//==========================================================================================================================================
module branch_decision #(
    parameter DATA_WIDTH = 32
)(
    input wire [DATA_WIDTH - 1 : 0] r_data_RA,
    input wire br,
    input wire cbr,
    output reg PC_sel
);
    always @(*) begin
        if(br) PC_sel = 1;
        else if(r_data_RA !== 0 && cbr) PC_sel = 1;
        else PC_sel = 0;
    end
endmodule


//==========================================================================================================================================
module MemAccess_Generator #(
    parameter DATA_WIDTH = 32
)(
    input wire [DATA_WIDTH - 1:0] base_addr_src,         
    input wire [DATA_WIDTH - 1:0] offset_addr_src,
    input wire [DATA_WIDTH - 1:0] base_addr_dest,    
    input wire [DATA_WIDTH - 1:0] offset_addr_dest,
    input wire [3:0] type_access,
    output reg [67:0] command
    
);
    reg [DATA_WIDTH - 1:0] addr_src;
    reg [DATA_WIDTH - 1:0] addr_dest;

    always @(*) begin
        addr_src = base_addr_src + offset_addr_src;
        addr_dest = base_addr_dest + offset_addr_dest;
        command = {type_access, addr_src, addr_dest};        //kiểu truy cập (load-store), chọn loại bộ nhớ DNN, addr OM, addr DNN
    end
endmodule

//==========================================================================================================================================
module control_forward #(
    parameter DATA_WIDTH = 32
)(
    input wire [5:0] opcode,
    input wire [4:0] RD_before,
    input wire [4:0] RA,
    input wire [4:0] RB,
    output reg sel_RA_forw,
    output reg sel_RB_forw
    );
    always @(*) begin
        if(opcode >=6'b000000 && opcode <= 6'b000100) begin
            if(RD_before == RA && RD_before != 0) sel_RA_forw = 1'b1;
                else sel_RA_forw = 1'b0;
            if(RD_before == RB && RD_before != 0) sel_RB_forw = 1'b1;
                else sel_RB_forw = 1'b0;
        end
        else if(opcode >=6'b000101 && opcode <=6'b001111) begin
            if(RD_before == RA && RD_before != 0) sel_RA_forw = 1'b1;
                else sel_RA_forw = 1'b0;
            sel_RB_forw = 1'b0;
        end
        else begin
            sel_RA_forw = 1'b0;
            sel_RB_forw = 1'b0;
        end
    end
endmodule

//==========================================================================================================================================
module mux4_32bit (
    input wire [31:0] data_in0, // Đầu vào 32-bit 0
    input wire [31:0] data_in1, // Đầu vào 32-bit 1
    input wire [31:0] data_in2, // Đầu vào 32-bit 2
    input wire [31:0] data_in3, // Đầu vào 32-bit 3
    input wire [1:0] sel,       // Tín hiệu chọn lựa (2 bit)
    output wire [31:0] data_out // Đầu ra 32-bit
);
    assign data_out = (sel == 2'b00) ? data_in0 :
                      (sel == 2'b01) ? data_in1 :
                      (sel == 2'b10) ? data_in2 :
                      data_in3; // sel == 2'b11
endmodule


module mux8_32bit (
    input wire [31:0] data_in0, // Đầu vào 32-bit 0
    input wire [31:0] data_in1, // Đầu vào 32-bit 1
    input wire [31:0] data_in2, // Đầu vào 32-bit 2
    input wire [31:0] data_in3, // Đầu vào 32-bit 3
    input wire [31:0] data_in4, // Đầu vào 32-bit 4
    input wire [31:0] data_in5, // Đầu vào 32-bit 5
    input wire [31:0] data_in6, // Đầu vào 32-bit 6
    input wire [31:0] data_in7, // Đầu vào 32-bit 7
    input wire [2:0] sel,       // Tín hiệu chọn lựa (3 bit)
    output wire [31:0] data_out // Đầu ra 32-bit
);
    assign data_out = (sel == 3'b000) ? data_in0 :
                      (sel == 3'b001) ? data_in1 :
                      (sel == 3'b010) ? data_in2 :
                      (sel == 3'b011) ? data_in3 :
                      (sel == 3'b100) ? data_in4 :
                      (sel == 3'b101) ? data_in5 :
                      (sel == 3'b110) ? data_in6 :
                      data_in7; // sel == 3'b111
endmodule

//==========================================================================================================================================

module memory_controller #(
    parameter BASE_DATA_OM = 32'h00010000
)(
    input wire clk,
    input wire rst,


    // command from controller
    input wire [67:0] command_mc,
    //PORT0 ==============
    input wire [67:0] command_P0_in,
    input wire [31:0] data_P0_in,
    output wire [31:0] command_P0_out,
    output wire [31:0] data_P0_out,
    
    //PORT1
    input wire [67:0] command_P1_in,
    input wire [31:0] data_P1_in,
    output wire [31:0] command_P1_out,
    output wire [31:0] data_P1_out,
    
    
    //PORT OM
    output reg [31:0] addr_OM,
    output reg wen_OM,
    output reg ren_OM,
    input wire [31:0] data_r_OM,
    output reg [31:0] data_w_OM,
    output reg ren_OM_inst,
    input wire [211:0] inst_r_OM, 
    
    //PORT DNN core
    output reg [8:0] addr_DNN,
    output reg wen_inst_mem,
    output reg [63:0] wen_IB,
    output reg [63:0] wen_KSP,
    output reg wen_BSP,
    output reg ren_OB,
    output reg [31:0] data_w_DNN,
    input wire [31:0] data_r_DNN,
    output reg [211:0] inst_w_DNN
);
    reg [31:0] data_r_OM_temp;
    reg [211:0] inst_r_OM_temp;
    reg [2:0] state;
    reg [67:0] command_temp;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state = 0;
            command_temp = 0;
        end
        else begin
            //state = 0 va co lenh tu mc
             if(state == 0 && command_mc[67:64] == 4'b0001) begin       // MEM -> DNN
                state = 1;
                command_temp = command_mc;
             end
             
  

             else if(state == 0 && command_mc[67:64] == 4'b0100) begin
                state = 3;
                command_temp = command_mc;
             end
             else if(state == 1) state = 2;
//             else if(state == 2) state = 3;
             else if(state == 2) begin
                state = 0;
                command_temp = 0;
             end
             else if(state == 3) state = 4;
             else if(state == 4) begin
                state = 0;
                command_temp = 0;
             end
        end
    end
    
    always @(*) begin
        if(state == 0) begin
            //PORT OM
            addr_OM = 0;
            wen_OM = 0;
            ren_OM = 0;
            data_w_OM = 0;
            ren_OM_inst = 0;
            
            //PORT DNN core
            addr_DNN = 0;
            wen_inst_mem = 0;
            wen_IB = 0;
            wen_KSP = 0;
            wen_BSP = 0;
            ren_OB = 0;
            data_w_DNN = 0;
            inst_w_DNN = 0;
        end
        
//xu ly voi truong hop chuyen data tu MEM sang DNN
        else if(state == 1) begin              
            //OM 
            addr_OM = command_temp[63:32];
            wen_OM = 0;
            data_w_OM = 0;
            
            if(addr_OM < BASE_DATA_OM) ren_OM_inst = 1;
            else ren_OM = 1;
            
            
        end 
        else if(state == 2) begin
            //OM 
            addr_OM = 0;
            wen_OM = 0;
            ren_OM_inst = 0;
            ren_OM = 0;
            data_w_OM = 0;
            //DNN
            addr_DNN = command_temp[8:0];   // dia chi truy cap DNN
            if(command_temp[18:16] == 3'b001) begin
                wen_IB = bit_selector(command_temp[15:9]); wen_KSP = 0; 
                wen_BSP = 0; ren_OB = 0; wen_inst_mem = 0;
                data_w_DNN = data_r_OM;
                
            end
            else if(command_temp[18:16] == 3'b010) begin
                wen_IB = 0; wen_KSP = bit_selector(command_temp[15:9]); 
                wen_BSP = 0; ren_OB = 0; wen_inst_mem = 0;
                data_w_DNN = data_r_OM;
            end
            else if(command_temp[18:16] == 3'b011) begin
                wen_IB = 0; wen_KSP = 0; 
                wen_BSP = 1; ren_OB = 0; wen_inst_mem = 0;
                data_w_DNN = data_r_OM;
            end

            else if(command_temp[18:16] == 3'b101) begin
                wen_IB = 0; wen_KSP = 0; 
                wen_BSP = 0; ren_OB = 0; wen_inst_mem = 1;
                inst_w_DNN = inst_r_OM;
            end
        end
        
        
//xu ly voi truong hop chuyen data tu DNN sang MEM
        else if(state == 3) begin
            ren_OB = 1;
            addr_DNN = command_temp[40:32];
        end
        else if(state == 4) begin
            ren_OB = 0;
            addr_DNN = 0;
            
            addr_OM = command_temp[31:0];
            wen_OM = 1;
            data_w_OM = data_r_DNN;
        end
    end
    
    
    function [127:0] bit_selector;
        input [6:0] position; // Vị trí bit đầu vào
        begin
            bit_selector = 128'h1 << position; // Dịch bit `1` sang vị trí tương ứng
        end
    endfunction
endmodule



//
module mode_controller_2 #(
    parameter START_DNN = 6'b010101,
    parameter VSYNC = 6'b010110,
    parameter END = 6'b010111
)(
    input wire [5:0] opcode,            
    input wire clk,
    input wire rst,    
    input wire start,                       // tin hieu bat dau DSIP
    input wire vsync_in,                    // tin hieu dong bo chieu doc tu cac DSIP subsequence
    input wire DNN_done,
    output reg vsync_out,
    output reg start_DNN_core,                  // tin hieu dau ra de bat dau kich hoat cho DNN core hoat dong
    output reg end_flag,                    // tin hieu bao rang ket thuc lenh
    output reg enable_PC                    // tin hieu cho phep PC tiep tuc    - neu bang 0 thi ngung PC
);

//    reg flag_enable_PC;
    reg [3:0] state;
    

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state = 0; 
            vsync_out = 0;
            start_DNN_core = 0;
            end_flag = 0;
            enable_PC = 1;
        end
        else begin
            if(state == 0 && start == 1) begin
                state = 1;
                enable_PC = 1;  
                end_flag = 0;          
            end
            
            else if(state == 1 && opcode == VSYNC) begin
                state = 2;
                vsync_out = 1;
                enable_PC = 0;
//                end_flag = 0;  
            end
            
            else if(state == 1 && opcode == END) begin
                state = 6;
                vsync_out = 0;
                enable_PC = 1;
                end_flag = 1;
            end
            
            else if(state == 2 && vsync_in) begin
                state = 3;
                vsync_out = 0;
                enable_PC = 1;
            end
            
            else if(state == 3 && opcode == START_DNN) begin
                state = 4;
                enable_PC = 0;
                start_DNN_core = 1;
            end
            else if(state == 4) begin
                state = 5;
                start_DNN_core = 0;
            end
            else if(state == 5 && DNN_done) begin
                state = 1;
                enable_PC = 1;
                start_DNN_core = 0;
            end
            else if(state == 6) begin
                end_flag = 0;
                state = 1;
            end
        end
    end
endmodule



// đồng bộ dọc tạm thời chưa fixed
module mode_controller_3 #(
    //parameter ID = 0,
    parameter IS_FIRST_ROW = 1'b1,      // = 1 là ASIP đầu tiên của 1 hàng
    parameter IS_FIRST_COL = 1'b1       // = 1 là ASIP đầu tiên của 1 cột
)(
    input wire [5:0] opcode,   
    input wire clk,
    input wire rst,    
    input wire start,                       // tin hieu bat dau DSIP
    input wire vsync_in,                    // tin hieu dong bo chieu doc tu cac DSIP subsequence
    input wire hsync_in,                    // = AND all hsync_out signal
     
    input wire DNN_done,
    output reg vsync_out,
    output reg hsync_out,
    output reg start_DNN_core,                  // tin hieu dau ra de bat dau kich hoat cho DNN core hoat dong
    output reg enable_PC,                    // tin hieu cho phep PC tiep tuc    - neu bang 0 thi ngung PC
    output reg end_flag,                    // tin hieu bao rang ket thuc lenh

    input wire done_transfer_prev,
    output reg done_transfer
); 

    localparam SDC          = 6'b010101;
    localparam VSYNC        = 6'b010110;
    localparam END          = 6'b010111;
    localparam HSYNC        = 6'b011000;
    
    localparam IDLE = 0,
               WAIT_VSYNC = 1,
               WAIT_VSYNC_IN = 2,
               START_CORE = 3,
               WAIT_CORE_DONE = 4,
               WAIT_HSYNC = 5,
               WAIT_HSYNC_IN = 6,
               WAIT_TO_TRANSFER = 7,
               TRANSFER = 8,
               WAIT_HSYNC_END_IN = 9,
               STATE_END = 10;
                
    reg [3:0] state;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state <= IDLE;
            done_transfer <= 0;
            enable_PC <= 1;
            vsync_out <= 0;
            hsync_out <= 0;
            end_flag <= 0;
        end
        else begin
            case (state)
                IDLE: begin
                    done_transfer <= 0;
                    if(start)  state <= WAIT_VSYNC;
                    enable_PC <= 1;
                    vsync_out <= 0;
                    hsync_out = 0;
                    end_flag <= 0;
                end
                
                // Tạo tín hiệu đồng bộ dọc (vẫn sử dụng nhưng hiện tại chưa có nhiều tác dụng)
                WAIT_VSYNC: begin
                    end_flag = 0;
                    if(opcode == VSYNC) begin
                        vsync_out = 1;
                        state <= WAIT_VSYNC_IN;
                        enable_PC <= 0;
                    end
                    /* Sau khi SDC lần cuối thì MC vẫn phải hđộng để lưu dữ liệu từ OB vào OM, sau đó mới gọi HSYNC
                        Vẫn có thể gọi HSYNC trước xong rồi gộp phần lưu dữ liệu 256/256 và Transfer vào làm 1 và bỏ phần dưới
                        Nhưng nếu như vậy thì có nên lưu luôn từ OB vào OM2 không ? 
                        Ở đây tui dùng vế đầu để gần hơn với suy nghĩ của tui*/
                    else if(opcode == HSYNC) begin
                        hsync_out = 1;
                        state <= WAIT_HSYNC_IN;
                        enable_PC = 0;
                    end
                end
                
                // Chờ tín hiệu đồng bộ dọc (vẫn sử dụng nhưng hiện tại chưa có nhiều tác dụng)
                WAIT_VSYNC_IN: begin
                    if(vsync_in) begin
                        vsync_out = 0;
                        state <= START_CORE;
                        enable_PC <= 1;
                    end
                end
                
                // tạo tín hiệu cho DNN hoạt động
                START_CORE: begin
                    if(SDC) begin
                        enable_PC <= 0;
                        start_DNN_core <= 1;
                        state <= WAIT_CORE_DONE;
                    end
                end
                
                // Chờ cho DNN xử lý xong
                WAIT_CORE_DONE: begin
                    start_DNN_core <= 0;
                    if(DNN_done) begin
                        enable_PC = 1;
                        state <= WAIT_HSYNC;
                    end
                end
                
                // State này dùng để báo cho các ASIP khác rằng mình đã sẵn sàng cho quá trình Transferring data
                WAIT_HSYNC: begin
                    // Nếu không muốn cho DNN chạy nữa thì tới giai đoạn truyền data sang OM mới
                    if(opcode == HSYNC) begin
                        hsync_out = 1;
                        state <= WAIT_HSYNC_IN;
                        enable_PC = 0;
                    end
                    
                    // Nếu DNN vẫn cần xử lý tiếp thì quay về stage WAIT_VSYNC
                    else begin
                        state <= WAIT_VSYNC;
                    end
                end
                
                // Được sử dụng để đảm bảo rằng toàn bộ ASIP đã sẵn sàng cho quá trình Transferring data
                WAIT_HSYNC_IN: begin
                    if(hsync_in) begin
                        hsync_out = 0;
                        state <= WAIT_TO_TRANSFER;
                        enable_PC = 0;
                    end                    
                end
                
                // Kiểm tra điều kiện để bắt đầu truyền dữ liệu
                WAIT_TO_TRANSFER: begin
                    if(IS_FIRST_ROW || done_transfer_prev) begin
                        state <= TRANSFER;
                        enable_PC <= 1;
                    end
                end
                //stage transferring data
                TRANSFER: begin
                    // Nếu truyền xong data thì đồng bộ ngang cho các ASIP khác hoạt động
                    if(opcode == HSYNC) begin
                        hsync_out <= 1;
                        done_transfer <= 1;
                        enable_PC = 0;
                        state <= WAIT_HSYNC_END_IN;
                    end                 
                end
                
                
                // Khi toàn bộ ASIP ngang hoàn thành quá trình truyền dữ liệu
                // thì quay về IDLE 
                WAIT_HSYNC_END_IN: begin
                    if(hsync_in) begin
                        done_transfer <= 0;
                        hsync_out <= 0;
                        enable_PC <= 1;
                        state <= STATE_END;
                    end
                end
                // quay về
                STATE_END: begin
                    if(opcode == END) begin
                        state <= WAIT_VSYNC;
                        end_flag <= 1;
                        enable_PC <= 1;
                    end
                end
            endcase
        end
    end
    
endmodule





module memory_controller_2 #(
    parameter BASE_DATA_OM = 32'h00010000
)(
    input wire clk,
    input wire rst,

    // command from controller
    input wire [67:0] command_mc,
    //PORT0 ==============
    input wire [67:0] command_P0_in,
    input wire [15:0] data_P0_in,
    output reg [67:0] command_P0_out,
    output reg [15:0] data_P0_out,
    
    //PORT1
    input wire [67:0] command_P1_in,
    input wire [15:0] data_P1_in,
    output reg [67:0] command_P1_out,
    output reg [15:0] data_P1_out,
    
    
    //PORT OM
    output reg [31:0] addr_OM,
    output reg wen_OM,
    output reg ren_OM,
    input wire [15:0] data_r_OM,
    output reg [15:0] data_w_OM,
    output reg ren_OM_inst,
    input wire [211:0] inst_r_OM, 
    
    //PORT DNN core
    output reg [8:0] addr_DNN,
    output reg wen_inst_mem,
    output reg [63:0] wen_IB,
    output reg [63:0] wen_KSP,
    output reg wen_BSP,
    output reg ren_OB,
    output reg [15:0] data_w_DNN,
    input wire [15:0] data_r_DNN,
    output reg [211:0] inst_w_DNN
);
    reg [211:0] inst_r_OM_temp;
    reg [2:0] state;
    reg [67:0] command_temp;
    reg [15:0] data_temp;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state = 0;
            command_temp = 0;
            data_temp = 0;
        end
        else begin
        //state = 0 và có lệnh từ Controller (OM sang DNN)
             if(state == 0 && command_mc[67:64] == 4'b0001) begin       
                state = 1;
                command_temp = command_mc;
             end
             
             // xử lý state với trường hợp chuyển data từ OM sang DNN
             else if(state == 1) state = 2;
             else if(state == 2) begin
                state = 0;
                command_temp = 0;
             end
             
        //state = 0 và có lệnh từ Controller (DNN sang OM)
             else if(state == 0 && command_mc[67:64] == 4'b0100) begin
                state = 3;
                command_temp = command_mc;
             end
             
             // xử lý state với trường hợp chuyển data từ DNN sang OM
             else if(state == 3) state = 4;
             else if(state == 4) begin
                state = 0;
                command_temp = 0;
             end
             
        //state = 0 và có lệnh từ Controller (OM sang P0)
            else if(state == 0 && command_mc[67:64] == 4'b0010) begin
                state = 5;
                command_temp = command_mc;
            end 
            else if(state == 5) state = 6;
            else if(state == 6) begin
                state = 0;
                command_temp = 0;
            end
            
        // state = 0 và có lệnh từ P0 (P0 sang OM)
            else if(state == 0 && command_P0_in[67:64] == 4'b0010) begin
                state = 7;
                command_temp = command_P0_in;
                data_temp = data_P0_in;
            end
            else if(state == 7) state = 8;
            else if(state == 8) begin
                state = 0;
                command_temp = 0;
                data_temp = 0;
            end
        end
    end
    
    always @(*) begin
        if(state == 0) begin
            data_temp = 0;
            command_temp = 0;
        
            //PORT OM
            addr_OM = 0;
            wen_OM = 0;
            ren_OM = 0;
            data_w_OM = 0;
            ren_OM_inst = 0;
            
            //PORT DNN core
            addr_DNN = 0;
            wen_inst_mem = 0;
            wen_IB = 0;
            wen_KSP = 0;
            wen_BSP = 0;
            ren_OB = 0;
            data_w_DNN = 0;
            inst_w_DNN = 0;
//            data_read_temp = 0;

            // PORT 0
            command_P0_out = 0;
            data_P0_out = 0;
            
            // PORT 1
            command_P1_out = 0;
            data_P1_out = 0;
        end
        
//xu ly voi truong hop chuyen data tu OM sang DNN
        else if(state == 1) begin              
            //OM 
            addr_OM = command_temp[63:32];
            wen_OM = 0;
            data_w_OM = 0;
            
            if(addr_OM < BASE_DATA_OM) ren_OM_inst = 1;
            else ren_OM = 1;
            
            
        end 
        else if(state == 2) begin
            //OM 
            addr_OM = 0;
            wen_OM = 0;
            ren_OM_inst = 0;
            ren_OM = 0;
            data_w_OM = 0;
            //DNN
            addr_DNN = command_temp[8:0];   // dia chi truy cap DNN
            if(command_temp[18:16] == 3'b001) begin
                wen_IB = bit_selector(command_temp[15:9]); wen_KSP = 0; 
                wen_BSP = 0; ren_OB = 0; wen_inst_mem = 0;
                data_w_DNN = data_r_OM;
                
            end
            else if(command_temp[18:16] == 3'b010) begin
                wen_IB = 0; wen_KSP = bit_selector(command_temp[15:9]); 
                wen_BSP = 0; ren_OB = 0; wen_inst_mem = 0;
                data_w_DNN = data_r_OM;
            end
            else if(command_temp[18:16] == 3'b011) begin
                wen_IB = 0; wen_KSP = 0; 
                wen_BSP = 1; ren_OB = 0; wen_inst_mem = 0;
                data_w_DNN = data_r_OM;
            end

            else if(command_temp[18:16] == 3'b101) begin
                wen_IB = 0; wen_KSP = 0; 
                wen_BSP = 0; ren_OB = 0; wen_inst_mem = 1;
                inst_w_DNN = inst_r_OM;
            end
        end
        
        
//xu ly voi truong hop chuyen data tu DNN sang OM
        else if(state == 3) begin
            ren_OB = 1;
            addr_DNN = command_temp[40:32];
        end
        else if(state == 4) begin
            ren_OB = 0;
            addr_DNN = 0;
            addr_OM = command_temp[31:0];
            wen_OM = 1;
            data_w_OM = data_r_DNN;
        end
        
// xử lý với trường hợp chuyển data từ OM sang P0
        else if(state == 5) begin
            addr_OM = command_temp[63:32];
            ren_OM = 1;
        end
        else if(state == 6) begin
            addr_OM = 0;
            ren_OM = 0;
            command_P0_out = command_temp;
            data_P0_out = data_r_OM;
        end
        
// xử lý với trường hợp chuyển data từ Port0 sang OM
        else if(state == 7) begin
            wen_OM = 1;
            addr_OM = command_temp[31:0];
            data_w_OM = data_temp;
        end
        else if(state == 8) begin
            wen_OM = 0;
            addr_OM = 0;
            data_w_OM = 0;
        end
    end
    
    
    function [127:0] bit_selector;
        input [6:0] position; // Vị trí bit đầu vào
        begin
            bit_selector = 128'h1 << position; // Dịch bit `1` sang vị trí tương ứng
        end
    endfunction
endmodule
