`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/21/2024 04:18:22 PM
// Design Name: 
// Module Name: test1
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


module test1_tb;
    bit clk;
    bit rst;
    bit wen;
    bit [15:0] data_in;
    wire [15:0] data_out;
    
    always #2 clk = !clk;
    
    initial begin
        rst = 1;
        #400
        rst = 0;
        wen = 1;
        data_in = 5;
    end
    
    test1 t(clk, rst, wen, data_in, data_out);
endmodule
