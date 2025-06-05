
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/11/2024 09:55:06 AM
// Design Name: 
// Module Name: Region_A_CTRL
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


module Region_A_CTRL(
    input wire ALU_en,
    input wire [4:0] opcode,
    output wire [2:0] ALUSel,
    output wire WEn,
    output wire ALU_enable
    );
    wire noA,noB,noC,noD,noE;
    wire w0,w1,w2,w3,w4,w5,w6,w7,w8,w9,w10,w11,w12,w13;
    not(noA,opcode[4]);
    not(noB,opcode[3]);
    not(noC,opcode[2]);
    not(noD,opcode[1]);
    not(noE,opcode[0]);
    and(w0,noA,noB);
    and(w1,noA,noC,noD);
    and(w2,noA,noC,noE);
    and(w3,w0,opcode[0]);
    and(w4,noA,noC,opcode[0]);
    and(w5,w0,opcode[1]);
    and(w6,w0,opcode[2]);
    and(w7,w1,opcode[3],opcode[0]);
    or(w8,w0,w1,w2);
    or(w9,w3,w4);
    or(w10,w5,w7);
    or(w11,w6,w7);
    and(WEn,ALU_en,w8);
    and(ALUSel[0],ALU_en,w9);
    and(ALUSel[1],ALU_en,w10);
    and(ALUSel[2],ALU_en,w11);
    and(ALU_enable,ALU_en,1);
endmodule
