`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/28/2025 08:44:10 AM
// Design Name: 
// Module Name: control_forward
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
