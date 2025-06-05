`timescale 1ns / 1ps


// Slot 1 of the long instruction
// opcode(2) - offset(iteration/pc_loop/flag)(9)

// Slot 2 of the long instruction
//opcode (1) - (=1 if load new address)
//base_addr_read_IB     (8)
//base_addr_read_KSP    (8)
//base_addr_write_OSP   (8)
//base_addr_read_OSP    (8)
//base_addr_write_OB    (8)
//base_addr_read_OB     (8)
//base_addr_read_BSP    (8)
//base_addr_write_FCSP  (8)
//base_addr_read_FCSP   (8)

// Manual
// Step 1: Set break point (sbp)
// Step 2: Set offset (sof)
// Step 3: Set iteration (sit)
// Step 4: Run

module agu #(
    parameter SCRATCHPAD_SIZE = 64
)(
    // INPUT
    input wire clk,
    input wire rst,
    input wire run_en,
    input wire sit_en,
    input wire sbp_en,
    input wire sof_en,
    input wire [8:0] offset,
    input wire [8:0] PC,
    
    input wire new_base_addr,
    input wire [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_read_IB,
    input wire [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_read_KSP,
    input wire [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_write_OSP,
    input wire [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_read_OSP,
    input wire [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_write_OB,
    input wire [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_read_OB,
    input wire [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_read_BSP,
    input wire [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_write_FCSP,
    input wire [$clog2(SCRATCHPAD_SIZE)-1:0] base_addr_read_FCSP,
    
    // OUTPUT
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_IB,
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_KSP,
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OSP,
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OSP,
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_OB,
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_OB,
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_BSP,
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write_FCSP,
    output wire [$clog2(SCRATCHPAD_SIZE)-1:0] addr_read_FCSP,
    
    output reg select_next_PC,
    output wire [8:0] PC_start,
    output reg n_active
);
    
    reg [$clog2(SCRATCHPAD_SIZE)-1:0] IB_read_reg;
    reg [$clog2(SCRATCHPAD_SIZE)-1:0] KSP_read_reg;
    reg [$clog2(SCRATCHPAD_SIZE)-1:0] OSP_write_reg;
    reg [$clog2(SCRATCHPAD_SIZE)-1:0] OSP_read_reg;
    reg [$clog2(SCRATCHPAD_SIZE)-1:0] OB_write_reg;
    reg [$clog2(SCRATCHPAD_SIZE)-1:0] OB_read_reg;
    reg [$clog2(SCRATCHPAD_SIZE)-1:0] BSP_read_reg;
    reg [$clog2(SCRATCHPAD_SIZE)-1:0] FCSP_write_reg;
    reg [$clog2(SCRATCHPAD_SIZE)-1:0] FCSP_read_reg;
    
    reg [8:0] flag;
    reg [8:0] iteration;
    reg [8:0] pc_loop;
    reg [8:0] pc_start;
    wire not_equal_signal;
    wire [8:0] select;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] new_address_read_IB;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] new_address_read_KSP;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] new_address_write_OSP;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] new_address_read_OSP;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] new_address_write_OB;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] new_address_read_OB;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] new_address_read_BSP;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] new_address_write_FCSP;
    wire [$clog2(SCRATCHPAD_SIZE)-1:0] new_address_read_FCSP;
    wire enable_counter;
    assign addr_read_IB = IB_read_reg;
    assign addr_read_KSP = KSP_read_reg;
    assign addr_write_OSP = OSP_write_reg;
    assign addr_read_OSP = OSP_read_reg;
    assign addr_write_OB = OB_write_reg;
    assign addr_read_OB = OB_read_reg;
    assign addr_read_BSP = BSP_read_reg;
    assign addr_write_FCSP = FCSP_write_reg;
    assign addr_read_FCSP = FCSP_read_reg;
//    reg [7:0] bufadd;
    reg iter_end;
    reg not_add_new;
    reg [7:0] add_buf;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            flag <= 0;
            pc_loop <= 0;
            iteration <= 0;
            pc_start <= 0;
            not_add_new <= 0;
//            iter_end <= 0;
            add_buf <= 0;
            n_active <= 0;
            iter_end = 0;
        end
        
        else if(iteration == 0 && (PC == pc_loop)) add_buf = 0;

        
        // set flag
        else if(sof_en) begin
            flag <= offset; 
            n_active <= 1;
        end
        // turn off flag when finish counting
        else if(run_en && not_equal_signal == 0) begin
            flag <= 0; //reset after finishing loop
            n_active <= 1;
        end
        // set pc loop
        else if(sbp_en) begin
            pc_start <= PC + 3;
            pc_loop <= PC + 3 + offset; 
            n_active <= 1;
        end
        // set iteration
        else if(sit_en) begin
            iteration <= offset; 
            n_active <= 1;
        end
        // run counter
        else if(run_en) 
            if(pc_loop - 2 == PC) n_active <= 1;
//            else n_active = 0;
            
            else begin            
                n_active <= 0;
                if(iteration > 0 && reach_bp) begin
                    iteration = iteration - 1; 
                    add_buf = add_buf + 1;
                    not_add_new = 1;
//                    if(iteration == 0 && !n_active) iter_end = 1;
//                    else if(iteration == 0 && n_active) iter_end = 0;
                end
                else if(iteration == 0) begin
                    not_add_new = 0;
//                    add_buf = 0;
                end
            end
            
        else n_active = 0;
    end
//    always @(posedge clk or posedge rst) begin
//        if(rst) iter_end = 0;
//        else begin
//            if(iteration == 0 && (PC == pc_loop)) iter_end = 1;
//            else iter_end = 0;
//        end
//    end
    // compare (Not equal block)
    compare_not_equal_0 cmp(.value(iteration), .not_equal_signal(not_equal_signal)); 
    
    
    // create select offset signal for adder
    assign select = flag & {9{not_equal_signal}};
    
    // select source to write address register
    adder #(.SCRATCHPAD_SIZE(SCRATCHPAD_SIZE)) a0(IB_read_reg   , base_addr_read_IB   , new_base_addr, select[0], new_address_read_IB   , reach_bp, not_add_new, iter_end, add_buf);
    adder #(.SCRATCHPAD_SIZE(SCRATCHPAD_SIZE)) a1(KSP_read_reg  , base_addr_read_KSP  , new_base_addr, select[1], new_address_read_KSP  , reach_bp, not_add_new, iter_end, add_buf);
    adder #(.SCRATCHPAD_SIZE(SCRATCHPAD_SIZE)) a2(OSP_write_reg , base_addr_write_OSP , new_base_addr, select[2], new_address_write_OSP , reach_bp, not_add_new, iter_end, add_buf);
    adder #(.SCRATCHPAD_SIZE(SCRATCHPAD_SIZE)) a3(OSP_read_reg  , base_addr_read_OSP  , new_base_addr, select[3], new_address_read_OSP  , reach_bp, not_add_new, iter_end, add_buf);
    adder #(.SCRATCHPAD_SIZE(SCRATCHPAD_SIZE)) a4(OB_write_reg  , base_addr_write_OB  , new_base_addr, select[4], new_address_write_OB  , reach_bp, not_add_new, iter_end, add_buf);
    adder #(.SCRATCHPAD_SIZE(SCRATCHPAD_SIZE)) a5(OB_read_reg   , base_addr_read_OB   , new_base_addr, select[5], new_address_read_OB   , reach_bp, not_add_new, iter_end, add_buf);
    adder #(.SCRATCHPAD_SIZE(SCRATCHPAD_SIZE)) a6(BSP_read_reg  , base_addr_read_BSP  , new_base_addr, select[6], new_address_read_BSP  , reach_bp, not_add_new, iter_end, add_buf);
    adder #(.SCRATCHPAD_SIZE(SCRATCHPAD_SIZE)) a7(FCSP_write_reg, base_addr_write_FCSP, new_base_addr, select[7], new_address_write_FCSP, reach_bp, not_add_new, iter_end, add_buf);
    adder #(.SCRATCHPAD_SIZE(SCRATCHPAD_SIZE)) a8(FCSP_read_reg , base_addr_read_FCSP , new_base_addr, select[8], new_address_read_FCSP , reach_bp, not_add_new, iter_end, add_buf);
    
//    wire [$clog2(SCRATCHPAD_SIZE)-1:0] new_address_write_OSP_temp1;
//    wire [$clog2(SCRATCHPAD_SIZE)-1:0] new_address_write_OSP_temp2;
//    assign new_address_write_OSP_temp1 = ~new_address_write_OSP;
//    assign new_address_write_OSP_temp2 = ~new_address_write_OSP_temp1;
    // Store addition result into register
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            IB_read_reg = 0;
            KSP_read_reg = 0;
            OSP_write_reg = 0;
            OSP_read_reg = 0;
            OB_write_reg = 0;
            OB_read_reg = 0;
            BSP_read_reg = 0;
            FCSP_write_reg = 0;
            FCSP_read_reg = 0;
        end
        else begin
            IB_read_reg = new_address_read_IB;
            KSP_read_reg = new_address_read_KSP;
            OSP_write_reg = new_address_write_OSP;
            OSP_read_reg = new_address_read_OSP;
            OB_write_reg = new_address_write_OB;
            OB_read_reg = new_address_read_OB;
            BSP_read_reg = new_address_read_BSP;
            FCSP_write_reg = new_address_write_FCSP;
            FCSP_read_reg = new_address_read_FCSP;
        end
    end
    
    // Create select PC signal
    // If select_next_PC = 0 (counter was not set) -> PC = PC + 1
    // If select_next_PC = 1 (counter was set) PC = PC_loop
    assign PC_start = pc_start; 

    assign reach_bp = (pc_loop - 1  == PC && iteration != 0) ? 1 : 0;
//    assign select_next_PC = (reach_bp == 0)? 0 : 1;
    always @(posedge clk or posedge rst) begin
        if(rst) select_next_PC = 1;
        else if(reach_bp == 0 | iteration == 0) select_next_PC = 0;
        else select_next_PC = 1;
    end
    
endmodule

//==============================================================================
module adder #(
    parameter SCRATCHPAD_SIZE = 64
)(
    input wire [$clog2(SCRATCHPAD_SIZE)-1:0] current_address,   //Current address stored in register
    input wire [$clog2(SCRATCHPAD_SIZE)-1:0] new_address,       //Base address users want to write
    input wire sl_addr,
    input wire sl_offset,
    output [$clog2(SCRATCHPAD_SIZE)-1:0] addr_write,
    input wire reach_bp,
    input wire not_add_new,
    input wire iter_end,
    input wire [7:0] add_buf
);
    reg [$clog2(SCRATCHPAD_SIZE)-1:0] addr;
    always @(*) begin
        if(sl_addr == 0) addr = current_address;
        else addr = new_address;        
    end
    assign addr_write = (iter_end == 1) ? 0 : (sl_offset) ? addr + add_buf : addr; 
endmodule

//==============================================================================


module compare_not_equal_0(
    input wire [8:0] value,
    output reg not_equal_signal
);
    always @(*) begin
        if(value != 0) not_equal_signal = 1;
        else not_equal_signal = 0;
    end
endmodule

