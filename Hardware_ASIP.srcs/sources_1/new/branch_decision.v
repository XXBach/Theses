`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/28/2025 08:42:38 AM
// Design Name: 
// Module Name: branch_decision
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
