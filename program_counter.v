`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/24 10:16:45
// Design Name: 
// Module Name: program_counter
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


module program_counter(
    input [31:0] D,         //Jump address
    input MODE,             //Operating mode(when MODE = 1,load a jump address,otherwise increment by 4)
    input ENABLE,           //Enable signal,only with ENABLE = 1, jump address can be loaded or the program counter can be incremented
    input RES,              //Reset,with RES = 1,the program counter is initialized with the boot ROM adress(0x1A00_0000)
    input CLK,              //Clock input
    output [31:0] PC_OUT    //Program counter output
    );
    
    reg [31:0] pc_reg;
    assign PC_OUT = pc_reg;
    
    always @ (posedge CLK) begin
        if (RES == 1) begin
            pc_reg <= 32'h1A00_0000;
        end else begin
            if (ENABLE == 1) begin
                if (MODE == 1) begin
                    pc_reg <= D;
                end else begin
                    pc_reg <= pc_reg + 4;    
                end
            end  
        end    
    end
endmodule
