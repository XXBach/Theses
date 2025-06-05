`timescale 1ns/1ps

module queue_tb;
    // Tham số
    parameter DATA_WIDTH = 8;
    parameter DEPTH = 8;

    // Tín hiệu
    reg clk;
    reg rst;
    reg enqueue;
    reg dequeue;
    reg [DATA_WIDTH-1:0] data_in;
    wire [DATA_WIDTH-1:0] data_out;
    wire full;
    wire empty;

    // Instantiation của module queue
    queue #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH)) uut (
        .clk(!clk),
        .rst(rst),
        .enqueue(enqueue),
        .dequeue(dequeue),
        .data_in(data_in),
        .data_out(data_out),
        .full(full),
        .empty(empty)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // Chu kỳ clock là 10ns

    // Testbench logic
    initial begin
        // Khởi tạo tín hiệu
        rst = 1;
        enqueue = 0;
        dequeue = 0;
        data_in = 0;

        // Reset hàng đợi
        #10;
        rst = 0;

        // Case 1: Nạp đầy dữ liệu vào queue và lấy ra hết
        $display("Case 1: Nạp đầy và lấy ra hết");
        repeat (DEPTH) begin
            @(posedge clk);
            enqueue = 1;
            data_in = $random % 256; // Dữ liệu ngẫu nhiên
        end
        @(posedge clk);
        enqueue = 0;

        repeat (DEPTH) begin
            @(posedge clk);
            dequeue = 1;
        end
        @(posedge clk);
        dequeue = 0;

        // Case 2: Nạp một nửa, lấy ra 2 phần tử và tiếp tục nạp đầy
        $display("Case 2: Nạp một nửa, lấy ra 2 phần tử và tiếp tục nạp đầy");
        repeat (DEPTH / 2) begin
            @(posedge clk);
            enqueue = 1;
            data_in = $random % 256;
        end
        @(posedge clk);
        enqueue = 0;

        repeat (2) begin
            @(posedge clk);
            dequeue = 1;
        end
        @(posedge clk);
        dequeue = 0;

        repeat (DEPTH / 2 + 2) begin
            @(posedge clk);
            enqueue = 1;
            data_in = $random % 256;
        end
        @(posedge clk);
        enqueue = 0;

        // Case 3: Nạp và lấy ra xen kẽ
        $display("Case 3: Nạp và lấy ra xen kẽ");
        repeat (DEPTH) begin
            @(posedge clk);
            enqueue = 1;
            data_in = $random % 256;
            @(posedge clk);
            enqueue = 0;
            dequeue = 1;
            @(posedge clk);
            dequeue = 0;
        end

        // Case 4: Nạp và lấy ra cùng lúc
        $display("Case 4: Nạp và lấy ra cùng lúc");
        repeat (DEPTH) begin
            @(posedge clk);
            enqueue = 1;
            dequeue = 1;
            data_in = $random % 256;
        end
        @(posedge clk);
        enqueue = 0;
        dequeue = 0;

        // Kết thúc testbench
        #10
        dequeue = 1;
        #20;
        $finish;
    end
endmodule
