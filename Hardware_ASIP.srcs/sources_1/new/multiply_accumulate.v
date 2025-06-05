//`timescale 1ns / 1ps

//module multiply_accumulate #(
//    parameter DATA_WIDTH = 16,                      // DECLARE DATA_WIDTH
//    parameter DECIMAL_BIT = 8                       // DECLARE NUMBER OF BITS DECIMAL PART
//)(
//    input wire [1:0] mult_sel_1,                    // SELECT AMONG 0, MLIout AND MLOout
//    input wire mult_sel_2,                          // SELECT BETWEEN 1 AND MLKout
//    input wire [1:0] acc_sel,                       // SELECT AMONG 0, MLOout, EOAout, SEOAout
//    input wire [DATA_WIDTH-1:0] MLIout,             // 16-bit fixed-point INPUT
//    input wire [DATA_WIDTH-1:0] MLIout_all,         // 16-bit fixed-point INPUT
//    input wire [DATA_WIDTH-1:0] MLKout,             // 16-bit fixed-point INPUT
//    input wire [DATA_WIDTH-1:0] MLOout,             // 16-bit fixed-point INPUT
//    input wire [DATA_WIDTH-1:0] EOAout,             // 16-bit fixed-point INPUT
//    input wire [DATA_WIDTH-1:0] SEOAout,            // 16-bit fixed-point INPUT
//    output reg [DATA_WIDTH-1:0] acc_result          // 16-bit fixed-point INPUT
//);

//    reg [DATA_WIDTH-1:0] mult_operand_1, mult_operand_2;
//    reg [DATA_WIDTH*2-1:0] mult_result; // STORE RESULT OF MULTIPLICATION
//    reg [DATA_WIDTH-1:0] acc_temp;      // STORE TEMP RESULT OF ADDITION

//    always @(*) begin
//            // SELECT OPERAND 1 FOR MULTIPLICATION
//            case (mult_sel_1)
//                2'b00: mult_operand_1 = 16'b0;              // 0
//                2'b01: mult_operand_1 = MLIout;             // MLIout
//                2'b10: mult_operand_1 = MLIout_all;         // MLOout from port 0
//                default: mult_operand_1 = 16'b0;           
//            endcase

//            // SELECT OPERAND 2 FOR MULTIPLICATION
//            case (mult_sel_2)
//                1'b0: mult_operand_2 = 16'b1;               // 1
//                1'b1: mult_operand_2 = MLKout;              // MLIout
//            endcase
            
//            // MULTIPLICATION
//            mult_result = mult_operand_1 * mult_operand_2;

//            // SCALE THE RESULT BACK TO fixed-point (Q8.8)
//            mult_result = mult_result >> DECIMAL_BIT; // SCALE (shift right)

//            // SELECT OPERAND FOR THE ACC BLOCK AND ADD THE ACCUMULATION WITH THE RESULT FROM MULTIPLICATION
//            case (acc_sel)
//                2'b00: acc_temp = mult_result[15:0];                // JUST RESULT FROM MULTIPICATION
//                2'b01: acc_temp = MLOout + mult_result[15:0];       // ADD MLIout
//                2'b10: acc_temp = EOAout + mult_result[15:0];       // ADD EOAout
//                2'b11: acc_temp = SEOAout + mult_result[15:0];      // ADD SEOAout
////                default: acc_temp = 16'b0; // mặc định là 0
//            endcase
//            // ASSIGN FINAL RESULT
//            acc_result = acc_temp;
//    end
//endmodule


`timescale 1ns / 1ps

module multiply_accumulate #(
    parameter DATA_WIDTH = 16,                      // DECLARE DATA_WIDTH
    parameter DECIMAL_BIT = 8                       // DECLARE NUMBER OF BITS DECIMAL PART
)(
    input signed [1:0] mult_sel_1,                    // SELECT AMONG 0, MLIout AND MLOout
    input signed mult_sel_2,                          // SELECT BETWEEN 1 AND MLKout
    input signed [1:0] acc_sel,                       // SELECT AMONG 0, MLOout, EOAout, SEOAout
    input signed [DATA_WIDTH-1:0] MLIout,             // 16-bit fixed-point INPUT
    input signed [DATA_WIDTH-1:0] MLIout_all,         // 16-bit fixed-point INPUT
    input signed [DATA_WIDTH-1:0] MLKout,             // 16-bit fixed-point INPUT
    input signed [DATA_WIDTH-1:0] MLOout,             // 16-bit fixed-point INPUT
    input signed [DATA_WIDTH-1:0] EOAout,             // 16-bit fixed-point INPUT
    input signed [DATA_WIDTH-1:0] SEOAout,            // 16-bit fixed-point INPUT
    output reg signed [DATA_WIDTH-1:0] acc_result          // 16-bit fixed-point INPUT
);

    reg signed [DATA_WIDTH-1:0] mult_operand_1, mult_operand_2;
    reg signed [DATA_WIDTH*2-1:0] mult_result; // STORE RESULT OF MULTIPLICATION
    reg signed [DATA_WIDTH-1:0] acc_temp;      // STORE TEMP RESULT OF ADDITION

    always @(*) begin
            // SELECT OPERAND 1 FOR MULTIPLICATION
            case (mult_sel_1)
                2'b00: mult_operand_1 = 16'b0;              // 0
                2'b01: mult_operand_1 = MLIout;             // MLIout
                2'b10: mult_operand_1 = MLIout_all;         // MLOout from port 0
                default: mult_operand_1 = 16'b0;           
            endcase

            // SELECT OPERAND 2 FOR MULTIPLICATION
            case (mult_sel_2)
                1'b0: mult_operand_2 = 16'b1;               // 1
                1'b1: mult_operand_2 = MLKout;              // MLIout
            endcase
            
            // MULTIPLICATION
            mult_result = mult_operand_1 * mult_operand_2;

            // SCALE THE RESULT BACK TO fixed-point (Q8.8)
            mult_result = mult_result >> DECIMAL_BIT; // SCALE (shift right)

            // SELECT OPERAND FOR THE ACC BLOCK AND ADD THE ACCUMULATION WITH THE RESULT FROM MULTIPLICATION
            case (acc_sel)
                2'b00: acc_temp = mult_result[15:0];                // JUST RESULT FROM MULTIPICATION
                2'b01: acc_temp = MLOout + mult_result[15:0];       // ADD MLIout
                2'b10: acc_temp = EOAout + mult_result[15:0];       // ADD EOAout
                2'b11: acc_temp = SEOAout + mult_result[15:0];      // ADD SEOAout
//                default: acc_temp = 16'b0; // mặc định là 0
            endcase
            // ASSIGN FINAL RESULT
            acc_result = acc_temp;
    end
endmodule
