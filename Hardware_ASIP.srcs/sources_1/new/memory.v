`timescale 1ns / 1ps

module memory#(
    parameter DATA_WIDTH = 16,
    parameter SIZE = 512,
    parameter EN_OUT_FF = 0
)(
    input wire clk,
    input wire wen,                  // Tín hiệu ghi
    input wire ren,                  // Tín hiệu đọc
    input wire [$clog2(SIZE)-1:0] addr_w,         // Địa chỉ ghi
    input wire [$clog2(SIZE)-1:0] addr_r,         // Địa chỉ đọc
    input wire [DATA_WIDTH - 1:0] din,            // Dữ liệu đầu vào
    output reg [DATA_WIDTH - 1:0] dout            // Dữ liệu đầu ra
);
    reg [DATA_WIDTH - 1:0] mem [0: SIZE - 1];           
    integer i;
    always @(posedge clk ) begin
        if (wen) begin
            mem[addr_w] <= din;  // Ghi dữ liệu vào bộ nhớ khi `wen` bật
        end

    end
    
    generate
        if(EN_OUT_FF) begin
            always @(posedge clk) begin
                if (ren) begin
                    dout <= mem[addr_r]; // Đọc dữ liệu từ bộ nhớ khi `ren` bật
                end
            end

        end else begin
            always @(*) dout = mem[addr_r];
        end
    endgenerate
endmodule