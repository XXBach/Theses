`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/16/2025 07:38:00 PM
// Design Name: 
// Module Name: read_hex_file
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
   

module read_hex_file;
    // Khai báo mảng động để lưu giá trị từ 2 file
    reg [15:0] input_array_hexa [];
    reg [15:0] conv_array_hexa [];
    integer file_input, file_conv, status;
    reg [31:0] line_data;

    // Task để đọc dữ liệu từ file và lưu vào mảng
    function read_file_to_array_0(input string file_name, output reg [15:0] array []);
        integer file, status;
        reg [15:0] line_data;
        begin
            // Mở file
            file = $fopen(file_name, "r");
            if (file == 0) begin
                $display("Không thể mở file %s!", file_name);
                $finish;
            end

            // Đọc dữ liệu từ file
            while (!$feof(file)) begin
                status = $fscanf(file, "%h\n", line_data);
                if (status == 1) begin
                    // Lưu giá trị hợp lệ vào mảng
                    array = {array, line_data[15:0]};
                end else begin
                    // Xử lý lỗi nếu đọc không đúng định dạng
                    $display("Cảnh báo: Không thể đọc dòng tiếp theo trong file %s.", file_name);
                end
            end

            // Đóng file
            $fclose(file);
        end
    endfunction

    function read_file_to_array_1(input string file_name, output reg [15:0] array []);
        integer file, status;
        reg [15:0] line_data;
        begin
            // Mở file
            file = $fopen(file_name, "r");
            if (file == 0) begin
                $display("Không thể mở file %s!", file_name);
                $finish;
            end

            // Đọc dữ liệu từ file
            while (!$feof(file)) begin
                status = $fscanf(file, "%h\n", line_data);
                if (status == 1) begin
                    // Lưu giá trị hợp lệ vào mảng
                    array = {array, line_data[15:0]};
                end else begin
                    // Xử lý lỗi nếu đọc không đúng định dạng
                    $display("Cảnh báo: Không thể đọc dòng tiếp theo trong file %s.", file_name);
                end
            end

            // Đóng file
            $fclose(file);
        end
    endfunction


    initial begin
        
        $display("Đọc dữ liệu từ file features_input.txt...");
        read_file_to_array_0("C:/Users/acer/Desktop/data/features_input.txt", input_array_hexa);
//        #500
        
        $display("Đọc dữ liệu từ file conv1.txt...");
        read_file_to_array_1("C:/Users/acer/Desktop/data/conv1.txt", conv_array_hexa);

        // Hiển thị nội dung của mảng input_array_hexa
        $display("Dữ liệu trong input_array_hexa:");
        for (int i = 0; i < input_array_hexa.size(); i++) begin
            $display("input_array_hexa[%0d] = %h", i, input_array_hexa[i]);
        end

        // Hiển thị nội dung của mảng conv_array_hexa
        $display("Dữ liệu trong conv_array_hexa:");
        for (int i = 0; i < conv_array_hexa.size(); i++) begin
            $display("conv_array_hexa[%0d] = %h", i, conv_array_hexa[i]);
        end

        $finish;
    end
endmodule
