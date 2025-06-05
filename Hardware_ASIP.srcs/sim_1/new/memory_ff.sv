`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/03/2024 04:24:50 PM
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


module memory_ff_tb;


    parameter DATA_WIDTH = 16;
    parameter SIZE = 256;

    bit clk;
    bit rst;
    bit wen;                  // Tín hiệu ghi
    bit ren;                  // Tín hiệu đọc
    bit [$clog2(SIZE)-1:0] addr_w;         // Địa chỉ ghi
    bit [$clog2(SIZE)-1:0] addr_r;         // Địa chỉ đọc
    bit [DATA_WIDTH - 1:0] din;            // Dữ liệu đầu vào
    wire [DATA_WIDTH - 1:0] dout_ff;            // Dữ liệu đầu ra

    initial begin
        rst = 1;
        #120
        rst = 0;
        
        // write
        ren = 0; wen = 1; addr_w = 2; din = 5;
        #4
        ren = 0; wen = 1; addr_w = 3; din = 20;
        #4
        ren = 0; wen = 1; addr_w = 5; din = 99;
        // read
        #4
        ren = 1; wen = 0; addr_r = 2;
        #4
        ren = 1; wen = 0; addr_r = 3;
        #4
        ren = 1; wen = 0; addr_r = 5;
        
        // write and read
        #4
        ren = 1; wen = 1; addr_w = 10; addr_r = 2; din = 200;
        #4
        ren = 1; wen = 1; addr_w = 20; addr_r = 10; din = 100;
        #4
        ren = 1; wen = 1; addr_w = 30; addr_r = 30; din = 450;
        #4
        ren = 1; wen = 1; addr_w = 50; addr_r = 20; din = 1;
        #4
        ren = 1; wen = 1; addr_w = 51; addr_r = 30; din = 9;
    end
    
always #2 clk = ~clk;
    
    
    memory_ff memo(.clk(clk),
               .rst(rst),
               .wen(wen),
               .ren(ren),
               .addr_w(addr_w),
               .addr_r(addr_r),
               .din(din),
               .dout_ff(dout_ff));
endmodule



