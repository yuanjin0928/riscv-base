`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/08 10:56:14
// Design Name: 
// Module Name: ALU_control
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

module ALU_control(
    input  [3:0] ALUOp,
    input  [4:0] func_bits,
    output [5:0] alu_ctr    
);   
    reg [4:0] func;
    assign alu_ctr[5] = (ALUOp == 4'b0100) ? 1'b1 : 1'b0;
    
    always @ (ALUOp, func_bits) begin
        case (ALUOp)
            4'b0000,
            4'b0101,
            4'b0110,
            4'b0111,
            4'b1000: func = func_bits;
            4'b0001: begin
                if (func_bits[2:0] == 3'b101) begin //shift right
                    if (func_bits[4] == 1'b1) begin
                        func = 5'b10101;
                    end else begin
                        func = 5'b00101;
                    end
                end else begin
                    func = {2'b00, func_bits[2:0]};    
                end
            end
            4'b0100: func = {2'b00, func_bits[2:0]};
            4'b0010,
            4'b0011,
            4'b1001: func = 5'b00000;
            default: func = 5'b00000;
        endcase
    end
    assign alu_ctr[4:0] = func; 
endmodule
