`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/23 20:23:33
// Design Name: 
// Module Name: int_proc
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


module int_proc(
    input clk,
    input res,
    input enable,
    input  [4:0] irq_id_D,
    output [4:0] irq_id_Q
);
    
    reg [4:0] irq_id_Q;
    always @ (posedge clk, posedge res) begin
        if (res) begin
            irq_id_Q <= 5'b00000;
        end else if (enable) begin
            irq_id_Q <= irq_id_D;
        end
    end
endmodule
