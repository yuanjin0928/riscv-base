`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/16 10:56:40
// Design Name: 
// Module Name: alu
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
/*
control code encoding
bit 5: 1-branch 0-non-branch
branch: 6 possibities bit 2 to bit 0
BEQ-000, BNE-001, BLT-100, BGE-101, BLTU-110, BGEU-111
non-branch: bit 2 to bit 0
ADD/SUB-000, SLL-001, SLT-010, SLTU-011, XOR-100, SRL/SRA-101, OR-110, AND-111
bit 4: ADD/SRL-0, SUB/SRA-1
bit 3: mul
*/
`define ALU_ADD  6'b000000
`define ALU_MUL  6'b001000
`define ALU_SUB  6'b010000
`define ALU_SLL  6'b000001
`define ALU_SLT  6'b000010
`define ALU_SLTU 6'b000011
`define ALU_XOR  6'b000100
`define ALU_SRL  6'b000101
`define ALU_SRA  6'b010101
`define ALU_OR   6'b000110
`define ALU_AND  6'b000111
`define ALU_BEQ  6'b100000
`define ALU_BNE  6'b100001
`define ALU_BLT  6'b100100
`define ALU_BGE  6'b100101
`define ALU_BLTU 6'b100110
`define ALU_BGEU 6'b100111

module alu(
    input       [5:0]  alu_ctr,
    input       [31:0] alu_rs1,
    input       [31:0] alu_rs2,
    output reg  [31:0] alu_res,
    output reg         alu_cmp
    );
    
    always @ (alu_ctr, alu_rs1, alu_rs2) begin
        alu_res = 32'd0; 
        alu_cmp = 1'b0;
        case (alu_ctr)
            `ALU_ADD : alu_res = $signed(alu_rs1) + $signed(alu_rs2);
            `ALU_MUL : alu_res = $signed(alu_rs1) * $signed(alu_rs2);   //needed to be imroved
            `ALU_SUB : alu_res = $signed(alu_rs1) - $signed(alu_rs2);
            `ALU_SLL : alu_res = alu_rs1 << alu_rs2;
            `ALU_SLT : alu_res = ($signed(alu_rs1) < $signed(alu_rs2))     ? 32'd1 : 32'd0;
            `ALU_SLTU: alu_res = ($unsigned(alu_rs1) < $unsigned(alu_rs2)) ? 32'd1 : 32'd0;
            `ALU_XOR : alu_res = alu_rs1 ^ alu_rs2;
            `ALU_SRL : alu_res = alu_rs1 >> alu_rs2;
            `ALU_SRA : alu_res = $signed(alu_rs1) >>> alu_rs2;
            `ALU_OR  : alu_res = alu_rs1 | alu_rs2;
            `ALU_AND : alu_res = alu_rs1 & alu_rs2;
            `ALU_BEQ : alu_cmp = ($signed(alu_rs1) == $signed(alu_rs2))    ? 1 : 0;
            `ALU_BNE : alu_cmp = ($signed(alu_rs1) != $signed(alu_rs2))    ? 1 : 0;
            `ALU_BLT : alu_cmp = ($signed(alu_rs1) <  $signed(alu_rs2))    ? 1 : 0;
            `ALU_BGE : alu_cmp = ($signed(alu_rs1) >=  $signed(alu_rs2))   ? 1 : 0;
            `ALU_BLTU: alu_cmp = ($unsigned(alu_rs1) < $unsigned(alu_rs2)) ? 1 : 0;
            `ALU_BGEU: alu_cmp = ($unsigned(alu_rs1) >= $unsigned(alu_rs2)) ? 1 : 0;
             default : begin alu_res = 32'd0; alu_cmp = 1'b0; end
        endcase
    end
 endmodule