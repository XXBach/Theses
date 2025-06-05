`timescale 1ns / 1ps
`define SINGLE 1
`define ONE_ONE 2
`define TWO_TWO 3


module ASIP_tb;

// Parameters
parameter INSTRUCTION_WIDTH = 32;
parameter MCMEM_SIZE = 4096;
parameter DATA_WIDTH_MC = 32;
parameter ADDR_WIDTH = 32;
parameter DATA_WIDTH_DNN_CORE = 16;
parameter DECIMAL_BIT = 8;
parameter INSTRUCTION_WIDTH_DNN_CORE = 212;
parameter BUFFER_SIZE = 512;
parameter SCRATCHPAD_SIZE = 512;
parameter BLOCKS_PER_ROW = 64;
parameter MODEL = `SINGLE;
parameter IS_FIRST_ROW = 1;
parameter IS_FIRST_COL = 1;


// Inputs
bit clk;
bit rst;
bit start;
bit wen_MCMem;
bit [$clog2(MCMEM_SIZE)-1:0] addr_w_MCMem;
bit [INSTRUCTION_WIDTH-1:0] data_w_MCMem;
bit vsync_in;
bit hsync_in;
bit all_DNN_done_signal;
wire vsync_out;
wire hsync_out;
wire start_DNN_core;
wire end_flag;

//PORT0 ==============
bit [67:0] command_P0_in;
bit [15:0] data_P0_in;
wire [67:0] command_P0_out;
wire [15:0] data_P0_out;

//PORT1
bit [67:0] command_P1_in;
bit [15:0] data_P1_in;
wire [67:0] command_P1_out;
wire [15:0] data_P1_out;


//PORT OM
wire [31:0] addr_OM;
wire wen_OM;
wire ren_OM;
bit [31:0] data_r_OM;
wire [31:0] data_w_OM;
wire ren_OM_inst;
bit [211:0] inst_r_OM;

//PORT DNN core
wire [8:0] addr_DNN;
wire wen_inst_mem;
wire [63:0] wen_IB;
wire [63:0] wen_KSP;
wire wen_BSP;
wire ren_OB;
wire [31:0] data_w_DNN;
wire [211:0] inst_w_DNN;
bit done_transfer_prev;
wire done_transfer;

wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB;
wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OB;

bit [7:0] select;

wire [DATA_WIDTH_DNN_CORE - 1 : 0] NEOA_read_out;
wire sel_lut;

wire [DATA_WIDTH_DNN_CORE - 1 : 0] li_data_out;

wire [DATA_WIDTH_DNN_CORE - 1 : 0] POA_read_out;


wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_ML_out;
wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_CONV_out;
wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_FCSP_ML_out;
wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB_ML_out;
wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OB_ML_out;
wire [DATA_WIDTH_DNN_CORE - 1 : 0] OB_read_out;
wire [DATA_WIDTH_DNN_CORE - 1 : 0] MEM_read_out;

wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_IB;
wire done_DNN;

wire DSIP_done;

// Instantiate the Unit Under Test (UUT)
ASIP #(
    .INSTRUCTION_WIDTH(INSTRUCTION_WIDTH),
    .MCMEM_SIZE(MCMEM_SIZE),
    .DATA_WIDTH_MC(DATA_WIDTH_MC),
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH_DNN_CORE(DATA_WIDTH_DNN_CORE),
    .DECIMAL_BIT(DECIMAL_BIT),
    .INSTRUCTION_WIDTH_DNN_CORE(INSTRUCTION_WIDTH_DNN_CORE),
    .BUFFER_SIZE(BUFFER_SIZE),
    .SCRATCHPAD_SIZE(SCRATCHPAD_SIZE),
    .BLOCKS_PER_ROW(BLOCKS_PER_ROW),
    .MODEL(MODEL),
    .IS_FIRST_ROW(IS_FIRST_ROW),
    .IS_FIRST_COL(IS_FIRST_COL)
) uut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .wen_MCMem(wen_MCMem),
    .addr_w_MCMem(addr_w_MCMem),
    .data_w_MCMem(data_w_MCMem),
    
    .vsync_in(vsync_out),
    .hsync_in(hsync_in),
//    .all_DNN_done_signal(done_DNN),
    .vsync_out(vsync_out),
    .hsync_out(hsync_out),
    .start_DNN_core(start_DNN_core),
    .end_flag(end_flag),
//PORT0 ==============
    .command_P0_in(command_P0_in),
    .data_P0_in(data_P0_in),
    .command_P0_out(command_P0_out),
    .data_P0_out(data_P0_out),
//PORT1
    .command_P1_in(command_P1_in),
    .data_P1_in(data_P1_in),
    .command_P1_out(command_P1_out),
    .data_P1_out(data_P1_out),
//PORT OM
    .addr_OM(addr_OM),
    .wen_OM(wen_OM),
    .ren_OM(ren_OM),
    .data_r_OM(data_r_OM),
    .data_w_OM(data_w_OM),
    .ren_OM_inst(ren_OM_inst),
    .inst_r_OM(inst_r_OM),
//PORT DNN core
    .addr_DNN(addr_DNN),
    .wen_inst_mem(wen_inst_mem),
    .wen_IB(wen_IB),
    .wen_KSP(wen_KSP),
    .wen_BSP(wen_BSP),
    .ren_OB(ren_OB),
    .data_w_DNN(data_w_DNN),
    .inst_w_DNN(inst_w_DNN),
    .done_transfer_prev(done_transfer_prev),
    .done_transfer(done_transfer),

    .done_DNN(done_DNN),
    .DSIP_done(DSIP_done)
);



// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100 MHz clock
end


// CODE MO PHONG OM ========================================================
reg [DATA_WIDTH_DNN_CORE - 1:0] OM_mem[0:1879048192];
reg [DATA_WIDTH_DNN_CORE - 1:0] data_read_from_OM;
always @(posedge clk) begin
    if(wen_OM) OM_mem[addr_OM] <= data_w_OM;
    else if(ren_OM) data_read_from_OM <= OM_mem[addr_OM];
end
assign data_r_OM = data_read_from_OM;

reg [INSTRUCTION_WIDTH_DNN_CORE-1:0] OM_mem_inst[0:65535];
reg [INSTRUCTION_WIDTH_DNN_CORE-1:0] inst_read_from_OM;
always @(posedge clk) begin
    if(ren_OM_inst) inst_read_from_OM <= OM_mem_inst[addr_OM];
end
assign inst_r_OM = inst_read_from_OM;
//==========================================================================

//doc DNN instruction
//module read_DNN_instruction;
//  // Định nghĩa các tham số và mảng
//  parameter DATA_WIDTH = INSTRUCTION_WIDTH_DNN_CORE;  // Độ rộng dữ liệu (16 bit)
//  parameter ARRAY_SIZE = 65536; // Kích thước mảng
//  parameter OFFSET = 32'h00000000; // Offset để gán dữ liệu bắt đầu từ vị trí 100
////  reg [DATA_WIDTH-1:0] data_array [0:ARRAY_SIZE-1]; // Mảng lưu dữ liệu
//  integer file, r, line_number_inst; // Biến tạm cho file và dòng dữ liệu
//  reg [255:0] line_inst; // Chuỗi tạm để đọc từng dòng
//  reg [DATA_WIDTH-1:0] temp_data_inst; // Biến tạm để lưu dữ liệu từ dòng
//  initial begin
//    // Gán giá trị mặc định cho mảng
//    integer i;
//    // Mở file txt
//    file = $fopen("D:/tailieu/Nghien_cuu_khoa_hoc/codeDSIP/venv/testfile/DNN_instruction/instructions_0.txt", "r");
//    if (file == 0) begin
//      $display("Không thể mở file!");
//      $finish;
//    end
//    line_number_inst = 0;
//    // Đọc từng dòng trong file
//    while (!$feof(file)) begin
//      r = $fgets(line_inst, file); // Đọc dòng từ file
//      if (r) begin
//        // Parse dữ liệu hexa từ dòng
//        r = $sscanf(line_inst, "%h", temp_data_inst); // Đọc dữ liệu hexa
//        if (r == 1) begin
//          // Gán dữ liệu vào mảng với OFFSET
//          if (line_number_inst + OFFSET < ARRAY_SIZE) begin
//            OM_mem_inst[line_number_inst + OFFSET] = temp_data_inst; // Gán từ vị trí OFFSET
////            $display("Đọc dòng %0d: %h -> Gán vào OM_mem[%0d]", line_number, temp_data, line_number + OFFSET);
//          end else begin
//            $display("Dữ liệu vượt kích thước mảng, dòng %0d sẽ bị bỏ qua.", line_number_inst);
//          end
//          line_number_inst = line_number_inst + 1;
//        end else begin
//          $display("Dòng %0d không hợp lệ: %s", line_number_inst, line_inst);
//        end
//      end
//    end
//    $fclose(file);
//  end
//endmodule



//doc input features
module read_input_features;
  // Định nghĩa các tham số và mảng
  parameter DATA_WIDTH = 16;  // Độ rộng dữ liệu (16 bit)
  parameter ARRAY_SIZE = 1879048192; // Kích thước mảng
  parameter OFFSET = 32'h00010000; // Offset để gán dữ liệu bắt đầu từ vị trí 100
//  reg [DATA_WIDTH-1:0] data_array [0:ARRAY_SIZE-1]; // Mảng lưu dữ liệu
  integer file, r, line_number; // Biến tạm cho file và dòng dữ liệu
  reg [255:0] line; // Chuỗi tạm để đọc từng dòng
  reg [DATA_WIDTH-1:0] temp_data; // Biến tạm để lưu dữ liệu từ dòng
  initial begin
    // Gán giá trị mặc định cho mảng
    integer i;
    // Mở file txt
    file = $fopen("E:/codeDSIP_DoAn1/150425/model_tiny_test_110525/6956/6956_hex.txt", "r");
    if (file == 0) begin
      $display("Không thể mở file!");
      $finish;
    end
    line_number = 0;
    // Đọc từng dòng trong file
    while (!$feof(file)) begin
      r = $fgets(line, file); // Đọc dòng từ file
      if (r) begin
        // Parse dữ liệu hexa từ dòng
        r = $sscanf(line, "%h", temp_data); // Đọc dữ liệu hexa
        if (r == 1) begin
          // Gán dữ liệu vào mảng với OFFSET
          if (line_number + OFFSET < ARRAY_SIZE) begin
            OM_mem[line_number + OFFSET] = temp_data; // Gán từ vị trí OFFSET
//            $display("Đọc dòng %0d: %h -> Gán vào OM_mem[%0d]", line_number, temp_data, line_number + OFFSET);
          end else begin
            $display("Dữ liệu vượt kích thước mảng, dòng %0d sẽ bị bỏ qua.", line_number);
          end
          line_number = line_number + 1;
        end else begin
          $display("Dòng %0d không hợp lệ: %s", line_number, line);
        end
      end
    end
    $fclose(file);
  end
endmodule


//doc conv0 weights
module read_weights_conv0;
  // Định nghĩa các tham số và mảng
  parameter DATA_WIDTH = 16;  // Độ rộng dữ liệu (16 bit)
  parameter ARRAY_SIZE = 1879048192; // Kích thước mảng
  parameter OFFSET = 32'h00010C00; // Offset để gán dữ liệu bắt đầu từ vị trí 100
//  reg [DATA_WIDTH-1:0] data_array [0:ARRAY_SIZE-1]; // Mảng lưu dữ liệu
  integer file, r, line_number; // Biến tạm cho file và dòng dữ liệu
  reg [255:0] line; // Chuỗi tạm để đọc từng dòng
  reg [DATA_WIDTH-1:0] temp_data; // Biến tạm để lưu dữ liệu từ dòng
  initial begin
    // Gán giá trị mặc định cho mảng
    integer i;
    // Mở file txt
    file = $fopen("E:/codeDSIP_DoAn1/150425/model_tiny_test_110525/Weight_bias_hex/weights_conv0_hex.txt", "r");
    if (file == 0) begin
      $display("Không thể mở file!");
      $finish;
    end
    line_number = 0;
    // Đọc từng dòng trong file
    while (!$feof(file)) begin
      r = $fgets(line, file); // Đọc dòng từ file
      if (r) begin
        // Parse dữ liệu hexa từ dòng
        r = $sscanf(line, "%h", temp_data); // Đọc dữ liệu hexa
        if (r == 1) begin
          // Gán dữ liệu vào mảng với OFFSET
          if (line_number + OFFSET < ARRAY_SIZE) begin
            OM_mem[line_number + OFFSET] = temp_data; // Gán từ vị trí OFFSET
//            $display("Đọc dòng %0d: %h -> Gán vào OM_mem[%0d]", line_number, temp_data, line_number + OFFSET);
          end else begin
            $display("Dữ liệu vượt kích thước mảng, dòng %0d sẽ bị bỏ qua.", line_number);
          end
          line_number = line_number + 1;
        end else begin
          $display("Dòng %0d không hợp lệ: %s", line_number, line);
        end
      end
    end
    $fclose(file);
  end
endmodule


//doc conv0 biases
module read_biases_conv0;
  // Định nghĩa các tham số và mảng
  parameter DATA_WIDTH = 16;  // Độ rộng dữ liệu (16 bit)
  parameter ARRAY_SIZE = 1879048192; // Kích thước mảng
  parameter OFFSET = 32'h00010F60; // Offset để gán dữ liệu bắt đầu từ vị trí 100
//  reg [DATA_WIDTH-1:0] data_array [0:ARRAY_SIZE-1]; // Mảng lưu dữ liệu
  integer file, r, line_number; // Biến tạm cho file và dòng dữ liệu
  reg [255:0] line; // Chuỗi tạm để đọc từng dòng
  reg [DATA_WIDTH-1:0] temp_data; // Biến tạm để lưu dữ liệu từ dòng
  initial begin
    // Gán giá trị mặc định cho mảng
    integer i;
    // Mở file txt
    file = $fopen("E:/codeDSIP_DoAn1/150425/model_tiny_test_110525/Weight_bias_hex/biases_conv0_hex.txt", "r");
    if (file == 0) begin
      $display("Không thể mở file!");
      $finish;
    end
    line_number = 0;
    // Đọc từng dòng trong file
    while (!$feof(file)) begin
      r = $fgets(line, file); // Đọc dòng từ file
      if (r) begin
        // Parse dữ liệu hexa từ dòng
        r = $sscanf(line, "%h", temp_data); // Đọc dữ liệu hexa
        if (r == 1) begin
          // Gán dữ liệu vào mảng với OFFSET
          if (line_number + OFFSET < ARRAY_SIZE) begin
            OM_mem[line_number + OFFSET] = temp_data; // Gán từ vị trí OFFSET
//            $display("Đọc dòng %0d: %h -> Gán vào OM_mem[%0d]", line_number, temp_data, line_number + OFFSET);
          end else begin
            $display("Dữ liệu vượt kích thước mảng, dòng %0d sẽ bị bỏ qua.", line_number);
          end
          line_number = line_number + 1;
        end else begin
          $display("Dòng %0d không hợp lệ: %s", line_number, line);
        end
      end
    end
    $fclose(file);
  end
endmodule
// doc dense0 weights
module read_weights_dense;
  // Định nghĩa các tham số và mảng
  parameter DATA_WIDTH = 16;  // Độ rộng dữ liệu (16 bit)
  parameter ARRAY_SIZE = 1879048192; // Kích thước mảng
  parameter OFFSET = 32'h000133A0; // Offset để gán dữ liệu bắt đầu từ vị trí 100
//  reg [DATA_WIDTH-1:0] data_array [0:ARRAY_SIZE-1]; // Mảng lưu dữ liệu
  integer file, r, line_number; // Biến tạm cho file và dòng dữ liệu
  reg [255:0] line; // Chuỗi tạm để đọc từng dòng
  reg [DATA_WIDTH-1:0] temp_data; // Biến tạm để lưu dữ liệu từ dòng
  initial begin
    // Gán giá trị mặc định cho mảng
    integer i;
    // Mở file txt
    file = $fopen("E:/codeDSIP_DoAn1/150425/model_tiny_test_110525/Weight_bias_hex/weights_dense_hex.txt", "r");
    if (file == 0) begin
      $display("Không thể mở file!");
      $finish;
    end
    line_number = 0;
    // Đọc từng dòng trong file
    while (!$feof(file)) begin
      r = $fgets(line, file); // Đọc dòng từ file
      if (r) begin
        // Parse dữ liệu hexa từ dòng
        r = $sscanf(line, "%h", temp_data); // Đọc dữ liệu hexa
        if (r == 1) begin
          // Gán dữ liệu vào mảng với OFFSET
          if (line_number + OFFSET < ARRAY_SIZE) begin
            OM_mem[line_number + OFFSET] = temp_data; // Gán từ vị trí OFFSET
//            $display("Đọc dòng %0d: %h -> Gán vào OM_mem[%0d]", line_number, temp_data, line_number + OFFSET);
          end else begin
            $display("Dữ liệu vượt kích thước mảng, dòng %0d sẽ bị bỏ qua.", line_number);
          end
          line_number = line_number + 1;
        end else begin
          $display("Dòng %0d không hợp lệ: %s", line_number, line);
        end
      end
    end
    $fclose(file);
  end
endmodule


// doc dense0 biases
module read_biases_dense;
  // Định nghĩa các tham số và mảng
  parameter DATA_WIDTH = 16;  // Độ rộng dữ liệu (16 bit)
  parameter ARRAY_SIZE = 1879048192; // Kích thước mảng
  parameter OFFSET = 32'h0001F6F0; // Offset để gán dữ liệu bắt đầu từ vị trí 100
//  reg [DATA_WIDTH-1:0] data_array [0:ARRAY_SIZE-1]; // Mảng lưu dữ liệu
  integer file, r, line_number; // Biến tạm cho file và dòng dữ liệu
  reg [255:0] line; // Chuỗi tạm để đọc từng dòng
  reg [DATA_WIDTH-1:0] temp_data; // Biến tạm để lưu dữ liệu từ dòng
  initial begin
    // Gán giá trị mặc định cho mảng
    integer i;
    // Mở file txt
    file = $fopen("E:/codeDSIP_DoAn1/150425/model_tiny_test_110525/Weight_bias_hex/biases_dense_hex.txt", "r");
    if (file == 0) begin
      $display("Không thể mở file!");
      $finish;
    end
    line_number = 0;
    // Đọc từng dòng trong file
    while (!$feof(file)) begin
      r = $fgets(line, file); // Đọc dòng từ file
      if (r) begin
        // Parse dữ liệu hexa từ dòng
        r = $sscanf(line, "%h", temp_data); // Đọc dữ liệu hexa
        if (r == 1) begin
          // Gán dữ liệu vào mảng với OFFSET
          if (line_number + OFFSET < ARRAY_SIZE) begin
            OM_mem[line_number + OFFSET] = temp_data; // Gán từ vị trí OFFSET
//            $display("Đọc dòng %0d: %h -> Gán vào OM_mem[%0d]", line_number, temp_data, line_number + OFFSET);
          end else begin
            $display("Dữ liệu vượt kích thước mảng, dòng %0d sẽ bị bỏ qua.", line_number);
          end
          line_number = line_number + 1;
        end else begin
          $display("Dòng %0d không hợp lệ: %s", line_number, line);
        end
      end
    end
    $fclose(file);
  end
endmodule
//doc controller instruction
reg [31:0] controller_instruction_temp[0:5000];
// Stimulus
initial begin   
   $readmemb("E:/codeDSIP_DoAn1/150425/Hardware_ASIP_14042025/test_files_newmodel/instruction_ASIP_MC_bin.txt",controller_instruction_temp);
   $readmemb("E:/codeDSIP_DoAn1/150425/Hardware_ASIP_14042025/test_files_newmodel/instruction_ASIP_SC_bin.txt",OM_mem_inst);

   rst = 1;
   #400
   rst = 0;
   // Nap lenh của controller vào mem
   foreach(controller_instruction_temp[i]) begin #10
       wen_MCMem = 1;
       addr_w_MCMem = i;
       data_w_MCMem = controller_instruction_temp[i];
       if(i == 1700) break;
   end
   
   #10
   start = 1;
   #10
   start = 0;
end
/* Khối này là khối ngắt chương trình khi PC đến stop PC, có thể đổi uut2 thành uut1 và ngược lại, khi thỏa điều kiện thì sẽ display ra các kết quả
 Đang display các kết quả trong dense ( OM_mem_2 )
 Kết quả đầu tiên xuất hiện có thể là kết quả nhiễu hoặc cũ, kết quả thứ hai và thứ ba là kết quả của hình 4983, kết quả thứ tư là của 0949, kết quả thứ năm là của 0973, và kết quả cuối cùng là của 0976*/
bit started = 0;
time start_time;
int stop_pc_mc = 1604;
int stop_pc_sc = 40;
int stop_pc = 119;
time end_time;
int start_addr = 32'h00425000;
int num_words = 10;
always @(posedge clk) begin
    if(uut.controller.start_flag && !started) begin
       start_time = $time;
       started = 1;
       $display("[START] Bắt đầu đo tại thời điểm %0t ns", start_time);
    end
    if (uut.controller.PC == stop_pc) begin
//        if(uut.dnn_core.PC == stop_pc_sc) begin
            $display("=== STOPPING: PC reached %0d ===", stop_pc);
            $display("Dumping %0d OM_mem words starting from address %0d", num_words, start_addr);
            for (int i = 0; i < num_words; i++) begin
    //          uncomment dòng sau để hiển thị từ OM_mem_1
    //          $display("OM_mem_1[%0d] = %h", start_addr + i, OM_mem_1[start_addr + i]);
    //          Lấy data từ OM_mem_2 để chắc rằng kquả đã được lưu vào mem
                $display("OM_mem[%0d] = %h", start_addr + i, OM_mem[start_addr + i]);
            end
            // Khi PC chạm giá trị dừng
            if (started) begin
                end_time = $time;
                $display("[STOP] PC = %0d tại thời điểm %0t ns", stop_pc, end_time);
                $display("[RESULT] Tổng thời gian thực thi: %0t ns", end_time - start_time);
            end
            $stop;
//        end
    end
end
// Thông số trạng thái DNN_Core
//parameter logic [3:0] RUNNING_STATE = 4'd5;

//// Biến lưu thời gian
//time last_time = 0;
//time controller_time_total = 0;
//time dnn_time_total = 0;

//// Lưu trạng thái trước
//logic [3:0] prev_state;

//// Khởi tạo
//initial begin
//    last_time  = $time;
//    prev_state = uut.controller.genblk1.mode_ctr.state;
//end

//// Đo thời gian theo state tại mỗi chu kỳ
//always @(posedge uut.clk) begin
//    logic [3:0] curr_state = uut.controller.genblk1.mode_ctr.state;
//    time now   = $time;
//    time delta = now - last_time;

//    // Chỉ phân biệt RUNNING_STATE và còn lại
//    if (prev_state == RUNNING_STATE) begin
//        dnn_time_total += delta;
//    end else begin
//        controller_time_total += delta;
//    end
//    if(uut.controller.PC == stop_pc_mc) begin
//        $display("[STOP] Kết thúc đo tại PC = %b, time = %0t", stop_pc_mc, now);
//        $display("==== Tổng kết thời gian đo ====");
//        $display("️ Thời gian DNN_Core:      %0t ns", dnn_time_total);
//        $display("  Thời gian Controller:    %0t ns", controller_time_total);
//        $display("  Tổng thời gian đo:      %0t ns", dnn_time_total + controller_time_total);
//        $stop;
//    end 
//    // Cập nhật
//    prev_state = curr_state;
//    last_time  = now;
//end

endmodule


