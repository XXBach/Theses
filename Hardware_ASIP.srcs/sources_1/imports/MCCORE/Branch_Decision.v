`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/02/2024 10:18:56 AM
// Design Name: 
// Module Name: Branch_Decision
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


module Branch_Decision#(
    parameter WIDTH = 32
)(
    input wire is_0,
    input wire is_br,
    input wire is_cbr,
    input wire [WIDTH-1:0] BRTG,
    input wire [WIDTH-1:0] CBRTG,
    output wire BRS,
    output wire [WIDTH-1:0] BRA
    );
    wire w0,w1,w2;
    wire [WIDTH-1:0] temp_BRA;
    and(w0,is_0,is_cbr);
    or(BRS,w0,is_br);
//    not(w1,is_cbr);
//    and(w2,w1,is_br);
    Mux2 m0 (CBRTG,BRTG,is_br,temp_BRA);
    Tristate ts0 (temp_BRA,BRS,BRA);
endmodule
