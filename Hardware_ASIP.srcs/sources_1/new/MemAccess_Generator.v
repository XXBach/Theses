`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/28/2025 08:47:25 AM
// Design Name: 
// Module Name: MemAccess_Generator
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
