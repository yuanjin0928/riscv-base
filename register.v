`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/24 08:38:25
// Design Name: 
// Module Name: register
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

module register 
    # (
       parameter DATA_WIDTH = 32,
       parameter ADDR_WIDTH = 5
    )
    (
        input  [DATA_WIDTH-1:0]   D,            //Data input
        input  [ADDR_WIDTH-1:0]   A_D,          //Destination address for the input data D
        input  [ADDR_WIDTH-1:0]   A_Q0,         //Address for output data Q0, Q1
        input  [ADDR_WIDTH-1:0]   A_Q1,
        input                     write_enable, //if write_enable = '1', then the input data is written into the register
        input                     RES,          //Reset, if RES = '1', all registers are set to 0
        input                     CLK,          //Clock input
        output [DATA_WIDTH-1:0]   Q0,           //Data output
        output [DATA_WIDTH-1:0]   Q1            //Data output       
    );
    reg [DATA_WIDTH-1:0] regset [2**ADDR_WIDTH-1:0];
    integer i;
    
    initial begin
        for (i=0; i<2**ADDR_WIDTH; i=i+1)
                regset[i] <= 0;
    end
    
    always @ (posedge CLK) begin
        if (RES) begin
            for (i=0; i<2**ADDR_WIDTH; i=i+1)
                regset[i] <= 0;        
        end else begin
            //Synchronous write
            if (write_enable & A_D != 0)  
                regset[A_D] <= D;
        end
    end
    //Asynchronous read
    assign Q0 = regset[A_Q0];
    assign Q1 = regset[A_Q1];
    
endmodule
