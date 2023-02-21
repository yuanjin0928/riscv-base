`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/06/11 11:10:29
// Design Name: 
// Module Name: instr_cache
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


module instr_cache
#(
    parameter LOG_SIZE = 4
)
(
    input clk,
    input res,
    
    //interface between processor and cache
    input         cached_instr_req,
    input  [31:0] cached_instr_adr,
    output        cached_instr_gnt,
    output        cached_instr_rvalid,
    output [31:0] cached_instr_read,
    
    //interface between cache and main memory
    input         instr_gnt,
    input         instr_rvalid,
    input  [31:0] instr_read,
    output        instr_req,
    output [31:0] instr_adr    
);
    reg cached_instr_gnt, cached_instr_rvalid, instr_req;
    
    wire hit;
    wire [LOG_SIZE-1:0] index;
    reg [31:0] lines [2**LOG_SIZE-1:0];
    reg [30-LOG_SIZE-1:0] tags [2**LOG_SIZE-1:0];
    reg [2**LOG_SIZE-1:0] valids;
    
    assign index = cached_instr_adr[1+LOG_SIZE:2];
    assign hit   = (valids[index] == 1'b0) ? 1'b0 : 
                   (cached_instr_adr[31:2+LOG_SIZE] == tags[index]) ? 1'b1 : 1'b0;
                   
    assign cached_instr_read = lines[index]; 
    assign instr_adr = cached_instr_adr;             
    
    always @(posedge clk) begin
        if(res == 1'b1)
            valids <= {2**LOG_SIZE{1'b0}};
        else if (instr_rvalid == 1'b1 && cur_state == WAIT_RVALID) begin
            lines[index]  <= instr_read;
            tags[index]   <= cached_instr_adr[31:2+LOG_SIZE];
            valids[index] <= 1'b1;
        end
    end
    
    localparam STATE = 5;
    localparam IDLE = 5'b00001, SET_GNT = 5'b00010, SET_RVALID = 5'b00100, WAIT_GNT = 5'b01000, WAIT_RVALID = 5'b10000;
    
    reg [STATE-1:0] cur_state, next_state;
    
    always @(posedge clk) begin
        if (res == 1'b1)
            cur_state <= IDLE;
        else 
            cur_state <= next_state;
    end
    
    always @(cur_state, hit, cached_instr_req, instr_gnt, instr_rvalid) begin
        next_state = IDLE;
        cached_instr_gnt = 1'b0;
        cached_instr_rvalid = 1'b0;
        instr_req = 1'b0;
        case (cur_state)   
            IDLE: begin
                if (cached_instr_req) begin
                    if (hit == 1'b1) begin
                        next_state = SET_GNT;
                    end else begin
                        next_state = WAIT_GNT;
                    end
                end 
            end 
            SET_GNT: begin
                next_state = SET_RVALID;
                cached_instr_gnt = 1'b1;    
            end
            SET_RVALID: begin
                next_state = IDLE;
                cached_instr_rvalid = 1'b1;
            end
            WAIT_GNT: begin
                instr_req = 1'b1;
                if (instr_gnt == 1'b1) begin
                    next_state = WAIT_RVALID;
                end else begin
                    next_state = WAIT_GNT;
                end            
            end
            WAIT_RVALID: begin
                if (instr_rvalid == 1'b1) begin
                    next_state = SET_GNT;
                end else begin
                    next_state = WAIT_RVALID;
                end
            end
            default: next_state = IDLE;
        endcase         
    end
    
endmodule
