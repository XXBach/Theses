`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/12/2024 05:15:07 PM
// Design Name: 
// Module Name: slave_core
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

module slave_core #(
    parameter DATA_WIDTH = 16,                       // độ rộng data  
    parameter DECIMAL_BIT = 8,                       // DECLARE NUMBER OF BITS DECIMAL PART
    parameter INSTRUCTION_WIDTH = 212,               // kích thước lệnh
    parameter BUFFER_SIZE = 512,                     // kích thước instruction mem
    parameter SCRATCHPAD_SIZE = 64,                  // kích thước IB, KSP, OSP, FCSP, OB
    parameter BLOCKS_PER_ROW = 64                    // số lượng block song song
)(
    input wire clk,                                                 // clock - 100 MHz
    input wire rst,                                                 // reset
    input wire start,                                               // start ASIP
    input wire en_write_SC,                                         // enable write DNN core instruction memory
    input wire [$clog2(BUFFER_SIZE)-1:0] SC_addr_w,                 // addr write DNN core instruction memory
    input wire [INSTRUCTION_WIDTH-1:0] inst_SC_w,                   // instruction writing to DNN core instruction memory
    input wire [BLOCKS_PER_ROW-1:0] en_write_IB,                    // enable write IB
    input wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_IB,         // addr write IB
    input wire [BLOCKS_PER_ROW-1:0] en_write_KSP,                   // enable write KSP
    input wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_KSP,        // addr write KSP
    input wire en_write_BSP,                                        // enable write BSP
    input wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_BSP,        // addr write BSP
    input wire [DATA_WIDTH - 1 : 0] data_write,                     // data write memory
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB,        // addr write OB (don't need to use)
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OB,         // addr read OB (don't need to use)         
    input wire [7:0] select,                                        // select 1 of 64 memory of IB/KSP/OSP... (don't need to use)
    output wire [DATA_WIDTH - 1 : 0] NEOA_read_out,                 // NEOA read (don't need to use)
    output wire sel_lut,                                            // select Look up table (don't need to use)
    output wire [DATA_WIDTH - 1 : 0] li_data_out,                   // Linear Interpolation's data read (don't need to use)
    output wire [DATA_WIDTH - 1 : 0] POA_read_out,                  // POA read (don't need to use)
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_ML_out,        // addr write OSP stage ML (don't need to use)
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_CONV_out,      // addr write OSP stage CONV (don't need to use)
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_FCSP_ML_out,       // addr write FCSP stage ML (don't need to use)
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_FCSP_CONV_out,     // addr write FCSP stage CONV (don't need to use)
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB_ML_out,         // addr write OB stage ML (don't need to use)
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB_CONV_out,       // addr write OB stage CONV (don't need to use)
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OB_ML_out,          // addr read OB stage ML (don't need to use)    
    output wire [DATA_WIDTH - 1 : 0] OB_read_out,                           // OB data read (don't need to use)
    output wire [DATA_WIDTH - 1 : 0] MEM_read_out,                          // MEM data read (don't need to use)
    input wire en_MC_read_OB,                                               // enable read OB 
    input wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_MC_read_OB,               // addr read OB 
    output wire [DATA_WIDTH - 1 : 0] data_MC_read_OB,                       // data read OB
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_IB,                 // addr read IB (don't need to use)
    output wire done_DNN                                                    // DNN core done
    
    );
//STAGE IF =======================================================================
    // declare wires of stage IF
//    wire DNN_end_flag;
    wire run_en;
    wire sit_en;
    wire sbp_en;
    wire sof_en; 
    wire [8:0] offset;
    wire new_base_addr;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_read_IB;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_read_KSP;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_write_OSP;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_read_OSP;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_write_OB;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_read_OB;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_read_BSP;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_write_FCSP;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_read_FCSP;
    // declare AGU block
    wire select_next_PC;
    wire [8:0] PC_start;
    reg [8:0] PC;
    reg [INSTRUCTION_WIDTH-1:0] instruction_stage_IF;
//    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_IB;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_KSP;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OSP;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_BSP;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_FCSP;
    reg [INSTRUCTION_WIDTH-1:0] instruction_stage_MS;
    reg [INSTRUCTION_WIDTH-1:0] instruction_stage_PL;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            instruction_stage_MS = 0;
        end
        else begin
            instruction_stage_MS = instruction_stage_PL;
        end
    end
    wire [INSTRUCTION_WIDTH - 1 : 0] instruction_read;
    
    // instruction memory
    memory #(.DATA_WIDTH(INSTRUCTION_WIDTH),                
             .SIZE(BUFFER_SIZE),
             .EN_OUT_FF(0)) SC
             (.clk(clk),
              .wen(en_write_SC),
              .ren(1'b1),
              .addr_w(SC_addr_w),
              .addr_r(PC),
              .din(inst_SC_w),
              .dout(instruction_read));             // instruction read from DNN core instruction mem
              

    // latch instruction from SC to ensure that
    // it syncs with AGU
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            instruction_stage_IF = 0;
        end
        else begin
            instruction_stage_IF = instruction_read;
        end
    end
              
    wire [10:0] slot1;
    assign slot1 = instruction_read[146:136];
    wire [90:0] slot2;
    assign slot2 = instruction_read[135:45];
    
    // decode instruction slot1 and slot2
    decoder_stage_IF #(.SCRATCHPAD_SIZE(SCRATCHPAD_SIZE))
                     decIF (.slot1(slot1),
                            .slot2(slot2),
                            .run_en(run_en),
                            .sit_en(sit_en),
                            .sbp_en(sbp_en),
                            .sof_en(sof_en),
                            .offset(offset),
                            .new_base_addr(new_base_addr),                              // Nhận address từ instruction
                            .base_addr_read_IB(base_addr_read_IB),                      // Base address read IB mới
                            .base_addr_read_KSP(base_addr_read_KSP),                    // Base address read KSP mới
                            .base_addr_write_OSP(base_addr_write_OSP),                  // Base address write OSP mới
                            .base_addr_read_OSP(base_addr_read_OSP),                    // Base address read OSP mới
                            .base_addr_write_OB(base_addr_write_OB),                    // Base address write OB mới
                            .base_addr_read_OB(base_addr_read_OB),                      // Base address read OB mới
                            .base_addr_read_BSP(base_addr_read_BSP),                    // Base address read BSP mới
                            .base_addr_write_FCSP(base_addr_write_FCSP),                // Base address write FCSP mới
                            .base_addr_read_FCSP(base_addr_read_FCSP));                 // Base address read FCSP mới
    
    
    // Tín hiệu tại bit 147 báo kết thúc hoạt động của DNN core
    assign done_DNN = instruction_read[147];
    reg start_flag;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            start_flag <= 0;            
        end
        else if(start) begin
            start_flag = 1;
        end
        else if(done_DNN) begin
            start_flag = 0;
        end
    end
    always @(negedge clk or posedge rst) begin
        if(rst) PC <= 0;
        else begin
            if(start_flag && !done_DNN) begin           
                if(select_next_PC) PC <= PC_start;
                else PC <= PC + 1;
            end
            else begin
                PC <= 0;
            end
            
        end
    end
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_FCSP;
//    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB;
//    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OB;
    wire n_active;
    agu #(.SCRATCHPAD_SIZE(SCRATCHPAD_SIZE)) agu_block(
                        .clk(clk),
                        .rst(rst),
                        .run_en(run_en),                                    // tín hiệu cho agu hoạt động
                        .sit_en(sit_en),                                    // tín hiệu thiết lập số vòng lặp
                        .sbp_en(sbp_en),                                    // tín hiệu thiết lập breakpoint
                        .sof_en(sof_en),                                    // tín hiệu thiết lập offset (flags để xác định địa chỉ nào thay đổi)
                        .offset(offset),                                    // giá trị gán vào (breakpoint/flags/iterations)
                        .PC(PC),                                            // PC
                        .new_base_addr(new_base_addr),                      // =1 thì nhận base address mới, còn không thì nhận address cũ
                        .base_addr_read_IB(base_addr_read_IB),              // base address read IB mới
                        .base_addr_read_KSP(base_addr_read_KSP),            // base address read KSP mới
                        .base_addr_write_OSP(base_addr_write_OSP),          // base address write OSP mới
                        .base_addr_read_OSP(base_addr_read_OSP),            // base address read OSP mới
                        .base_addr_write_OB(base_addr_write_OB),            // base address write OB mới
                        .base_addr_read_OB(base_addr_read_OB),              // base address read OB mới
                        .base_addr_read_BSP(base_addr_read_BSP),            // base address read BSP
                        .base_addr_write_FCSP(base_addr_write_FCSP),        // base address write FCSP
                        .base_addr_read_FCSP(base_addr_read_FCSP),          // base address read FCSP
                        .addr_read_IB(addr_read_IB),                        // address read IB
                        .addr_read_KSP(addr_read_KSP),                      // address read KSP
                        .addr_write_OSP(addr_write_OSP),                    // address write OSP
                        .addr_read_OSP(addr_read_OSP),                      // address read OSP
                        .addr_write_OB(addr_write_OB),                      // address write OB
                        .addr_read_OB(addr_read_OB),                        // address read OB
                        .addr_read_BSP(addr_read_BSP),                      // address read BSP
                        .addr_write_FCSP(addr_write_FCSP),                  // address write FCSP
                        .addr_read_FCSP(addr_read_FCSP),                    // address read FCSP
                        .select_next_PC(select_next_PC),                    // chọn PC kế tiếp (khi có lặp thì PC tín hiệu này dùng để chọn PC kế tiếp)
                        .PC_start(PC_start),                                // PC bắt đầu thực hiện vòng lặp
                        .n_active(n_active));                               // (don't care)
    
    // Declare IB memory
    wire [DATA_WIDTH - 1 : 0] IB_read [0:BLOCKS_PER_ROW-1];
    genvar i;
    generate
        for(i = 0; i < BLOCKS_PER_ROW; i = i + 1) begin: IB_mem_array  
            memory #(.DATA_WIDTH(DATA_WIDTH),
                     .SIZE(SCRATCHPAD_SIZE),
                     .EN_OUT_FF(1)) IB(
                                .clk(!clk),
                                .wen(en_write_IB[i]),
                                .ren(1'b1),
                                .addr_w(addr_write_IB),
                                .addr_r(addr_read_IB),
                                .din(data_write),
                                .dout(IB_read[i])
             );   
        end  
    endgenerate   
//    assign IB_read_out = IB_read[select];

    // Declare KSP memory
    wire [DATA_WIDTH - 1 : 0] KSP_read [0:BLOCKS_PER_ROW-1];
    generate
        for(i = 0; i < BLOCKS_PER_ROW; i = i + 1) begin: KSP_mem_array  
            memory #(.DATA_WIDTH(DATA_WIDTH),
                     .SIZE(SCRATCHPAD_SIZE),
                     .EN_OUT_FF(1)) KSP(
                                .clk(!clk),
                                .wen(en_write_KSP[i]),
                                .ren(1'b1),
                                .addr_w(addr_write_KSP),
                                .addr_r(addr_read_KSP),
                                .din(data_write),
                                .dout(KSP_read[i])
             );   
        end  
    endgenerate   
//    assign KSP_read_out = KSP_read[select]; 
    
    // Declare FCSP mem
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_FCSP_MS;
    wire [DATA_WIDTH - 1 : 0] POFC_read;        // POFC read data
    wire [DATA_WIDTH - 1 : 0] FCSP_read;        // FCSP read data
    wire [DATA_WIDTH - 1 : 0] data_write_POFC;  // data write to POFC
//    wire en_store_FCSP;
    generate
        memory #(.DATA_WIDTH(DATA_WIDTH),
                 .SIZE(SCRATCHPAD_SIZE),
                 .EN_OUT_FF(1)) FCSP(
                            .clk(!clk),
                            .wen(en_store_FCSP),
                            .ren(1'b1),
                            .addr_w(addr_write_FCSP_MS),
                            .addr_r(addr_read_FCSP),
                            .din(POFC_read),
                            .dout(FCSP_read)
         );    
    endgenerate   
    
    // Khai báo POFC
    generate
        register POFC(.clk(!clk),
                          .rst(rst),
                          .wen(1),
                          .data_in(data_write_POFC),
                          .data_out(POFC_read));  
    endgenerate
//    assign FCSP_read_out = FCSP_read; 
    
    // Declare BSP mem
    wire [DATA_WIDTH - 1 : 0] BSP_read;     // data đọc từ BSP
    generate
        memory #(.DATA_WIDTH(DATA_WIDTH),
                 .SIZE(SCRATCHPAD_SIZE),
                 .EN_OUT_FF(1)) BSP(
                            .clk(!clk),
                            .wen(en_write_BSP),
                            .ren(1'b1),
                            .addr_w(addr_write_BSP),
                            .addr_r(addr_read_BSP),
                            .din(data_write),
                            .dout(BSP_read)
         );   
    endgenerate   
//    assign BSP_read_out = BSP_read; 
    

    
    wire [DATA_WIDTH - 1 : 0] OSP_read [0:BLOCKS_PER_ROW-1];        // data đọc từ OSP
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_MS;           // địa chỉ ghi OSP tại stage MS
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_MS_temp1;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_MS_temp2;
    assign addr_write_OSP_MS_temp1 = ~addr_write_OSP_MS;            // add thêm delay
    assign addr_write_OSP_MS_temp2 = ~addr_write_OSP_MS_temp1;      // add thêm delay
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_PL;           // địa chỉ ghi OSP tại stage PL
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_PL_temp1;     
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_PL_temp2; 
    assign addr_write_OSP_PL_temp1 = ~addr_write_OSP_PL;            // add thêm delay
    assign addr_write_OSP_PL_temp2 = ~addr_write_OSP_PL_temp1;      // add thêm delay
    wire en_store_OSP;                                              // enable store OSP
    wire [63:0] enable_OSP;
    
    // Declare OSP memory
    generate
        for(i = 0; i < BLOCKS_PER_ROW; i = i + 1) begin: OSP_mem_array  
            memory #(.DATA_WIDTH(DATA_WIDTH),
                     .SIZE(SCRATCHPAD_SIZE),
                     .EN_OUT_FF(1)) OSP(
                                .clk(!clk),
                                .wen(en_store_OSP & enable_OSP[i]),
                                .ren(1'b1),
                                .addr_w(addr_write_OSP_MS_temp2),
                                .addr_r(addr_read_OSP),
                                .din(PEOA_read[i]),
                                .dout(OSP_read[i])
             );   
        end  
    endgenerate   
//    assign OSP_read_out = OSP_read[select]; 
    
    
    // STAGE ML =============================================================================
    // Latch address accessing memory
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_FCSP_ML;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_FCSP_temp1;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_FCSP_temp2;
    assign addr_write_FCSP_temp1 = ~addr_write_FCSP;
    assign addr_write_FCSP_temp2 = ~addr_write_FCSP_temp1;
    
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_ML;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_temp1;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_temp2;
    assign addr_write_OSP_temp1 = ~addr_write_OSP;
    assign addr_write_OSP_temp2 = ~addr_write_OSP_temp1;

    
    reg [INSTRUCTION_WIDTH-1:0] instruction_stage_ML;
    wire [INSTRUCTION_WIDTH-1:0] instruction_stage_IF_temp1;
    wire [INSTRUCTION_WIDTH-1:0] instruction_stage_IF_temp2;
    assign instruction_stage_IF_temp1 = ~instruction_stage_IF;
    assign instruction_stage_IF_temp2 = ~instruction_stage_IF_temp1;

    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB_ML;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB_temp1;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB_temp2;
    assign addr_write_OB_temp1 = ~addr_write_OB;
    assign addr_write_OB_temp2 = ~addr_write_OB_temp1;

    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OB_ML;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OB_temp1;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OB_temp2;
    assign addr_read_OB_temp1 = ~addr_read_OB;
    assign addr_read_OB_temp2 = ~addr_read_OB_temp1;
    
    // thanh ghi chốt address write FCSP giữa stage IF và ML
    generate
        register #(.DATA_WIDTH($clog2(SCRATCHPAD_SIZE)))
                    IFFCSP(.clk(clk),
                         .rst(rst),
                         .wen(1),
                         .data_in(addr_write_FCSP_temp2),
                         .data_out(addr_write_FCSP_ML));
    endgenerate
    
    // thanh ghi chốt address write OSP giữa stage IF và ML
    generate
        register #(.DATA_WIDTH($clog2(SCRATCHPAD_SIZE)))
                    IFOSP(.clk(clk),
                         .rst(rst),
                         .wen(1),
                         .data_in(addr_write_OSP_temp2),
                         .data_out(addr_write_OSP_ML));
    endgenerate
    
    // thanh ghi chốt address write OB giữa stage IF và ML
    generate
        register #(.DATA_WIDTH($clog2(SCRATCHPAD_SIZE)))
                    IFOBW(.clk(clk),
                          .rst(rst),
                          .wen(1),
                          .data_in(addr_write_OB_temp2),
                          .data_out(addr_write_OB_ML));
    endgenerate
    
    // thanh ghi chốt address read OB giữa stage IF và ML
    generate
        register #(.DATA_WIDTH($clog2(SCRATCHPAD_SIZE)))
                    IFOBR(.clk(clk),
                          .rst(rst),
                          .wen(1),
                          .data_in(addr_read_OB_temp2),
                          .data_out(addr_read_OB_ML));
    endgenerate
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            instruction_stage_ML = 0;
        end
        else begin
            instruction_stage_ML = instruction_stage_IF_temp2;
        end
    end
    
    
        
    wire [10:0] slot3;
    assign slot3 = instruction_stage_ML[44:34];
    wire en_load_IB;
    wire en_load_KSP;
    wire en_load_OSP;
    wire en_load_BSP;
    wire en_load_FCSP;
    wire [7:0] sel_MLOM;
    
//    wire [DATA_WIDTH - 1 : 0]MLI_read_out;
//    wire [DATA_WIDTH - 1 : 0]MLK_read_out;
//    wire [DATA_WIDTH - 1 : 0]MLB_read_out;
//    wire [DATA_WIDTH - 1 : 0]MLFC_read_out;
//    wire [DATA_WIDTH - 1 : 0]MLO_read_out;
//    wire [DATA_WIDTH - 1 : 0]MLOM_read_out;
    
    // decoder stage ML
    decoder_stage_ML decML(
        slot3,
        en_load_IB,     // tín hiệu đọc IB
        en_load_KSP,    // tín hiệu đọc KSP
        en_load_OSP,    // tín hiệu đọc OSP
        en_load_BSP,    // tín hiệu đọc BSP
        en_load_FCSP,   // tín hiệu đọc FCSP
        sel_MLOM        // tín hiệu chọn nguồn để ghi vào MLOM
    );
    // Declare MLI register
    wire [DATA_WIDTH - 1 : 0] MLI_read [0:BLOCKS_PER_ROW-1];
    generate
        for(i = 0; i < BLOCKS_PER_ROW; i = i + 1) begin: MLI_reg_array
            register MLI(.clk(!clk),
                         .rst(rst),
                         .wen(en_load_IB),
                         .data_in(IB_read[i]),
                         .data_out(MLI_read[i]));
        end
    endgenerate
//    assign MLI_read_out = MLI_read[select];
    
    // Declare MLK register
    wire [DATA_WIDTH - 1 : 0] MLK_read [0:BLOCKS_PER_ROW-1]; 
    generate
        for(i = 0; i < BLOCKS_PER_ROW; i = i + 1) begin: MLK_reg_array
            register MLK(.clk(!clk),
                         .rst(rst),
                         .wen(en_load_KSP),
                         .data_in(KSP_read[i]),
                         .data_out(MLK_read[i]));
        end 
    endgenerate
//    assign MLK_read_out = MLK_read[select];
    
    // Declare MLB register
    wire [DATA_WIDTH - 1 : 0] MLB_read;
    generate
        register MLB(.clk(!clk),
                     .rst(rst),
                     .wen(en_load_BSP),
                     .data_in(BSP_read),
                     .data_out(MLB_read));
    endgenerate
//    assign MLB_read_out = MLB_read;
    
    // Declare MLFC register
    wire [DATA_WIDTH - 1 : 0] MLFC_read;
    generate
        register MLFC(.clk(!clk),
                     .rst(rst),
                     .wen(en_load_FCSP),
                     .data_in(FCSP_read),
                     .data_out(MLFC_read));
    endgenerate
//    assign MLFC_read_out = MLFC_read; 
    
    // Declare MLO register
    wire [DATA_WIDTH - 1 : 0] MLO_read [0:BLOCKS_PER_ROW-1]; 
    generate
        for(i = 0; i < BLOCKS_PER_ROW; i = i + 1) begin: MLO_reg_array
            register MLO(.clk(!clk),
                         .rst(rst),
                         .wen(en_load_OSP),
                         .data_in(OSP_read[i]),
                         .data_out(MLO_read[i]));
        end 
    endgenerate
//    assign MLO_read_out = MLO_read[select];
    
    // Declare MLOM register
    wire [DATA_WIDTH - 1 : 0] MLOM_in;
    assign MLOM_in = OSP_read[sel_MLOM];
    wire [DATA_WIDTH - 1 : 0] MLOM_read;
    generate
        register MLOM(.clk(!clk),
                     .rst(rst),
                     .wen(en_load_OSP),
                     .data_in(MLOM_in),
                     .data_out(MLOM_read));
    endgenerate
//    assign MLOM_read_out = MLOM_read;
    
    
    // STAGE CONV ========================================================================
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_FCSP_CONV;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_FCSP_ML_temp1;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_FCSP_ML_temp2;
    assign addr_write_FCSP_ML_temp1 = ~addr_write_FCSP_ML;
    assign addr_write_FCSP_ML_temp2 = ~addr_write_FCSP_ML_temp1;

    
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_CONV;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_ML_temp1;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_ML_temp2;
    assign addr_write_OSP_ML_temp1 = ~addr_write_OSP_ML;
    assign addr_write_OSP_ML_temp2 = ~addr_write_OSP_ML_temp1;
    
    reg [INSTRUCTION_WIDTH-1:0] instruction_stage_CONV;
    wire [INSTRUCTION_WIDTH-1:0] instruction_stage_ML_temp1;
    wire [INSTRUCTION_WIDTH-1:0] instruction_stage_ML_temp2;
    assign instruction_stage_ML_temp1 = ~instruction_stage_ML;
    assign instruction_stage_ML_temp2 = ~instruction_stage_ML_temp1;
    
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB_CONV;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB_ML_temp1;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB_ML_temp2;
    assign addr_write_OB_ML_temp1 = ~addr_write_OB_ML;
    assign addr_write_OB_ML_temp2 = ~addr_write_OB_ML_temp1;

    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OB_CONV;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OB_ML_temp1;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OB_ML_temp2;
    assign addr_read_OB_ML_temp1 = ~addr_read_OB_ML;
    assign addr_read_OB_ML_temp2 = ~addr_read_OB_ML_temp1;
    
    // thanh ghi chốt address write FCSP giữa stage ML và CONV
    generate
        register #(.DATA_WIDTH($clog2(SCRATCHPAD_SIZE)))
                    MLFCSP(.clk(clk),
                         .rst(rst),
                         .wen(1),
                         .data_in(addr_write_FCSP_ML_temp2),
                         .data_out(addr_write_FCSP_CONV));
    endgenerate 

    // thanh ghi chốt address write OSP giữa stage ML và CONV
    generate
        register #(.DATA_WIDTH($clog2(SCRATCHPAD_SIZE)))
                    MLOSP(.clk(clk),
                         .rst(rst),
                         .wen(1),
                         .data_in(addr_write_OSP_ML_temp2),
                         .data_out(addr_write_OSP_CONV));
    endgenerate
    
    // thanh ghi chốt address write OB giữa stage ML và CONV
    generate
        register #(.DATA_WIDTH($clog2(SCRATCHPAD_SIZE)))
                    MLOBW(.clk(clk),
                         .rst(rst),
                         .wen(1),
                         .data_in(addr_write_OB_ML_temp2),
                         .data_out(addr_write_OB_CONV));
    endgenerate
    
    // thanh ghi chốt address read OB giữa stage ML và CONV
    generate
        register #(.DATA_WIDTH($clog2(SCRATCHPAD_SIZE)))
                    MLOBR(.clk(clk),
                         .rst(rst),
                         .wen(1),
                         .data_in(addr_read_OB_ML_temp2),
                         .data_out(addr_read_OB_CONV));
    endgenerate
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            instruction_stage_CONV = 0;
        end
        else begin
            instruction_stage_CONV = instruction_stage_ML_temp2;
        end
    end
    
    
    wire [63:0] enable_EOA = instruction_stage_CONV[211:148]; // tín hiệu để chọn EOA nào được ghi dữ liệu từ ALU
    
    wire [5:0]  slot4;
    assign slot4 = instruction_stage_CONV[33:28];
    
    wire [1:0] src_mult_1;
    wire src_mult_2;
    wire [1:0] src_acc;
    wire src_add_bias;
    
    // Khai báo decoder stage CONV
    decoder_stage_Conv decConv(
                            slot4,
                            src_mult_1,         // chọn toán hạng 1 cho phép nhân trong ALU
                            src_mult_2,         // chọn toán hạng 2 cho phép nhân trong ALU
                            src_acc,            // chọn toán hạng để thực hiện phép cộng tích lũy
                            src_add_bias        // chọn nguồn giá trị để cộng với bias trước khi đưa qua LUT
                            );
                            
    wire [DATA_WIDTH - 1 : 0] conv_read [BLOCKS_PER_ROW-1:0];
    wire [DATA_WIDTH - 1 : 0] EOA_read [BLOCKS_PER_ROW-1:0];
   
   // Khai báo EOA
    generate
        for(i = 0; i < BLOCKS_PER_ROW; i = i + 1) begin: conv_array
            if(i!=0)
                multiply_accumulate #(.DATA_WIDTH(DATA_WIDTH),
                                      .DECIMAL_BIT(DECIMAL_BIT))
                                      conv(.mult_sel_1(src_mult_1),
                                           .mult_sel_2(src_mult_2),
                                           .acc_sel(src_acc),
                                           .MLIout(MLI_read[i]),
                                           .MLIout_all(MLI_read[0]),
                                           .MLKout(MLK_read[i]),
                                           .MLOout(MLO_read[i]),
                                           .EOAout(EOA_read[i]),
                                           .SEOAout(EOA_read[i-1]),
                                           .acc_result(conv_read[i])
                                           );
            else   
                multiply_accumulate #(.DATA_WIDTH(DATA_WIDTH),
                                          .DECIMAL_BIT(DECIMAL_BIT))
                                          conv(.mult_sel_1(src_mult_1),
                                               .mult_sel_2(src_mult_2),
                                               .acc_sel(src_acc),
                                               .MLIout(MLI_read[i]),
                                               .MLIout_all(MLI_read[0]),
                                               .MLKout(MLK_read[i]),
                                               .MLOout(MLO_read[i]),
                                               .EOAout(EOA_read[i]),
                                               .SEOAout('b0),
                                               .acc_result(conv_read[i])
                                               );                           
        end
        for(i = 0; i < BLOCKS_PER_ROW; i = i + 1) begin: EOA_reg_array
            register EOA(.clk(!clk),
                         .rst(rst),
                         .wen(enable_EOA[i]),
                         .data_in(conv_read[i]),
                         .data_out(EOA_read[i]));
        end    
    endgenerate
//    assign EOA_read_out = EOA_read[select];  
        
    wire [DATA_WIDTH - 1 : 0] data_write_LUT;
    wire [DATA_WIDTH - 1 : 0] data_add_bias;
    assign data_add_bias = (src_add_bias == 0) ? MLOM_read : MLFC_read;
    assign data_write_LUT = data_add_bias + MLB_read;
    
    wire [DATA_WIDTH*2 - 1 : 0] lut0_coordinate_0;         
    wire [DATA_WIDTH*2 - 1 : 0] lut0_coordinate_1;         
    wire [DATA_WIDTH - 1 : 0] lut0_data_out;              
    
    wire [DATA_WIDTH*2 - 1 : 0] lut1_coordinate_0;         
    wire [DATA_WIDTH*2 - 1 : 0] lut1_coordinate_1;         
    wire [DATA_WIDTH - 1 : 0] lut1_data_out;
    
    // Khai báo lookuptable0
    generate
        lookuptable_module_0 lut0(.clk(!clk),
                                .rst(rst),
                                .data_in(data_write_LUT),
                                .coordinate_0(lut0_coordinate_0),
                                .coordinate_1(lut0_coordinate_1),
                                .data_out(lut0_data_out));
    endgenerate     
    
    // Khai báo lookuptable1                       
    generate
        lookuptable_module_1 lut1(.clk(!clk),
                                .rst(rst),
                                .data_in(data_write_LUT),
                                .coordinate_0(lut1_coordinate_0),
                                .coordinate_1(lut1_coordinate_1),
                                .data_out(lut1_data_out));
    endgenerate
    
    // STAGE NON-LINEAR ==========================================================
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_FCSP_NL;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_FCSP_CONV_temp1;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_FCSP_CONV_temp2;
    assign addr_write_FCSP_CONV_temp1 = ~addr_write_FCSP_CONV;
    assign addr_write_FCSP_CONV_temp2 = ~addr_write_FCSP_CONV_temp1;

    
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_NL;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_CONV_temp1;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_CONV_temp2;
    assign addr_write_OSP_CONV_temp1 = ~addr_write_OSP_CONV;
    assign addr_write_OSP_CONV_temp2 = ~addr_write_OSP_CONV_temp1;
    
    reg [INSTRUCTION_WIDTH-1:0] instruction_stage_NL;
    wire [INSTRUCTION_WIDTH-1:0] instruction_stage_CONV_temp1;
    wire [INSTRUCTION_WIDTH-1:0] instruction_stage_CONV_temp2;
    assign instruction_stage_CONV_temp1 = ~instruction_stage_CONV;
    assign instruction_stage_CONV_temp2 = ~instruction_stage_CONV_temp1;
    
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB_NL;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB_CONV_temp1;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB_CONV_temp2;
    assign addr_write_OB_CONV_temp1 = ~addr_write_OB_CONV;
    assign addr_write_OB_CONV_temp2 = ~addr_write_OB_CONV_temp1;

    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OB_NL;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OB_CONV_temp1;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OB_CONV_temp2;
    assign addr_read_OB_CONV_temp1 = ~addr_read_OB_CONV;
    assign addr_read_OB_CONV_temp2 = ~addr_read_OB_CONV_temp1;
    
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            instruction_stage_NL = 0;
        end
        else begin
            instruction_stage_NL = instruction_stage_CONV_temp2;
        end
    end
    
    // thanh ghi chốt address write FCSP giữa stage CONV và NL
    generate
        register #(.DATA_WIDTH($clog2(SCRATCHPAD_SIZE)))
                    CONVFCSP(.clk(clk),
                             .rst(rst),
                             .wen(1),
                             .data_in(addr_write_FCSP_CONV_temp2),
                             .data_out(addr_write_FCSP_NL));
    endgenerate
    
    //thanh ghi chốt address write OSP giữa stage CONV và NL
    generate
        register #(.DATA_WIDTH($clog2(SCRATCHPAD_SIZE)))
                    CONVOSP(.clk(clk),
                            .rst(rst),
                            .wen(1),
                            .data_in(addr_write_OSP_CONV_temp2),
                            .data_out(addr_write_OSP_NL));
    endgenerate
   
    // thanh ghi chốt address write OB giữa stage CONV và NL
    generate
        register #(.DATA_WIDTH($clog2(SCRATCHPAD_SIZE)))
                    CONVOBW(.clk(clk),
                            .rst(rst),
                            .wen(1),
                            .data_in(addr_write_OB_CONV_temp2),
                            .data_out(addr_write_OB_NL));
    endgenerate
    
    // thanh ghi chốt address read OB giữa stage CONV và NL
    generate
        register #(.DATA_WIDTH($clog2(SCRATCHPAD_SIZE)))
                    CONVOBR(.clk(clk),
                            .rst(rst),
                            .wen(1),
                            .data_in(addr_read_OB_CONV_temp2),
                            .data_out(addr_read_OB_NL));
    endgenerate
    
    wire [8:0]  slot5;
    assign slot5 = instruction_stage_NL[27:19];

//    wire sel_lut;
    wire [7:0] sel_NOA;
    
    // Khai báo decoder stage NL
    decoder_stage_NL decNL(slot5,
                           sel_lut,     // chọn lookuptable
                           sel_NOA      // chọn data ghi vào NOA
                           );
    
    
    wire [DATA_WIDTH - 1 : 0] NEOA_read [BLOCKS_PER_ROW-1:0];

    // Khai báo thanh ghi NEOA
    generate
        for(i = 0; i < BLOCKS_PER_ROW; i = i + 1) begin: NEOA_reg_array
            register NEOA(.clk(!clk),
                         .rst(rst),
                         .wen(1'b1),
                         .data_in(EOA_read[i]),
                         .data_out(NEOA_read[i]));
        end    
    endgenerate
    assign NEOA_read_out = NEOA_read[select];
    
    wire [DATA_WIDTH - 1 : 0] data_write_NOA;
    assign data_write_NOA = EOA_read[sel_NOA];
    
    wire [DATA_WIDTH - 1 : 0] NOA_read;    
    // Khai báo thanh ghi NOA
    generate
        register NOA(.clk(!clk),
                     .rst(rst),
                     .wen(1),
                     .data_in(data_write_NOA),
                     .data_out(NOA_read));
    endgenerate   
//    assign NOA_read_out = NOA_read; 
    
    wire [DATA_WIDTH*2 - 1 : 0] lut_coordinate_0;         
    wire [DATA_WIDTH*2 - 1 : 0] lut_coordinate_1;         
    wire [DATA_WIDTH - 1 : 0] lut_data_out;      
    
    // chọn tọa độ 0 giữa lookuptable0 hoặc lookuptable1
    assign lut_coordinate_0 = (sel_lut == 0)? lut0_coordinate_0 : lut1_coordinate_0;
    // chọn tọa độ 1 giữa lookuptable0 hoặc lookuptable1
    assign lut_coordinate_1 = (sel_lut == 0)? lut0_coordinate_1 : lut1_coordinate_1;
    // chọn data out từ lookuptable0 hoặc lookuptable1
    assign lut_data_out = (sel_lut == 0)? lut0_data_out : lut1_data_out;
    
 
    LI #(.DATA_WIDTH(DATA_WIDTH),
         .DECIMAL_BIT(DECIMAL_BIT)
        ) linear_interpolation(
            .x(lut_data_out), 
            .x1(lut_coordinate_0[31:16]),      
            .y1(lut_coordinate_0[15:0]),      
            .x2(lut_coordinate_1[31:16]),      
            .y2(lut_coordinate_1[15:0]),      
            .y(li_data_out)     
            );
    wire [DATA_WIDTH - 1 : 0] NOL_read;    
    generate
        register NOL(.clk(!clk),
                     .rst(rst),
                     .wen(1),
                     .data_in(li_data_out),
                     .data_out(NOL_read));
    endgenerate   

    reg signed [DATA_WIDTH - 1 : 0] temp_sum;
    wire [DATA_WIDTH - 1 : 0] data_write_NFC;
    wire [DATA_WIDTH - 1 : 0] NFC_read;
    integer k;
    always @(*) begin
        temp_sum = 0;
        for (k = 0; k < BLOCKS_PER_ROW; k = k + 1) begin
            temp_sum = temp_sum + EOA_read[k];
        end
    end
    assign data_write_NFC = temp_sum;
    
    // Khai báo thanh ghi NFC
    register NFC  (.clk(!clk),
                   .rst(rst),
                   .wen(1),
                   .data_in(data_write_NFC),
                   .data_out(NFC_read));
//    assign NFC_read_out = NFC_read[select];
    
    
    // STAGE POOLING =====================================================================
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_FCSP_PL;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_FCSP_NL_temp1;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_FCSP_NL_temp2;
    assign addr_write_FCSP_NL_temp1 = ~addr_write_FCSP_NL;
    assign addr_write_FCSP_NL_temp2 = ~addr_write_FCSP_NL_temp1;

    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_PL;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_NL_temp1;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_NL_temp2;
    assign addr_write_OSP_NL_temp1 = ~addr_write_OSP_NL;
    assign addr_write_OSP_NL_temp2 = ~addr_write_OSP_NL_temp1;
    
    reg [INSTRUCTION_WIDTH-1:0] instruction_stage_PL;
    wire [INSTRUCTION_WIDTH-1:0] instruction_stage_NL_temp1;
    wire [INSTRUCTION_WIDTH-1:0] instruction_stage_NL_temp2;
    assign instruction_stage_NL_temp1 = ~instruction_stage_NL;
    assign instruction_stage_NL_temp2 = ~instruction_stage_NL_temp1;

    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB_PL;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB_NL_temp1;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB_NL_temp2;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB_NL_temp3;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB_NL_temp4;

    assign addr_write_OB_NL_temp1 = ~addr_write_OB_NL;
    assign addr_write_OB_NL_temp2 = ~addr_write_OB_NL_temp1;
    assign addr_write_OB_NL_temp3 = ~addr_write_OB_NL_temp2;
    assign addr_write_OB_NL_temp4 = ~addr_write_OB_NL_temp3;
    
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OB_PL;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OB_NL_temp1;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OB_NL_temp2;
    assign addr_read_OB_NL_temp1 = ~addr_read_OB_NL;
    assign addr_read_OB_NL_temp2 = ~addr_read_OB_NL_temp1;
    
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            instruction_stage_PL = 0;
        end
        else begin
            instruction_stage_PL = instruction_stage_NL_temp2;
        end
    end
    
    // Khai báo thanh ghi chốt address write FCSP giữa stage NL và PL
    generate
        register #(.DATA_WIDTH($clog2(SCRATCHPAD_SIZE)))
                    NLFCSP(.clk(clk),
                           .rst(rst),
                           .wen(1),
                           .data_in(addr_write_FCSP_NL_temp2),
                           .data_out(addr_write_FCSP_PL));
    endgenerate
    
    // Khai báo thanh ghi chốt adderss write OSP giữa stage NL và PL
    generate
        register #(.DATA_WIDTH($clog2(SCRATCHPAD_SIZE)))
                    NLOSP(.clk(clk),
                         .rst(rst),
                         .wen(1),
                         .data_in(addr_write_OSP_NL_temp2),
                         .data_out(addr_write_OSP_PL));
    endgenerate
    
    // Khai báo thanh ghi chốt address write OB giữa stage NL và PL
    generate
        register #(.DATA_WIDTH($clog2(SCRATCHPAD_SIZE)))
                    NLOBW(.clk(clk),
                          .rst(rst),
                          .wen(1),
                          .data_in(addr_write_OB_NL_temp2),
                          .data_out(addr_write_OB_PL));
    endgenerate
    
    // Khai báo thanh ghi chốt address read OB giữa stage NL và PL
    generate
        register #(.DATA_WIDTH($clog2(SCRATCHPAD_SIZE)))
                    NLOBR(.clk(clk),
                          .rst(rst),
                          .wen(1),
                          .data_in(addr_read_OB_NL_temp2),
                          .data_out(addr_read_OB_PL));
    endgenerate
    
    wire [11:0]  slot6;
    assign slot6 = instruction_stage_PL[18:7];
    
    wire [2:0] src_max; 
    wire [7:0] sel_POA; 
    wire sel_adder; 
    
    // Khai báo decoder stage PL
    decoder_stage_PL decPL(slot6, src_max, sel_POA, sel_adder);
    
    // Declare PEOA register
    wire [DATA_WIDTH - 1 : 0] PEOA_read [BLOCKS_PER_ROW-1:0];
    wire [DATA_WIDTH - 1 : 0] PEOA_read_temp1 [BLOCKS_PER_ROW-1:0]; 
    wire [DATA_WIDTH - 1 : 0] PEOA_read_temp2 [BLOCKS_PER_ROW-1:0]; 

    // Khai báo thanh ghi PEOA
    generate
        for(i = 0; i < BLOCKS_PER_ROW; i = i + 1) begin: PEOA_reg_array
            if(i != 0)
                register PEOA(.clk(!clk),
                             .rst(rst),
                             .wen(1'b1),
                             .data_in(NEOA_read[i-1]),
                             .data_out(PEOA_read[i]));
            else 
                register PEOA(.clk(!clk),
                                 .rst(rst),
                                 .wen(1'b1),
                                 .data_in('b0),
                                 .data_out(PEOA_read[i]));
        end                     
    endgenerate
//    assign PEOA_read_out = PEOA_read[select];
    for(i = 0; i < BLOCKS_PER_ROW; i = i + 1) begin
        assign PEOA_read_temp1[i] = ~PEOA_read[i];
        assign PEOA_read_temp2[i] = ~PEOA_read_temp1[i];
    end

    
    // Declare POA register
    wire [DATA_WIDTH - 1 : 0] POA_read;
    wire [DATA_WIDTH - 1 : 0] data_write_POA;
    assign data_write_POA = NEOA_read[sel_POA];
    
    // Khai báo thanh ghi POA
    generate
        register POA(.clk(!clk),
                     .rst(rst),
                     .wen(1),
                     .data_in(data_write_POA),
                     .data_out(POA_read));
    endgenerate   
    assign POA_read_out = POA_read;
    
    // Declare POL register
    wire [DATA_WIDTH - 1 : 0] POL_read;    
    generate
        register POL(.clk(!clk),
                     .rst(rst),
                     .wen(1),
                     .data_in(NOL_read),
                     .data_out(POL_read));
    endgenerate   
//    assign POL_read_out = POL_read;
  
      // chọn kết quả ghi vào POFC
      assign data_write_POFC = (sel_adder == 0) ? NFC_read + 0:
                                                  NFC_read + POFC_read;                                                 
//    assign POFC_read_out = POFC_read;
    
    // Declare max pooling block
    wire [DATA_WIDTH - 1 : 0] max_pool_result; 
    wire [DATA_WIDTH - 1 : 0] POM_read; 
//    assign POM_read_out = POM_read;
    wire [DATA_WIDTH - 1 : 0] OB_read;
    wire [DATA_WIDTH - 1 : 0] MEM_read;
    wire [DATA_WIDTH - 1 : 0] max_operand_1;
    wire [DATA_WIDTH - 1 : 0] max_operand_2;
    // chọn toán hạng cho khối max
    assign max_operand_1 = (src_max == 0) ? 0:
                           (src_max == 1) ? NOA_read:
                           (src_max == 2) ? OB_read:
                           (src_max == 3) ? MEM_read:
                           (src_max == 4) ? POL_read:
                           (src_max == 5) ? POM_read: 'bz;
      
    assign max_operand_2 = NOL_read;
    assign max_pool_result = (max_operand_1 > max_operand_2) ? max_operand_1 : max_operand_2;
    
    // Khai báo thanh ghi POM
    generate
        register POM(.clk(!clk),
                     .rst(rst),
                     .wen(1),
                     .data_in(max_pool_result),
                     .data_out(POM_read));
    endgenerate
    
    
    // STAGE MEM STORE =============================================================
    reg [INSTRUCTION_WIDTH-1:0] instruction_stage_MS;
       
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_PL_temp1; 
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP_PL_temp2; 
    assign addr_write_OSP_PL_temp1 = ~addr_write_OSP_PL;
    assign addr_write_OSP_PL_temp2 = ~addr_write_OSP_PL_temp1;

    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_FCSP_PL_temp1; 
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_FCSP_PL_temp2; 
    assign addr_write_FCSP_PL_temp1 = ~addr_write_FCSP_PL;
    assign addr_write_FCSP_PL_temp2 = ~addr_write_FCSP_PL_temp1;

    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB_MS;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB_PL_temp1;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB_PL_temp2;
    assign addr_write_OB_PL_temp1 = ~addr_write_OB_PL;
    assign addr_write_OB_PL_temp2 = ~addr_write_OB_PL_temp1;
    
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OB_MS;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OB_PL_temp1;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OB_PL_temp2;
    assign addr_read_OB_PL_temp1 = ~addr_read_OB_PL;
    assign addr_read_OB_PL_temp2 = ~addr_read_OB_PL_temp1;

    
    // Khai báo thanh ghi chốt address write FCSP giữa stage PL và MS
    generate
        register #(.DATA_WIDTH($clog2(SCRATCHPAD_SIZE)))
                    PFCSP(.clk(clk),
                          .rst(rst),
                          .wen(1),
                          .data_in(addr_write_FCSP_PL_temp2),
                          .data_out(addr_write_FCSP_MS));
    endgenerate
    
    // Khai báo thanh ghi chốt address write OSP giữa stage PL và MS
    generate
        register #(.DATA_WIDTH($clog2(SCRATCHPAD_SIZE)))
                    POSP(.clk(clk),
                         .rst(rst),
                         .wen(1),
                         .data_in(addr_write_OSP_PL_temp2),
                         .data_out(addr_write_OSP_MS));
    endgenerate
   
   // Khai báo thanh ghi chốt address write OB giữa stage PL và MS
    generate
        register #(.DATA_WIDTH($clog2(SCRATCHPAD_SIZE)))
                    POBW(.clk(clk),
                         .rst(rst),
                         .wen(1),
                         .data_in(addr_write_OB_PL_temp2),
                         .data_out(addr_write_OB_MS));
    endgenerate
   
   // Khai báo thanh ghi chốt address read OB giữa stage PL và MS
    generate
        register #(.DATA_WIDTH($clog2(SCRATCHPAD_SIZE)))
                    POBR(.clk(clk),
                         .rst(rst),
                         .wen(1),
                         .data_in(addr_read_OB_PL_temp2),
                         .data_out(addr_read_OB_MS));
    endgenerate
       
    wire [6:0]  slot7;
    assign slot7 = instruction_stage_MS[6:0];
    assign slot7_forward = instruction_stage_PL[6:0];

    // Do cách hoạt động của DNN core, khi tại ALU[i] thực hiện thì sẽ lưu data tại OSP[i+1]
    // nên giả sử ta có 9 ALU với index từ 0->8, ta sử dụng 3 ALU đầu tiên (0->2) thì gán
    // tín hiệu en_write EOA là 9'b000_000_111 và en_write OSP là 9'b000_001_110 
    assign enable_OSP = (instruction_stage_MS[211:148]) << 1;       //sử dụng tín hiệu enable write EOA, dịch trái 1 bit và gán vào enable write OSP
    wire en_store_OB;           // enable write OB
//    wire en_store_OB_fw;

//    wire en_store_OSP;
    wire en_store_FCSP;         // enable write FCSP
    wire [1:0] src_store_OB;        // chọn nguồn data để lưu vào OB
    wire [1:0] src_store_MEM;       // chọn nguồn data để lưu vào thanh ghi MEM
    decoder_stage_MS decMS(slot7,en_store_OB,en_store_OSP,en_store_FCSP,src_store_OB,src_store_MEM);            // decoder stage MS
//    decoder_stage_MS decMS_fw(slot7,en_store_OB_fw);
    assign addr_write_OSP_CONV_out = addr_write_OSP_CONV;               
    assign addr_write_OSP_ML_out = addr_write_OSP_ML;
    assign addr_write_FCSP_CONV_out = addr_write_FCSP_CONV;
    assign addr_write_FCSP_ML_out = addr_write_FCSP_ML;
    
    assign addr_write_OB_ML_out = addr_write_OB_ML;
    assign addr_write_OB_CONV_out = addr_write_OB_CONV;
    assign addr_read_OB_ML_out = addr_read_OB_ML;
    assign addr_read_OB_CONV_out = addr_read_OB_CONV;

    wire [DATA_WIDTH - 1 : 0] data_write_OB;
    wire [DATA_WIDTH - 1 : 0] data_write_MEM;
    // Chọn source ghi vào OB
    assign data_write_OB = (src_store_OB == 0) ? POFC_read :
                           (src_store_OB == 1) ? POA_read :
                           (src_store_OB == 2) ? POM_read : POL_read;
                           
    // Chọn source ghi vào MEM
    assign data_write_MEM = (src_store_MEM == 0) ? POA_read :
                            (src_store_MEM == 1) ? POM_read :
                            (src_store_MEM == 2) ? POL_read : 'bz;
    
    // Declare OB memory (dùng nội bộ trong DNN core)
    generate
        memory #(.DATA_WIDTH(DATA_WIDTH),
                 .SIZE(SCRATCHPAD_SIZE),
                 .EN_OUT_FF(0)) OB(
                            .clk(!clk),
                            .wen(en_store_OB),
                            .ren(1'b1),
                            .addr_w(addr_write_OB_MS),
                            .addr_r(addr_read_OB_NL),
                            .din(data_write_OB),
                            .dout(OB_read)
         );    
    endgenerate
    assign OB_read_out = OB_read;
    
    
    // generate OB communicate with MC (tương tự như OB, nhưng output được kết nối với Controller)
    generate
        memory #(.DATA_WIDTH(DATA_WIDTH),
                 .SIZE(SCRATCHPAD_SIZE),
                 .EN_OUT_FF(1)) OB_MC(
                            .clk(!clk),
                            .wen(en_store_OB),
                            .ren(en_MC_read_OB),
                            .addr_w(addr_write_OB_MS),
                            .addr_r(addr_MC_read_OB),
                            .din(data_write_OB),
                            .dout(data_MC_read_OB)
         );    
    endgenerate
    
    // Declare MEM register
    generate
        register MEM(.clk(!clk),
                     .rst(rst),
                     .wen(1),
                     .data_in(data_write_MEM),
                     .data_out(MEM_read));
    endgenerate
    assign MEM_read_out = MEM_read;
    
endmodule





//=====================================================================================================
// module decode slot1 and slot2 of instruction
module decoder_stage_IF #(
    parameter SCRATCHPAD_SIZE = 256
)(
    input wire [10:0] slot1,
    input wire [90:0] slot2,
    output reg run_en,
    output reg sit_en,
    output reg sbp_en,
    output reg sof_en, 
    output reg [8:0] offset,
    output reg new_base_addr,
    output reg [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_read_IB,
    output reg [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_read_KSP,
    output reg [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_write_OSP,
    output reg [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_read_OSP,
    output reg [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_write_OB,
    output reg [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_read_OB,
    output reg [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_read_BSP,
    output reg [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_write_FCSP,
    output reg [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_read_FCSP
);
    // decode slot 1
    always @(*) begin
        case(slot1[10:9])
            2'b00: begin
                run_en = 1; sit_en = 0; sbp_en = 0; sof_en = 0;
            end
            2'b01: begin
                run_en = 0; sit_en = 0; sbp_en = 1; sof_en = 0;
            end
            2'b10: begin
                run_en = 0; sit_en = 0; sbp_en = 0; sof_en = 1;
            end
            2'b11: begin
                run_en = 0; sit_en = 1; sbp_en = 0; sof_en = 0;
            end
        endcase
        
        offset <= slot1[8:0];
    end
    
    // decode slot 2
    always @(*) begin
        new_base_addr <= slot2[90];
        base_addr_read_IB = slot2[89:80];
        base_addr_read_KSP = slot2[79:70];
        base_addr_write_OSP = slot2[69:60];
        base_addr_read_OSP = slot2[59:50];
        base_addr_write_OB = slot2[49:40];
        base_addr_read_OB = slot2[39:30];
        base_addr_read_BSP = slot2[29:20];
        base_addr_write_FCSP = slot2[19:10];
        base_addr_read_FCSP = slot2[9:0];
    end 
endmodule


// module decode slot3 of instruction
module decoder_stage_ML #(
    parameter MLD0 = 3'b000,        // no load
    parameter MLD1 = 3'b001,        // load from IB
    parameter MLD2 = 3'b010,        // load from IB, KSP
    parameter MLD3 = 3'b011,        // load from IB, OSP
    parameter MLD4 = 3'b100,        // load from IB, KSP, OSP
    parameter MLD5 = 3'b101,        // load from OSP, BSP
    parameter MLD6 = 3'b110,        // load from FCSP, BSP
    parameter MLD7 = 3'b111         // load from FCSP, BSP, OSP
)(
    input wire [10:0] slot3,
    output reg en_load_IB,
    output reg en_load_KSP,
    output reg en_load_OSP,
    output reg en_load_BSP,
    output reg en_load_FCSP,
    output wire [7:0] sel_MLOM
);
    always @(*) begin
        case(slot3[10:8])
            MLD0: begin     // not load
                en_load_IB = 0; en_load_KSP = 0; en_load_OSP = 0; en_load_BSP = 0; en_load_FCSP = 0;
            end
            MLD1: begin     // load IB
                en_load_IB = 1; en_load_KSP = 0; en_load_OSP = 0; en_load_BSP = 0; en_load_FCSP = 0;
            end
            MLD2: begin     // load IB, KSP
                en_load_IB = 1; en_load_KSP = 1; en_load_OSP = 0; en_load_BSP = 0; en_load_FCSP = 0;
            end
            MLD3: begin     // load IB, OSP
                en_load_IB = 1; en_load_KSP = 0; en_load_OSP = 1; en_load_BSP = 0; en_load_FCSP = 0;
            end
            MLD4: begin     // load IB, KSP, OSP
                en_load_IB = 1; en_load_KSP = 1; en_load_OSP = 1; en_load_BSP = 0; en_load_FCSP = 0;
            end
            MLD5: begin     // load OSP, BSP
                en_load_IB = 0; en_load_KSP = 0; en_load_OSP = 1; en_load_BSP = 1; en_load_FCSP = 0;
            end
            MLD6: begin     // load BSP, FCSP
                en_load_IB = 0; en_load_KSP = 0; en_load_OSP = 0; en_load_BSP = 1; en_load_FCSP = 1;
            end
            MLD7: begin     // load OSP, BSP, FCSP
                en_load_IB = 0; en_load_KSP = 0; en_load_OSP = 1; en_load_BSP = 1; en_load_FCSP = 1;
            end
        endcase   
    end
    assign sel_MLOM = slot3[7:0];
    
endmodule


// module decode slot4 of instruction
module decoder_stage_Conv(
    input wire [5:0] slot4,
    output wire [1:0] src_mult_1,
    output wire src_mult_2,
    output wire [1:0] src_acc,              // select between MLOM and MLFC
    output wire src_add_bias
);
    assign src_mult_1   = slot4[5:4];
    assign src_mult_2   = slot4[3];
    assign src_acc      = slot4[2:1];
    assign src_add_bias = slot4[0];
endmodule

// module decode slot5 of instruction
module decoder_stage_NL(
    input wire [8:0] slot5,
    output wire sel_lut,
    output wire [7:0] sel_NOA
);
    assign sel_lut   = slot5[8];
    assign sel_NOA  = slot5[7:0];
endmodule


// module decode slot6 of instruction
module decoder_stage_PL(
    input wire [11:0] slot6,
    output wire [2:0] src_max,
    output wire [7:0] sel_POA,
    output wire sel_adder
);
    assign src_max      = slot6[11:9];
    assign sel_POA      = slot6[8:1];
    assign sel_adder    = slot6[0];
endmodule



// module decode slot7 of instruction
module decoder_stage_MS #(
    parameter MST0 = 0,             // No store
    parameter MST1 = 1,             // Store OB
    parameter MST2 = 2,             // Store OSP  
    parameter MST3 = 3,             // Store FCSP         
    parameter MST4 = 4,             // Store OB, OSP    
    parameter MST5 = 5,             // Store OB, FCSP      
    parameter MST6 = 6,             // Store OSP, FCSP   
    parameter MST7 = 7              // Store OB, OSP, FCSP      
)(
    input wire [6:0] slot7,
    output reg en_store_OB,
    output reg en_store_OSP,
    output reg en_store_FCSP,
    output wire [1:0] src_store_OB,
    output wire [1:0] src_store_MEM
);
    always @(*) begin
        case(slot7[6:4])
            MST0: begin
                en_store_OB = 0; en_store_OSP = 0; en_store_FCSP = 0;
            end
            MST1: begin
                en_store_OB = 1; en_store_OSP = 0; en_store_FCSP = 0;
            end
            MST2: begin
                en_store_OB = 0; en_store_OSP = 1; en_store_FCSP = 0;
            end
            MST3: begin
                en_store_OB = 0; en_store_OSP = 0; en_store_FCSP = 1;
            end
            MST4: begin
                en_store_OB = 1; en_store_OSP = 1; en_store_FCSP = 0;
            end
            MST5: begin
                en_store_OB = 1; en_store_OSP = 0; en_store_FCSP = 1;
            end
            MST6: begin
                en_store_OB = 0; en_store_OSP = 1; en_store_FCSP = 1;
            end
            MST7: begin
                en_store_OB = 1; en_store_OSP = 1; en_store_FCSP = 1;
            end
        endcase
    end
    
    assign src_store_OB = slot7[3:2];
    assign src_store_MEM = slot7[1:0];

endmodule


