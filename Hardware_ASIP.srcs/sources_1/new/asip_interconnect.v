`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/24/2025 10:41:02 PM
// Design Name: 
// Module Name: asip_interconnect
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


module asip_interconnect(
    input wire clk,
    input wire rst,
    
    // Write-read port 0
    input wire [31:0] addr_w_0,
    input wire [31:0] addr_r_0,
    input wire [31:0] data_0,
    input wire wen_0,
    input wire ren_0,
    
    
    
    
    // Write-read port 0
    output wire [31:0] addr_w_o,
    output wire [31:0] addr_r_o,
    output wire [31:0] data_o,
    output wire [211:0] inst_o,
    output wire wen_o,
    output wire ren_o
    );
    
    
endmodule
