`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/07/2025 07:23:58 PM
// Design Name: 
// Module Name: MODEcontroller
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


module MODEcontroller #(
    parameter is_sub      = 0,
    parameter connections = 1
)(
    input  wire        clk,
    input  wire [4:0]  opcode,
    input  wire        MLD,
    input  wire        MSD,
    input  wire        SCD,
    input  wire        Start,
    input  wire        VSync_in,
    output reg  [2:0]  state,      // Gi?m xu?ng 3 bit (c�n 8 state: 0..7)
    output reg         HSync_out,
    output reg         VSync_out,
    output reg         MACG_en,
    output reg         MCMem_en,
    output reg         ALU_en
);
    reg [2:0] next_state;
    reg [$clog2(connections) - 1 : 0] count_vsync;
    initial begin
        state      = 3'd0;
        next_state = 3'd0;
        count_vsync = 0;
    end
    always @(posedge clk) begin
        state <= next_state;
    end
    always @(posedge clk) begin
        if (state == 3'd6 && is_sub == 0) begin
            if (VSync_in) begin
                count_vsync <= count_vsync + 1;
            end
        end else begin
            count_vsync <= 0;
        end
    end
    always @(*) begin
        case (state)
        3'd0: begin
            if      (opcode == 5'd19)   next_state = 3'd6; 
            else if (opcode == 5'd20)   next_state = 3'd7;
            else if (Start)             next_state = 3'd1;
            else                        next_state = 3'd0;
        end
        3'd1: begin
            if      (opcode == 5'd18)   next_state = 3'd2;
            else if (opcode == 5'd19)   next_state = 3'd6; 
            else if (opcode == 5'd20)   next_state = 3'd7;
            else                        next_state = 3'd1;
        end
        3'd2: begin
            if (opcode == 5'd19)        next_state = 3'd6;
            else                        next_state = 3'd3;
        end
        3'd3: begin
            if (MLD)                    next_state = 3'd4;
            else                        next_state = 3'd3;
        end
        3'd4: begin
            if (SCD)                    next_state = 3'd5;
            else                        next_state = 3'd4;
        end
        3'd5: begin
            if (MSD)                    next_state = 3'd1;
            else                        next_state = 3'd5;
        end
        3'd6: begin
            if (is_sub == 0) begin
                if (count_vsync >= connections)     next_state = 3'd1;
                else                                next_state = 3'd6;
            end else                                next_state = 3'd1;      
        end
        3'd7: begin
            next_state = 3'd1;
        end
        default: begin
            next_state = 3'd0;
        end
        endcase
    end
    always @(*) begin
        MACG_en   = (state == 3'd1);
        MCMem_en  = (state == 3'd1);
        ALU_en    = (state == 3'd1);
        HSync_out = 1'b0;
        VSync_out = 1'b0;
        if (state == 3'd7) begin
            HSync_out = 1'b1;
        end
        if ((state == 3'd6) && (is_sub == 1'b1)) begin
            VSync_out = 1'b1;
        end
    end
endmodule

