`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/08 10:56:14
// Design Name: 
// Module Name: imm_gen
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
`include "riscv_isa_defines.v"

module imm_gen(
    input  [31:0] instr,
    output [31:0] imm
);
    reg [6:0] op_code;
    reg [31:0] imm;
    
    always @ (instr) begin
        op_code = instr[6:0];
        case (op_code)
            `OPCODE_OPIMM  :begin
                if (instr[14:12] == 3'b001 || instr[14:12] == 3'b101) begin
                    imm = $unsigned(instr[24:20]);
                end else begin
                    imm = $signed(instr[31:20]);    
                end
            end
            `OPCODE_LOAD,
            `OPCODE_JALR   : imm = $signed(instr[31:20]);
            `OPCODE_STORE  : imm = $signed({instr[31:25],instr[11:7]});
            `OPCODE_BRANCH : imm = $signed({instr[31],instr[7],instr[30:25],instr[11:8]});
            `OPCODE_JAL    : imm = $signed({instr[31],instr[19:12],instr[20],instr[30:21]});
            `OPCODE_AUIPC  : imm = instr[31:12] << 12;
            `OPCODE_LUI    : imm = instr[31:12] << 12; 
            default        : imm = $signed(instr[31:20]);
        endcase
    end
endmodule