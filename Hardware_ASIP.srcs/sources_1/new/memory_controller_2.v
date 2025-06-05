`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/28/2025 08:48:43 AM
// Design Name: 
// Module Name: memory_controller_2
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


module memory_controller_2 #(
    parameter BASE_DATA_OM = 32'h00010000
)(
    input wire clk,
    input wire rst,

    // command from controller
    input wire [67:0] command_mc,
    //PORT0 ==============
    input wire [67:0] command_P0_in,
    input wire [15:0] data_P0_in,
    output reg [67:0] command_P0_out,
    output reg [15:0] data_P0_out,
    
    //PORT1
    input wire [67:0] command_P1_in,
    input wire [15:0] data_P1_in,
    output reg [67:0] command_P1_out,
    output reg [15:0] data_P1_out,
    
    
    //PORT OM
    output reg [31:0] addr_OM,
    output reg wen_OM,
    output reg ren_OM,
    input wire [15:0] data_r_OM,
    output reg [15:0] data_w_OM,
    output reg ren_OM_inst,
    input wire [211:0] inst_r_OM, 
    
    //PORT DNN core
    output reg [8:0] addr_DNN,
    output reg wen_inst_mem,
    output reg [63:0] wen_IB,
    output reg [63:0] wen_KSP,
    output reg wen_BSP,
    output reg ren_OB,
    output reg [15:0] data_w_DNN,
    input wire [15:0] data_r_DNN,
    output reg [211:0] inst_w_DNN
);
    reg [211:0] inst_r_OM_temp;
    reg [2:0] state;
    reg [67:0] command_temp;
    reg [15:0] data_temp;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state = 0;
            command_temp = 0;
            data_temp = 0;
        end
        else begin
        //state = 0 và có lệnh từ Controller (OM sang DNN)
             if(state == 0 && command_mc[67:64] == 4'b0001) begin       
                state = 1;
                command_temp = command_mc;
             end
             
             // xử lý state với trường hợp chuyển data từ OM sang DNN
             else if(state == 1) state = 2;
             else if(state == 2) begin
                state = 0;
                command_temp = 0;
             end
             
        //state = 0 và có lệnh từ Controller (DNN sang OM)
             else if(state == 0 && command_mc[67:64] == 4'b0100) begin
                state = 3;
                command_temp = command_mc;
             end
             
             // xử lý state với trường hợp chuyển data từ DNN sang OM
             else if(state == 3) state = 4;
             else if(state == 4) begin
                state = 0;
                command_temp = 0;
             end
             
        //state = 0 và có lệnh từ Controller (OM sang P0)
            else if(state == 0 && command_mc[67:64] == 4'b0010) begin
                state = 5;
                command_temp = command_mc;
            end 
            else if(state == 5) state = 6;
            else if(state == 6) begin
                state = 0;
                command_temp = 0;
            end
            
        // state = 0 và có lệnh từ P0 (P0 sang OM)
            else if(state == 0 && command_P0_in[67:64] == 4'b0010) begin
                state = 7;
                command_temp = command_P0_in;
                data_temp = data_P0_in;
            end
            else if(state == 7) state = 8;
            else if(state == 8) begin
                state = 0;
                command_temp = 0;
                data_temp = 0;
            end
        end
    end
    
    always @(*) begin
        if(state == 0) begin
            data_temp = 0;
            command_temp = 0;
        
            //PORT OM
            addr_OM = 0;
            wen_OM = 0;
            ren_OM = 0;
            data_w_OM = 0;
            ren_OM_inst = 0;
            
            //PORT DNN core
            addr_DNN = 0;
            wen_inst_mem = 0;
            wen_IB = 0;
            wen_KSP = 0;
            wen_BSP = 0;
            ren_OB = 0;
            data_w_DNN = 0;
            inst_w_DNN = 0;
//            data_read_temp = 0;

            // PORT 0
            command_P0_out = 0;
            data_P0_out = 0;
            
            // PORT 1
            command_P1_out = 0;
            data_P1_out = 0;
        end
        
//xu ly voi truong hop chuyen data tu OM sang DNN
        else if(state == 1) begin              
            //OM 
            addr_OM = command_temp[63:32];
            wen_OM = 0;
            data_w_OM = 0;
            
            if(addr_OM < BASE_DATA_OM) ren_OM_inst = 1;
            else ren_OM = 1;
            
            
        end 
        else if(state == 2) begin
            //OM 
            addr_OM = 0;
            wen_OM = 0;
            ren_OM_inst = 0;
            ren_OM = 0;
            data_w_OM = 0;
            //DNN
            addr_DNN = command_temp[8:0];   // dia chi truy cap DNN
            if(command_temp[18:16] == 3'b001) begin
                wen_IB = bit_selector(command_temp[15:9]); wen_KSP = 0; 
                wen_BSP = 0; ren_OB = 0; wen_inst_mem = 0;
                data_w_DNN = data_r_OM;
                
            end
            else if(command_temp[18:16] == 3'b010) begin
                wen_IB = 0; wen_KSP = bit_selector(command_temp[15:9]); 
                wen_BSP = 0; ren_OB = 0; wen_inst_mem = 0;
                data_w_DNN = data_r_OM;
            end
            else if(command_temp[18:16] == 3'b011) begin
                wen_IB = 0; wen_KSP = 0; 
                wen_BSP = 1; ren_OB = 0; wen_inst_mem = 0;
                data_w_DNN = data_r_OM;
            end

            else if(command_temp[18:16] == 3'b101) begin
                wen_IB = 0; wen_KSP = 0; 
                wen_BSP = 0; ren_OB = 0; wen_inst_mem = 1;
                inst_w_DNN = inst_r_OM;
            end
        end
        
        
//xu ly voi truong hop chuyen data tu DNN sang OM
        else if(state == 3) begin
            ren_OB = 1;
            addr_DNN = command_temp[40:32];
        end
        else if(state == 4) begin
            ren_OB = 0;
            addr_DNN = 0;
            addr_OM = command_temp[31:0];
            wen_OM = 1;
            data_w_OM = data_r_DNN;
        end
        
// xử lý với trường hợp chuyển data từ OM sang P0
        else if(state == 5) begin
            addr_OM = command_temp[63:32];
            ren_OM = 1;
        end
        else if(state == 6) begin
            addr_OM = 0;
            ren_OM = 0;
            command_P0_out = command_temp;
            data_P0_out = data_r_OM;
        end
        
// xử lý với trường hợp chuyển data từ Port0 sang OM
        else if(state == 7) begin
            wen_OM = 1;
            addr_OM = command_temp[31:0];
            data_w_OM = data_temp;
        end
        else if(state == 8) begin
            wen_OM = 0;
            addr_OM = 0;
            data_w_OM = 0;
        end
    end
    
    
    function [127:0] bit_selector;
        input [6:0] position; // Vị trí bit đầu vào
        begin
            bit_selector = 128'h1 << position; // Dịch bit `1` sang vị trí tương ứng
        end
    endfunction
endmodule
