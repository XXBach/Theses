`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/28/2025 08:39:48 AM
// Design Name: 
// Module Name: register_file
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


module register_file #(
    parameter SIZE = 32,
    parameter DATA_WIDTH = 32
)(
    input wire clk,
    input wire rst,
    input wire [4:0] RA,        // addr read RA
    input wire [4:0] RB,        // addr read RB
    input wire [4:0] RD_r,      // addr read RD
    input wire [4:0] Rtemp,
    input wire [4:0] RD_w,      // addr write RD
    input wire wen,
    input wire [DATA_WIDTH-1:0] w_data,
    output wire [DATA_WIDTH-1:0] r_data_RA,
    output wire [DATA_WIDTH-1:0] r_data_RB,
    output wire [DATA_WIDTH-1:0] r_data_RD,
    output wire [DATA_WIDTH-1:0] r_data_Rtemp

    );
    
    reg [DATA_WIDTH - 1 : 0] mem [SIZE - 1 : 0];
    integer i;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            for(i = 0; i < SIZE; i = i + 1) mem[i] <= 0;
        end
        else begin
            
            if(wen)
                if(RD_w != 0)
                    mem[RD_w] <= w_data;
        end
    end
    assign r_data_RA = mem[RA];
    assign r_data_RB = mem[RB];
    assign r_data_RD = mem[RD_r];
    assign r_data_Rtemp = mem[Rtemp];

endmodule
