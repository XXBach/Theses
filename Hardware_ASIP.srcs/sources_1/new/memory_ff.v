`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/03/2024 04:24:37 PM
// Design Name: 
// Module Name: memory_ff
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



    
module memory_ff#(
    parameter DATA_WIDTH = 16,
    parameter SIZE = 256
)(
    input wire clk,
    input wire rst,
    input wire wen,                  // Tín hiệu ghi
    input wire ren,                  // Tín hiệu đọc
    input wire [$clog2(SIZE)-1:0] addr_w,         // Địa chỉ ghi
    input wire [$clog2(SIZE)-1:0] addr_r,         // Địa chỉ đọc
    input wire [DATA_WIDTH - 1:0] din,            // Dữ liệu đầu vào
    output reg [DATA_WIDTH - 1:0] dout_ff            // Dữ liệu đầu ra
);
    wire [DATA_WIDTH - 1:0] mem_out;
    memory mem(.clk(clk),
           .rst(rst),
           .wen(wen),
           .ren(ren),
           .addr_w(addr_w),
           .addr_r(addr_r),
           .din(din),
           .dout(mem_out));
    
    always @(posedge clk or posedge rst) begin
        if(rst) dout_ff<= 0;
        else dout_ff <= mem_out;
    end
endmodule
