`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/06/2024 05:05:17 PM
// Design Name: 
// Module Name: LI
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


module LI #(
    parameter DATA_WIDTH = 16,
    parameter DECIMAL_BIT = 8   // Defines fractional bits in fixed-point format
)(
    input signed [DATA_WIDTH - 1:0] x, // Renamed input from `x` to `data_in`
    input signed [DATA_WIDTH - 1:0] x1,      // Known point X1 from LUT
    input signed [DATA_WIDTH - 1:0] y1,      // Known point Y1 from LUT
    input signed [DATA_WIDTH - 1:0] x2,      // Known point X2 from LUT
    input signed [DATA_WIDTH - 1:0] y2,      // Known point Y2 from LUT
    output reg signed [DATA_WIDTH - 1:0] y        // Interpolated Y output
);
    reg signed [DATA_WIDTH - 1:0] slope;
    reg signed [2*DATA_WIDTH - 1:0] intercept;
    reg signed [2*DATA_WIDTH - 1:0] y_intermediate; // Q8.16 format for intermediate y calculation
    reg signed [2*DATA_WIDTH - 1:0] dy;
    reg signed [DATA_WIDTH - 1:0] dx;

    always @(*) begin
        if (x2 != x1) begin
            dy = y2 - y1;
            dx = x2 - x1;
            slope = (dy << DECIMAL_BIT) / dx;            
            intercept = (y1 << DECIMAL_BIT) - (slope * x1);
            y_intermediate = slope * x + intercept;
            y = y_intermediate[DATA_WIDTH + DECIMAL_BIT - 1:DECIMAL_BIT];
        end 
    end
endmodule

