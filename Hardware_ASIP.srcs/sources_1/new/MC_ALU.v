`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/28/2025 08:45:20 AM
// Design Name: 
// Module Name: MC_ALU
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

