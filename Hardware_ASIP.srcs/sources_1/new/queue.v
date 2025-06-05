module queue #(parameter DATA_WIDTH = 8, DEPTH = 8) (
    input wire clk,
    input wire rst,
    input wire enqueue,       // Tín hiệu thêm phần tử
    input wire dequeue,       // Tín hiệu lấy phần tử
    input wire [DATA_WIDTH-1:0] data_in, // Dữ liệu đầu vào
    output reg [DATA_WIDTH-1:0] data_out, // Dữ liệu đầu ra
    output wire full,          // Tín hiệu hàng đợi đầy
    output wire empty          // Tín hiệu hàng đợi rỗng
);

    // Mảng để lưu trữ dữ liệu trong hàng đợi
    reg [DATA_WIDTH-1:0] queue_mem[DEPTH-1:0];
    reg [$clog2(DEPTH):0] head; // Chỉ số đầu hàng đợi
    reg [$clog2(DEPTH):0] tail; // Chỉ số cuối hàng đợi
    reg [$clog2(DEPTH+1)-1:0] count; // Số phần tử hiện có trong hàng đợi
    assign  full = (count == DEPTH);
    assign empty = (count == 0);
   always @(posedge clk or posedge rst) begin
    if (rst) begin
        head <= 0;
        tail <= 0;
        count <= 0;
//        full <= 0;
//        empty <= 1;
        data_out <= 0;
    end else begin
        // Cập nhật trạng thái full và empty
//        full <= (count == DEPTH);
//        empty <= (count == 0);

        // Xử lý trường hợp enqueue và dequeue đồng thời
        if (enqueue && dequeue) begin
            if (!empty) begin
                data_out <= queue_mem[head]; // Đọc dữ liệu từ head
                head <= (head + 1) % DEPTH;  // Cập nhật head
            end
            if (!full) begin
                queue_mem[tail] <= data_in;  // Ghi dữ liệu vào tail
                tail <= (tail + 1) % DEPTH;  // Cập nhật tail
            end
            // Count không thay đổi khi cả enqueue và dequeue đồng thời
        end else if (enqueue && !full) begin
            queue_mem[tail] <= data_in;  // Ghi dữ liệu vào tail
            tail <= (tail + 1) % DEPTH;  // Cập nhật tail
            count <= count + 1;         // Tăng số lượng phần tử
        end else if (dequeue && !empty) begin
            data_out <= queue_mem[head]; // Đọc dữ liệu từ head
            head <= (head + 1) % DEPTH;  // Cập nhật head
            count <= count - 1;         // Giảm số lượng phần tử
        end
    end
end


endmodule
