`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2024 04:03:34 PM
// Design Name: 
// Module Name: look_up_table_tb
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


module look_up_table_tb #(
    parameter DATA_WIDTH = 16,                              // DATA WIDTH
    parameter DECIMAL_BITS = 8                              // Defines fractional bits in fixed-point format
);
    bit clk;
    bit rst;
    bit [DATA_WIDTH - 1 : 0] data_in;
    wire [DATA_WIDTH*2 - 1 : 0] coordinate_0; 
    wire [DATA_WIDTH*2 - 1 : 0] coordinate_1; 
    wire [DATA_WIDTH - 1 : 0] data_out;
    
    
    initial begin
    rst = 0;
    // RESET
    #10
    rst = 1;
    #100
    rst = 0;
    #50
    data_in = 4;
    #50
    data_in = 15;
    #50
    data_in = 33;
    #50
    data_in = 41;
    #50
    data_in = 100;
    #50
    data_in = 7;
    #50
    data_in = 16;
    #50
    data_in = 28;
    #50
    data_in = 38;
    #50
    data_in = 45;
    #50
    data_in = 57;
    #100
    $finish;
    end
    
    always #5 clk = ~clk;
    
    lookuptable_module #(.DATA_WIDTH(DATA_WIDTH),
                        .DECIMAL_BITS(DECIMAL_BITS)
                        ) lut
                        (.clk(clk),
                        .rst(rst),
                        .data_in(data_in),
                        .coordinate_0(coordinate_0),
                        .coordinate_1(coordinate_1),
                        .data_out(data_out));
endmodule
