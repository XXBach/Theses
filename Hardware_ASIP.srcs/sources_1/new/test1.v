`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/21/2024 04:18:12 PM
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


module test1#(
    parameter DATA_WIDTH = 16,
    parameter DECIMAL_BIT = 8
)(
    input clk,
    input rst,
    input wire [1:0] mult_sel_1,                    // SELECT AMONG 0, MLIout AND MLOout
    input wire mult_sel_2,                          // SELECT BETWEEN 1 AND MLKout
    input wire [1:0] acc_sel,                       // SELECT AMONG 0, MLOout, EOAout, SEOAout
    input wire [DATA_WIDTH-1:0] MLIout,             // 16-bit fixed-point INPUT
    input wire [DATA_WIDTH-1:0] MLIout_all,         // 16-bit fixed-point INPUT
    input wire [DATA_WIDTH-1:0] MLKout,             // 16-bit fixed-point INPUT
    input wire [DATA_WIDTH-1:0] MLOout,             // 16-bit fixed-point INPUT
    input wire [DATA_WIDTH-1:0] EOAout,             // 16-bit fixed-point INPUT
    input wire [DATA_WIDTH-1:0] SEOAout,            // 16-bit fixed-point INPUT
//    output reg [DATA_WIDTH-1:0] acc_result          // 16-bit fixed-point INPUT
    output reg [DATA_WIDTH-1:0] data_out
    );
    
    reg [1:0] mult_sel_1_reg;                   
    reg mult_sel_2_reg;                          
    reg [1:0] acc_sel_reg;                      
    reg [DATA_WIDTH-1:0] MLIout_reg;             
    reg [DATA_WIDTH-1:0] MLIout_all_reg;         
    reg [DATA_WIDTH-1:0] MLKout_reg;             
    reg [DATA_WIDTH-1:0] MLOout_reg;             
    reg [DATA_WIDTH-1:0] EOAout_reg;             
    reg [DATA_WIDTH-1:0] SEOAout_reg;            
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            mult_sel_1_reg = 0;                   
            mult_sel_2_reg = 0;                          
            acc_sel_reg = 0;                      
            MLIout_reg = 0;             
            MLIout_all_reg = 0;         
            MLKout_reg = 0;             
            MLOout_reg = 0;             
            EOAout_reg = 0;             
            SEOAout_reg = 0;            
        end
        else begin
            mult_sel_1_reg = mult_sel_1;                   
            mult_sel_2_reg = mult_sel_2;                          
            acc_sel_reg = acc_sel;                      
            MLIout_reg = MLIout;             
            MLIout_all_reg = MLIout_all;         
            MLKout_reg = MLKout;             
            MLOout_reg = MLOout;             
            EOAout_reg = EOAout;             
            SEOAout_reg = SEOAout;       
        end
    end
    
    reg [DATA_WIDTH-1:0] mult_operand_1, mult_operand_2;
    reg [DATA_WIDTH*2-1:0] mult_result; // STORE RESULT OF MULTIPLICATION
    reg [DATA_WIDTH-1:0] acc_temp;      // STORE TEMP RESULT OF ADDITION
    reg [DATA_WIDTH-1:0] acc_result;
    always @(*) begin
            // SELECT OPERAND 1 FOR MULTIPLICATION
            case (mult_sel_1_reg)
                2'b00: mult_operand_1 = 16'b0;              // 0
                2'b01: mult_operand_1 = MLIout_reg;             // MLIout
                2'b10: mult_operand_1 = data_out;         // MLOout from port 0
                default: mult_operand_1 = 16'b0;           
            endcase

            // SELECT OPERAND 2 FOR MULTIPLICATION
            case (mult_sel_2_reg)
                1'b0: mult_operand_2 = 16'b1;               // 1
                1'b1: mult_operand_2 = MLKout_reg;              // MLIout
            endcase
            
            // MULTIPLICATION
            mult_result = mult_operand_1 * mult_operand_2;

            // SCALE THE RESULT BACK TO fixed-point (Q8.8)
            mult_result = mult_result >> DECIMAL_BIT; // SCALE (shift right)

            // SELECT OPERAND FOR THE ACC BLOCK AND ADD THE ACCUMULATION WITH THE RESULT FROM MULTIPLICATION
            case (acc_sel_reg)
                2'b00: acc_temp = mult_result[15:0];                // JUST RESULT FROM MULTIPICATION
                2'b01: acc_temp = MLOout_reg + mult_result[15:0];       // ADD MLIout
                2'b10: acc_temp = EOAout_reg + mult_result[15:0];       // ADD EOAout
                2'b11: acc_temp = SEOAout_reg + mult_result[15:0];      // ADD SEOAout
//                default: acc_temp = 16'b0; // mặc định là 0
            endcase
            // ASSIGN FINAL RESULT
            acc_result = acc_temp;
    end
    
    always @(posedge clk or posedge rst) begin
        if(rst) data_out = 0;
        else data_out = acc_result;
    end
endmodule
