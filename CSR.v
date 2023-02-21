`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/06/18 12:42:29
// Design Name: 
// Module Name: CSR
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
`define RDCYCLE_ADDR_LOW 12'hC00
`define RDCYCLE_ADDR_HIGH 12'hC80
`define RDTIME_ADDR_LOW 12'hC01
`define RDTIME_ADDR_HIGH 12'hC81
`define RDINSTRET_ADDR_LOW 12'hC02
`define RDINSTRET_ADDR_HIGH 12'hC82
`define MHARTID_ADDR 12'hF14         

module CSR
#(
    parameter ID = 1
)
(
    input clk,
    input res,
    input request,
    input instr_done,
    input [11:0] A,
    input [31:0] mode,
    output [31:0] Q
);
    
    reg [63:0] RDCYCLE;
    reg [63:0] RDTIME;
    reg [63:0] RDINSTRET;
    reg [31:0] MHARTID;
    reg [31:0] reg_data;
    always @ (posedge clk) begin
        if (res) begin
            RDCYCLE   <= 64'd0;
            RDTIME    <= 64'd0;
            RDINSTRET <= 64'd0;  
            MHARTID   <= ID;          
        end else begin
            RDCYCLE <= RDCYCLE + 1;
            RDTIME <= RDTIME + 40;
            MHARTID <= MHARTID;
            if (instr_done)
                RDINSTRET <= RDINSTRET + 1;
            if(request) begin     
                case (A)
                    `RDCYCLE_ADDR_LOW:    RDCYCLE[31:0]  <= RDCYCLE[31:0]  | mode;
                    `RDCYCLE_ADDR_HIGH:   RDCYCLE[63:32] <= RDCYCLE[63:32] | mode;
                    `RDTIME_ADDR_LOW:     RDTIME[31:0]   <= RDTIME[31:0]   | mode;
                    `RDTIME_ADDR_HIGH:    RDTIME[63:32]  <= RDTIME[63:32]  | mode; 
                    `RDINSTRET_ADDR_LOW:  RDINSTRET[31:0]   <= RDINSTRET[31:0]  | mode;
                    `RDINSTRET_ADDR_HIGH: RDINSTRET[63:32]  <= RDINSTRET[63:32] | mode;     
                    `MHARTID_ADDR:        MHARTID <= MHARTID | mode; 
                    default: begin
                        RDCYCLE <= RDCYCLE + 1;
                        RDTIME <= RDTIME + 40;
                        if (instr_done)
                            RDINSTRET <= RDINSTRET + 1;
                        MHARTID <= MHARTID;
                    end                
               endcase  
            end 
        end
    end
    
    always @ (A) begin
        case (A)
            `RDCYCLE_ADDR_LOW:    reg_data = RDCYCLE[31:0];
            `RDCYCLE_ADDR_HIGH:   reg_data = RDCYCLE[63:32];
            `RDTIME_ADDR_LOW:     reg_data = RDTIME[31:0];
            `RDTIME_ADDR_HIGH:    reg_data = RDTIME[63:32]; 
            `RDINSTRET_ADDR_LOW:  reg_data = RDINSTRET[31:0];
            `RDINSTRET_ADDR_HIGH: reg_data = RDINSTRET[63:32];     
            `MHARTID_ADDR:        reg_data = MHARTID; 
            default:              reg_data = 32'd0;
        endcase
    end
    assign Q = reg_data;
endmodule
