`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/04 09:20:28
// Design Name: 
// Module Name: arbitrator
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


module arbitrator(
     input clk,
     input res,
     
     input        instr_req_1,
     input [31:0] instr_adr_1,
     
     input        instr_req_2,
     input [31:0] instr_adr_2,
     
     output        instr_req,
     output [31:0] instr_adr,
     output        data_req,
     output [31:0] data_addr,     
        
     input         instr_gnt,
     input         instr_rvalid,
     input  [31:0] instr_read,
     
     output        instr_gnt_1,
     output        instr_rvalid_1,
     output [31:0] instr_read_1,
     
     output        instr_gnt_2,
     output        instr_rvalid_2,
     output [31:0] instr_read_2,
     
     input        data_req_1,
     input        data_write_enable_1,
     input        data_write_1,
     input [3:0]  data_be_1,
     input [31:0] data_addr_1,
      
     input        data_req_2,
     input        data_write_enable_2,
     input        data_write_2,
     input [3:0]  data_be_2,
     input [31:0] data_addr_2,
     
     output data_write_enable,
     output data_be,
     output [31:0] data_write,
     
     input         data_gnt,
     input         data_r_valid,
     input  [31:0] data_read,
     
     output        data_gnt_1,
     output        data_r_valid_1,
     output [31:0] data_read_1,
     
     output        data_gnt_2,
     output        data_r_valid_2,
     output [31:0] data_read_2
);
    parameter IDLE = 0, MEM_READ = 1, MEM_WRITE = 2; 
    reg [1:0] cur_state, next_state;
    reg cur_proc,next_proc;
    reg select; 
    always @ (posedge clk) begin
        if (res) begin
            cur_state <= IDLE;  
            cur_proc <= 1'b0;
            select <= 1'b0;  
        end else begin
            cur_state <= next_state; 
            cur_proc <= next_proc;       
        end
    end
      
    wire [3:0] req = {instr_req_1,instr_req_2,data_req_1,data_req_2};
    always @ (cur_state,cur_proc,req,instr_req_1,instr_req_2,instr_gnt,instr_rvalid,data_req_1,data_req_2,data_write_enable_1, data_write_enable_2, data_r_valid, data_gnt) begin
        next_state = IDLE;
        next_proc = cur_proc;
        select = 1'b0;
        case (cur_state)
            IDLE: begin
                if (instr_req_1 | instr_req_2 | data_req_1 | data_req_2) begin 
                    case (req)
                        4'b1000: begin
                            next_state = MEM_READ;
                            next_proc = 1'b0;
                            select = 1'b0;
                        end
                        4'b0100: begin
                            next_state = MEM_READ;
                            next_proc = 1'b1;
                            select = 1'b1;
                        end
                        4'b0010: begin
                            next_proc = 1'b0;
                            select = 1'b0;
                            if (data_write_enable_1) 
                                next_state = MEM_WRITE;    
                            else 
                                next_state = MEM_READ;
                        end 
                        4'b0001: begin
                            next_proc = 1'b1;
                            select = 1'b1;
                            if (data_write_enable_2) 
                                next_state = MEM_WRITE;    
                            else 
                                next_state = MEM_READ;
                        end
                        4'b1100: begin
                            next_state = MEM_READ;
                            if (cur_proc == 1'b0) begin
                                select = 1'b1;
                                next_proc = 1'b1;
                            end else begin
                                select = 1'b0;
                                next_proc = 1'b0;
                            end                           
                        end
                        4'b0011: begin
                            if (cur_proc == 1'b0) begin
                                select = 1'b1;
                                next_proc = 1'b1;
                                if (data_write_enable_1)
                                    next_state = MEM_WRITE; 
                                else
                                    next_state = MEM_READ;
                            end else begin
                                select = 1'b0;
                                next_proc = 1'b0;
                                if (data_write_enable_2)
                                    next_state = MEM_WRITE; 
                                else
                                    next_state = MEM_READ;
                            end                           
                        end
                        4'b1001: begin
                            if (cur_proc == 1'b0) begin
                                select = 1'b1;
                                next_proc = 1'b1;
                                next_state = MEM_READ;
                            end else begin
                                select = 1'b0;
                                next_proc = 1'b0;
                                if (data_write_enable_2)
                                    next_state = MEM_WRITE; 
                                else
                                    next_state = MEM_READ;
                            end                               
                        end
                        4'b0110: begin
                            if (cur_proc == 1'b0) begin
                                select = 1'b1;
                                next_proc = 1'b1;
                                if (data_write_enable_1)
                                    next_state = MEM_WRITE; 
                                else
                                    next_state = MEM_READ;
                            end else begin
                                select = 1'b0;
                                next_proc = 1'b0;
                                next_state = MEM_READ;
                            end
                        end
                        default: begin
                            next_state = IDLE;
                            next_proc = cur_proc;
                            select = 1'b0;    
                        end                                                           
                    endcase         
                end else begin
                    next_state = IDLE;
                end
            end
            MEM_READ: begin
                if (cur_proc == 1'b0)
                    select = 1'b0;
                else
                    select = 1'b1;
                if (data_r_valid | instr_rvalid) begin
                    next_state = IDLE;
                end else begin
                    next_state = MEM_READ;
                end    
            end
            MEM_WRITE: begin
                if (cur_proc == 1'b0)
                    select = 1'b0;
                else
                    select = 1'b1;
                if (data_gnt) begin
                    next_state = IDLE;
                end else begin
                    next_state = MEM_WRITE;
                end    
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end
    
    assign instr_req = (select == 1'b0) ? instr_req_1 : instr_req_2;
    assign instr_adr = (select == 1'b0) ? instr_adr_1 : instr_adr_2;
    assign instr_gnt_1 = (select == 1'b0) ? instr_gnt : 1'b0;
    assign instr_gnt_2 = (select == 1'b0) ? 1'b0 : instr_gnt;
    assign instr_rvalid_1 = (select == 1'b0) ? instr_rvalid : 1'b0;
    assign instr_rvalid_2 = (select == 1'b0) ? 1'b0 : instr_rvalid;
    assign instr_read_1 = (select == 1'b0) ? instr_read : 32'd0;
    assign instr_read_2 = (select == 1'b0) ? 32'd0 : instr_read;
    
    assign data_req  = (select == 1'b0) ? data_req_1 : data_req_2;
    assign data_addr = (select == 1'b0) ? data_addr_1 : data_addr_2; 
    assign data_write_enable = (select == 1'b0) ? data_write_enable_1 : data_write_enable_2;
    assign data_be = (select == 1'b0) ? data_be_1 : data_be_2;
    assign data_write = (select == 1'b0) ? data_write_1 : data_write_2;
    assign data_gnt_1 = (select == 1'b0) ? data_gnt : 1'b0;
    assign data_gnt_2 = (select == 1'b0) ? 1'b0 : data_gnt;
    assign data_r_valid_1 = (select == 1'b0) ? data_r_valid : 1'b0;
    assign data_r_valid_2 = (select == 1'b0) ? 1'b0 : data_r_valid;
    assign data_read_1 = (select == 1'b0) ? data_read : 32'd0;
    assign data_read_2 = (select == 1'b0) ? 32'd0 : data_read; 

endmodule
