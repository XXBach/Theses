`timescale 1ns / 1ps

// CREATE MUX64 FROM MUX8
module mux64 #(
    parameter DATA_WIDTH = 16               // DECLARE DATA WIDTH
)(
    input  [64*DATA_WIDTH-1:0] in,          // 64 PORT IN
    input  [5:0] sel,                       // SELECT
    output [DATA_WIDTH-1:0] out             // OUTPUT
);

    wire [DATA_WIDTH-1:0] mux8_out[7:0];    // DECLARE OUTPUT FROM FIRST 8 MULTIPLEXERS

    // CREATE 8 MULTIPLEXERS
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : mux8_layer
            // PASSING PARAMETER FOR EACH MUX
            mux8 #(DATA_WIDTH) u_mux8 (
                .in(in[(i+1)*8*DATA_WIDTH-1:i*8*DATA_WIDTH]),       
                .sel(sel[2:0]),                                     
                .out(mux8_out[i])                                   
            );
        end
    endgenerate

    // CREATE NEW MUX TO CHOOSE RESULT FROM 1 OF 8 MULTIPLEXERS
    mux8 #(DATA_WIDTH) final_mux8 (
        .in({mux8_out[7], mux8_out[6], mux8_out[5], mux8_out[4], 
             mux8_out[3], mux8_out[2], mux8_out[1], mux8_out[0]}), // INPUT IS A RESULT OF 8 MULTIPLEXERS 
        .sel(sel[5:3]),                                            // SELECT
        .out(out)                                                  // FINAL OUTPUT
    );

endmodule
