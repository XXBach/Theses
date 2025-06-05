`timescale 1ns / 1ps

module memory_single_port #(
    parameter SIZE = 256,               // Kích thước bộ nhớ
    parameter DATA_WIDTH = 16
)(
    input wire clk,
    input wire rst,
    input wire wen,                   // Tín hiệu ghi
    input wire ren,                   // Tín hiệu đọc
    input wire [$clog2(SIZE)-1:0] addr_w, // Địa chỉ ghi
    input wire [$clog2(SIZE)-1:0] addr_r, // Địa chỉ đọc
    input wire [DATA_WIDTH - 1:0] din,             // Dữ liệu đầu vào
    output wire [DATA_WIDTH - 1:0] dout            // Dữ liệu đầu ra
);

    generate
        if (SIZE == 256) begin
            // Bộ nhớ nhỏ nhất: Memory256
            memory256 #(DATA_WIDTH) mem256(
                .clk(clk),
                .rst(rst),
                .wen(wen),
                .ren(ren),
                .addr_w(addr_w[7:0]),
                .addr_r(addr_r[7:0]),
                .din(din),
                .dout(dout)
            );

        end else if (SIZE > 256) begin
            // Bộ nhớ lớn hơn: chia thành 4 mô-đun con
            wire [1:0] mem_select_w = addr_w[$clog2(SIZE)-1:$clog2(SIZE)-2]; // Chọn mô-đun con để ghi
            wire [1:0] mem_select_r = addr_r[$clog2(SIZE)-1:$clog2(SIZE)-2]; // Chọn mô-đun con để đọc
            wire [7:0] dout_array [3:0];      // Dữ liệu đầu ra từ mỗi mô-đun con
            reg [1:0] mem_select_r_clk;
            // Khởi tạo 4 mô-đun con
            memory_single_port #(SIZE / 4, DATA_WIDTH) mem0 (
                .clk(clk),
                .rst(rst),
                .wen(wen & (mem_select_w == 2'b00)),
                .ren(ren & (mem_select_r == 2'b00)),
                .addr_w(addr_w[$clog2(SIZE)-3:0]),
                .addr_r(addr_r[$clog2(SIZE)-3:0]),
                .din(din),
                .dout(dout_array[0])
            );

            memory_single_port #(SIZE / 4, DATA_WIDTH) mem1 (
                .clk(clk),
                .rst(rst),
                .wen(wen & (mem_select_w == 2'b01)),
                .ren(ren & (mem_select_r == 2'b01)),
                .addr_w(addr_w[$clog2(SIZE)-3:0]),
                .addr_r(addr_r[$clog2(SIZE)-3:0]),
                .din(din),
                .dout(dout_array[1])
            );

            memory_single_port #(SIZE / 4, DATA_WIDTH) mem2 (
                .clk(clk),
                .rst(rst),
                .wen(wen & (mem_select_w == 2'b10)),
                .ren(ren & (mem_select_r == 2'b10)),
                .addr_w(addr_w[$clog2(SIZE)-3:0]),
                .addr_r(addr_r[$clog2(SIZE)-3:0]),
                .din(din),
                .dout(dout_array[2])
            );

            memory_single_port #(SIZE / 4, DATA_WIDTH) mem3 (
                .clk(clk),
                .rst(rst),
                .wen(wen & (mem_select_w == 2'b11)),
                .ren(ren & (mem_select_r == 2'b11)),
                .addr_w(addr_w[$clog2(SIZE)-3:0]),
                .addr_r(addr_r[$clog2(SIZE)-3:0]),
                .din(din),
                .dout(dout_array[3])
            );

            // Chọn dữ liệu đầu ra từ mô-đun con
            always @(posedge clk) mem_select_r_clk = mem_select_r;
            assign dout = dout_array[mem_select_r_clk];
        end
    endgenerate

endmodule





module memory256#(
    parameter DATA_WIDTH = 16
)(
    input wire clk,
    input wire rst,
    input wire wen,                  // Tín hiệu ghi
    input wire ren,                  // Tín hiệu đọc
    input wire [7:0] addr_w,         // Địa chỉ ghi
    input wire [7:0] addr_r,         // Địa chỉ đọc
    input wire [DATA_WIDTH - 1:0] din,            // Dữ liệu đầu vào
    output reg [DATA_WIDTH - 1:0] dout            // Dữ liệu đầu ra
);
    reg [DATA_WIDTH - 1:0] mem [255:0];           // RAM 256 từ, mỗi từ 16 bit
    integer i;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            for(i = 0; i < 256; i = i + 1) begin
                mem[i] <= 0;
            end
        end
        else begin
            if (wen) begin
                mem[addr_w] <= din;  // Ghi dữ liệu vào bộ nhớ khi `wen` bật
            end
            if (ren) begin
                dout <= mem[addr_r]; // Đọc dữ liệu từ bộ nhớ khi `ren` bật
            end
        end
    end
endmodule
