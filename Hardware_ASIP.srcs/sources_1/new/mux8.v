`timescale 1ns / 1ps

module mux8 #(parameter DATA_WIDTH = 16) (
    input  [8*DATA_WIDTH-1:0] in,   // 8 đầu vào, mỗi đầu vào DATA_WIDTH-bit
    input  [2:0] sel,               // Tín hiệu chọn 3-bit
    output [DATA_WIDTH-1:0] out     // Đầu ra DATA_WIDTH-bit
);

    // Mỗi giá trị `sel` sẽ chọn một đầu vào DATA_WIDTH-bit trong `in`
    assign out = (sel == 3'b000) ? in[1*DATA_WIDTH-1:0*DATA_WIDTH] :
                 (sel == 3'b001) ? in[2*DATA_WIDTH-1:1*DATA_WIDTH] :
                 (sel == 3'b010) ? in[3*DATA_WIDTH-1:2*DATA_WIDTH] :
                 (sel == 3'b011) ? in[4*DATA_WIDTH-1:3*DATA_WIDTH] :
                 (sel == 3'b100) ? in[5*DATA_WIDTH-1:4*DATA_WIDTH] :
                 (sel == 3'b101) ? in[6*DATA_WIDTH-1:5*DATA_WIDTH] :
                 (sel == 3'b110) ? in[7*DATA_WIDTH-1:6*DATA_WIDTH] :
                 in[8*DATA_WIDTH-1:7*DATA_WIDTH]; // sel == 3'b111

endmodule
