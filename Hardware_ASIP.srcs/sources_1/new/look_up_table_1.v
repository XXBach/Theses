//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Company: 
//// Engineer: 
//// 
//// Create Date: 01/16/2025 08:59:53 PM
//// Design Name: 
//// Module Name: look_up_table_1
//// Project Name: 
//// Target Devices: 
//// Tool Versions: 
//// Description: 
//// 
//// Dependencies: 
//// 
//// Revision:
//// Revision 0.01 - File Created
//// Additional Comments:
//// 
////////////////////////////////////////////////////////////////////////////////////


//module lookuptable_module_1 #(
//    parameter DATA_WIDTH = 16                              // DATA WIDTH
//)(
//    // INPUT
//    input wire clk,
//    input wire rst,
//    input wire [DATA_WIDTH - 1 : 0] data_in,
    
//    // OUTPUT
//    output reg [DATA_WIDTH*2 - 1 : 0] coordinate_0,         // Coordinate of point 0
//    output reg [DATA_WIDTH*2 - 1 : 0] coordinate_1,         // Coordinate of point 1
//    output reg [DATA_WIDTH - 1 : 0] data_out                // = data_in after being latched
//    );
    
//    // Registers store values
//    reg [DATA_WIDTH*2 - 1 : 0] data0;
//    reg [DATA_WIDTH*2 - 1 : 0] data1;
//    reg [DATA_WIDTH*2 - 1 : 0] data2;
//    reg [DATA_WIDTH*2 - 1 : 0] data3;
//    reg [DATA_WIDTH*2 - 1 : 0] data4;

    
//    initial begin
//        data0 = 32'h00008CE1;       
//        data1 = 32'h001C9580;       
//        data2 = 32'h007442D0;       
//        data3 = 32'h02315314;       
//        data4 = 32'h1AD212C3;       
//    end
    
//    // Compare input and values stored in register 0 --> 4
//    wire [3:0] cmp_result;
    
//    compare c0(.value0(data0[DATA_WIDTH * 2 - 1: DATA_WIDTH]), .value1(data1[DATA_WIDTH * 2 - 1: DATA_WIDTH]), .value_input(data_in), .cmp_result(cmp_result[0]));
//    compare c1(.value0(data1[DATA_WIDTH * 2 - 1: DATA_WIDTH]), .value1(data2[DATA_WIDTH * 2 - 1: DATA_WIDTH]), .value_input(data_in), .cmp_result(cmp_result[1]));
//    compare c2(.value0(data2[DATA_WIDTH * 2 - 1: DATA_WIDTH]), .value1(data3[DATA_WIDTH * 2 - 1: DATA_WIDTH]), .value_input(data_in), .cmp_result(cmp_result[2]));
//    compare c3(.value0(data3[DATA_WIDTH * 2 - 1: DATA_WIDTH]), .value1(data4[DATA_WIDTH * 2 - 1: DATA_WIDTH]), .value_input(data_in), .cmp_result(cmp_result[3]));

//    // Drive compare result to Control Tri-state block
//    wire [1:0] signal;
//    control_tristate ctr_tri(.cmp_result(cmp_result), .signal(signal));
    
//    // Using signal from output of control tri-state block to control 2 mux
//    reg [DATA_WIDTH*2 - 1 : 0] out0;
//    reg [DATA_WIDTH*2 - 1 : 0] out1;

//    always @(*) begin
//        if(signal == 2'b00) begin
//            out0 = data0;
//            out1 = data1;
//        end
//        else if(signal == 2'b01) begin
//            out0 = data1;
//            out1 = data2;
//        end
//        else if(signal == 2'b10) begin
//            out0 = data2;
//            out1 = data3;
//        end
//        else if(signal == 2'b11) begin
//            out0 = data3;
//            out1 = data4;
//        end
//        else begin
//            out0 = 'bz;
//            out1 = 'bz;
//        end
//    end
    
//    // latch the input value
//    always @(posedge clk or posedge rst) begin
//        if(rst) begin
//            data_out <= 0;
//            coordinate_0 <= 0;
//            coordinate_1 <= 0;
//        end
//        else begin
//            data_out <= data_in;
//            coordinate_0 <= out0;
//            coordinate_1 <= out1;
//        end
//    end
    
//endmodule

//// Compare block
//module compare #(
//    DATA_WIDTH = 16
//)(
//    input wire [DATA_WIDTH - 1 : 0] value0,             // Value stored in register
//    input wire [DATA_WIDTH - 1 : 0] value1,             // Value stored in register
//    input wire [DATA_WIDTH - 1 : 0] value_input,        // Value input users want to compare
//    output reg cmp_result
//);
//    always @(*) begin
//        if(value_input >= value0 && value_input <= value1) cmp_result = 1;
//        else cmp_result = 0;
//    end
//endmodule

//// Control tri-state block  - Create signal control mux from compare result
//module control_tristate(
//    input wire [3:0] cmp_result,
//    output reg [1:0] signal
//);
//    always @(*) begin
//        if(cmp_result == 4'b0001) signal = 2'b00;
//        else if(cmp_result == 4'b0010) signal = 2'b01;
//        else if(cmp_result == 4'b0100) signal = 2'b10;
//        else if(cmp_result == 4'b1000) signal = 2'b11;
//        else signal = 2'bzz;
//    end
//endmodule




`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2024 03:45:56 PM
// Design Name: 
// Module Name: look_up_table
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


module lookuptable_module_1 #(
    parameter DATA_WIDTH = 16                              // DATA WIDTH
)(
    // INPUT
    input wire clk,
    input wire rst,
    input wire [DATA_WIDTH - 1 : 0] data_in,
    
    // OUTPUT
    output reg [DATA_WIDTH*2 - 1 : 0] coordinate_0,         // Coordinate of point 0
    output reg [DATA_WIDTH*2 - 1 : 0] coordinate_1,         // Coordinate of point 1
    output reg [DATA_WIDTH - 1 : 0] data_out                // = data_in after being latched
    );
    
    // Registers store values
    reg [DATA_WIDTH*2 - 1 : 0] data0;
    reg [DATA_WIDTH*2 - 1 : 0] data1;
    reg [DATA_WIDTH*2 - 1 : 0] data2;
    reg [DATA_WIDTH*2 - 1 : 0] data3;
    reg [DATA_WIDTH*2 - 1 : 0] data4;

    
    initial begin
        data0 = 32'hFFFF0000;       
        data1 = 32'h80000000;       
        data2 = 32'h00000020;       
        data3 = 32'h30000060;       
        data4 = 32'h7FFF0100;       
    end
   
    always @(posedge clk or posedge rst) begin
        if(rst) begin
        coordinate_0 = 0;         // Coordinate of point 0
        coordinate_1 = 0;         // Coordinate of point 1
        data_out = 0; 
        end
        else begin
            if($signed(data0[31:16]) <= $signed(data_in) && $signed(data_in) <= $signed(data1[31:16])) begin
                coordinate_0 = data0;
                coordinate_1 = data1;
                data_out = data_in;
            end 
            
            else if($signed(data1[31:16]) <= $signed(data_in) && $signed(data_in) <= $signed(data2[31:16])) begin
                coordinate_0 = data1;
                coordinate_1 = data2;
                data_out = data_in;
            end 
            
            else if($signed(data2[31:16]) <= $signed(data_in) && $signed(data_in) <= $signed(data3[31:16])) begin
                coordinate_0 = data2;
                coordinate_1 = data3;
                data_out = data_in;
            end 
            else if($signed(data3[31:16]) <= $signed(data_in) && $signed(data_in) <= $signed(data4[31:16])) begin
                coordinate_0 = data3;
                coordinate_1 = data4;
                data_out = data_in;
            end 

        end
    end
    
endmodule
