`timescale 1ns / 1ps

module register #(
    parameter DATA_WIDTH = 16               // DECLARE DATA WIDTH
)(
    // DECLARE INPUT
    input clk,                              // CLOCK
    input rst,                              // RESET SIGNAL
    input wen,                              // WRITE ENABLE
    input [DATA_WIDTH-1:0] data_in,         // INPUT DATA
    
    // DECLARE OUTPUT
    output reg [DATA_WIDTH-1:0] data_out    // OUTPUT DATA
);

always @(posedge clk or posedge rst) begin
    // RESET
    if(rst) data_out <= 0;
    
    // WRITE
    else begin
        if(wen) data_out <= data_in;
    end   
end
endmodule
