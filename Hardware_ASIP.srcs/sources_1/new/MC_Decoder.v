`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/28/2025 08:38:27 AM
// Design Name: 
// Module Name: MC_decoder
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
