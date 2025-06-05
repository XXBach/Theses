`timescale 1ns / 1ps

module multiply_accumulate_tb;

    // Parameters
    parameter DATA_WIDTH = 16;
    parameter DECIMAL_BIT = 8;

    // Inputs
    reg [1:0] mult_sel_1;
    reg mult_sel_2;
    reg [1:0] acc_sel;
    reg [DATA_WIDTH-1:0] MLIout;
    reg [DATA_WIDTH-1:0] MLIout_all;
    reg [DATA_WIDTH-1:0] MLKout;
    reg [DATA_WIDTH-1:0] MLOout;
    reg [DATA_WIDTH-1:0] EOAout;
    reg [DATA_WIDTH-1:0] SEOAout;

    // Outputs
    wire [DATA_WIDTH-1:0] acc_result;

    // Instantiate the DUT (Device Under Test)
    multiply_accumulate #(
        .DATA_WIDTH(DATA_WIDTH),
        .DECIMAL_BIT(DECIMAL_BIT)
    ) dut (
        .mult_sel_1(mult_sel_1),
        .mult_sel_2(mult_sel_2),
        .acc_sel(acc_sel),
        .MLIout(MLIout),
        .MLIout_all(MLIout_all),
        .MLKout(MLKout),
        .MLOout(MLOout),
        .EOAout(EOAout),
        .SEOAout(SEOAout),
        .acc_result(acc_result)
    );

    // Testbench variables
    initial begin
        // Initialize inputs
        mult_sel_1 = 2'b00;
        mult_sel_2 = 1'b0;
        acc_sel = 2'b00;
        MLIout = 16'h0100;       // 1.0 in Q8.8 format
        MLIout_all = 16'h0200;   // 2.0 in Q8.8 format
        MLKout = 16'h0300;       // 3.0 in Q8.8 format
        MLOout = 16'h0400;       // 4.0 in Q8.8 format
        EOAout = 16'h0500;       // 5.0 in Q8.8 format
        SEOAout = 16'h0600;      // 6.0 in Q8.8 format

        // Wait for global reset
        #10;

        // Test Case 1: Multiply 0 with 1 (result should be 0)
        mult_sel_1 = 2'b00;
        mult_sel_2 = 1'b0;
        acc_sel = 2'b00;
        #10;

        // Test Case 2: Multiply MLIout with 1 (result should be MLIout)
        mult_sel_1 = 2'b01;
        mult_sel_2 = 1'b0;
        acc_sel = 2'b00;
        #10;

        // Test Case 3: Multiply MLIout with MLKout and accumulate with MLOout
        mult_sel_1 = 2'b01;
        mult_sel_2 = 1'b1;
        acc_sel = 2'b01;
        #10;

        // Test Case 4: Multiply MLIout_all with MLKout and accumulate with EOAout
        mult_sel_1 = 2'b10;
        mult_sel_2 = 1'b1;
        acc_sel = 2'b10;
        #10;

        // Test Case 5: Multiply MLIout_all with MLKout and accumulate with SEOAout
        mult_sel_1 = 2'b10;
        mult_sel_2 = 1'b1;
        acc_sel = 2'b11;
        #10;

        // Test Case 6: Edge case, multiply 0 with MLKout and accumulate with SEOAout
        mult_sel_1 = 2'b00;
        mult_sel_2 = 1'b1;
        acc_sel = 2'b11;
        #10;

        // Finish simulation
        $finish;
    end

    // Monitor signals
    initial begin
        $monitor("Time: %0d, mult_sel_1: %b, mult_sel_2: %b, acc_sel: %b, acc_result: %h",
                 $time, mult_sel_1, mult_sel_2, acc_sel, acc_result);
    end
endmodule
