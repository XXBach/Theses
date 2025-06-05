`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/28/2025 08:54:07 AM
// Design Name: 
// Module Name: mode_controller_2
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


module mode_controller_2 #(
    parameter START_DNN = 6'b010101,
    parameter VSYNC = 6'b010110,
    parameter END = 6'b010111
)(
    input wire [5:0] opcode,            
    input wire clk,
    input wire rst,    
    input wire start,                       // tin hieu bat dau DSIP
    input wire vsync_in,                    // tin hieu dong bo chieu doc tu cac DSIP subsequence
    input wire DNN_done,
    output reg vsync_out,
    output reg start_DNN_core,                  // tin hieu dau ra de bat dau kich hoat cho DNN core hoat dong
    output reg end_flag,                    // tin hieu bao rang ket thuc lenh
    output reg enable_PC                    // tin hieu cho phep PC tiep tuc    - neu bang 0 thi ngung PC
);

//    reg flag_enable_PC;
    reg [3:0] state;
    

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state = 0; 
            vsync_out = 0;
            start_DNN_core = 0;
            end_flag = 0;
            enable_PC = 1;
        end
        else begin
            if(state == 0 && start == 1) begin
                state = 1;
                enable_PC = 1;  
                end_flag = 0;          
            end
            
            else if(state == 1 && opcode == VSYNC) begin
                state = 2;
                vsync_out = 1;
                enable_PC = 0;
//                end_flag = 0;  
            end
            
            else if(state == 1 && opcode == END) begin
                state = 6;
                vsync_out = 0;
                enable_PC = 1;
                end_flag = 1;
            end
            
            else if(state == 2 && vsync_in) begin
                state = 3;
                vsync_out = 0;
                enable_PC = 1;
            end
            
            else if(state == 3 && opcode == START_DNN) begin
                state = 4;
                enable_PC = 0;
                start_DNN_core = 1;
            end
            else if(state == 4) begin
                state = 5;
                start_DNN_core = 0;
            end
            else if(state == 5 && DNN_done) begin
                state = 1;
                enable_PC = 1;
                start_DNN_core = 0;
            end
            else if(state == 6) begin
                end_flag = 0;
                state = 1;
            end
        end
    end
endmodule
