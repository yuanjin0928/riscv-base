`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/06/18 20:53:00
// Design Name: 
// Module Name: mem_access_ctrl
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
`define BYTE   3'b000
`define BYTEU  3'b100
`define HWORD  3'b001
`define HWORDU 3'b101
`define WORD   3'b010

module mem_access_ctrl(
    input clk,
    input res,
    input access,
    input write,
    input finished_once,
    input [2:0] width,
    input [31:0] addr_pre,
    input [31:0] data_from_mem,
    input [31:0] data_from_reg,
    output [1:0] times_required, 
    output [3:0]  data_be,
    output [31:0] addr_post,
    output [31:0] data_to_mem,
    output [31:0] data_to_reg
);
    reg [1:0] times_required;
    reg [3:0] data_be;
    reg [31:0] addr_post, data_to_mem, data_to_reg;
    reg  [31:0] prev_value_Q, prev_value_D;    //unaligned memory access, need to store the result of the first access.
    wire [31:0] starting_addr = {addr_pre[31:2], 2'b00};
    wire [1:0] byte_offset = addr_pre[1:0];
    reg aligned;
    always @ (byte_offset, width) begin
        aligned = 1'b1;
        case (width)
            `BYTE,
            `BYTEU: begin
                aligned = 1'b1;   
             end
            `HWORD,
            `HWORDU: begin
                //regarding offset eaquals to 2'b01, it's actually unaligned, but the second access can be cancelled, we also consider it as
                //one type of aligned
                if (byte_offset == 2'b00 || byte_offset == 2'b01 || byte_offset == 2'b10) begin
                    aligned = 1'b1;                
                end else begin
                    aligned = 1'b0;
                end
             end
            `WORD: begin
                if (byte_offset == 2'b00) begin
                    aligned = 1'b1;                
                end else begin
                    aligned = 1'b0;
                end
             end  
             default: aligned = 1'b1;  
        endcase
    end
    
    parameter S0 = 0, S1 = 1, S2 = 2;
    reg [1:0] cur_state, next_state; 
    always @ (posedge clk) begin
        if (res) begin  
            cur_state <= S0;
            prev_value_Q <= 32'd0;   
        end else begin
            cur_state <= next_state;
            prev_value_Q <= prev_value_D;
        end
    end   
    
    always @ (cur_state, access, aligned, finished_once) begin
        next_state = S0;
        case (cur_state)
            S0 : begin
                if (access) begin
                    if (aligned)
                        next_state = S1;
                    else 
                        next_state = S2;
                end else begin
                    next_state = S0;
                end
            end
            S1 : begin
                if(finished_once) begin
                    next_state = S0;
                end else begin
                    next_state = S1;
                end
            end 
            S2 : begin
                if(finished_once) begin
                    next_state = S1;
                end else begin
                    next_state = S2;
                end
            end  
            default: next_state = S0;
        endcase
    end
    
    always @ (cur_state, finished_once) begin
        times_required = 2'b00;
        case (cur_state)
            S0 : begin
                times_required = 2'b00;    
            end
            S1 : begin
                if (finished_once) begin
                    times_required = 2'b00;
                end else begin
                    times_required = 2'b01;
                end
            end
            S2 : begin
                if (finished_once) begin
                    times_required = 2'b01;
                end else begin
                    times_required = 2'b10;    
                end
            end
            default : times_required = 2'b00;
        endcase 
    end
    
    always @ (cur_state, write, starting_addr, byte_offset, width, aligned, data_from_reg, data_from_mem, prev_value_Q) begin
        addr_post = 32'd0;
        data_to_mem = 32'd0;
        data_to_reg = 32'd0;
        data_be = 4'b0000;
        case (cur_state)
            S0 : begin
                addr_post = 32'd0;
                data_to_mem = 32'd0;
                data_to_reg = 32'd0; 
                data_be = 4'b0000;       
            end 
            S1 : begin
                case (width)
                    `BYTE : begin
                        addr_post = starting_addr;
                        if (write) begin
                            case (byte_offset) 
                                2'b00 : data_to_mem = {24'd0, data_from_reg[7:0]};
                                2'b01 : data_to_mem = {16'd0, data_from_reg[7:0], 8'd0};
                                2'b10 : data_to_mem = {8'd0, data_from_reg[7:0], 16'd0};
                                2'b11 : data_to_mem = {data_from_reg[7:0], 24'd0};
                                default : data_to_mem = 32'd0;
                            endcase    
                            data_be = 4'b0001 << byte_offset;    
                        end else begin
                            case (byte_offset) 
                                2'b00 : data_to_reg = {{24{data_from_mem[7]}}, data_from_mem[7:0]};
                                2'b01 : data_to_reg = {{24{data_from_mem[15]}}, data_from_mem[15:8]};
                                2'b10 : data_to_reg = {{24{data_from_mem[23]}}, data_from_mem[23:16]};
                                2'b11 : data_to_reg = {{24{data_from_mem[31]}}, data_from_mem[31:24]};
                                default : data_to_reg = 32'd0;
                            endcase    
                        end       
                    end
                    `BYTEU : begin
                        addr_post = starting_addr;                       
                        case (byte_offset) 
                            2'b00 : data_to_reg = {24'd0, data_from_mem[7:0]};
                            2'b01 : data_to_reg = {24'd0, data_from_mem[15:8]};
                            2'b10 : data_to_reg = {24'd0, data_from_mem[23:16]};
                            2'b11 : data_to_reg = {24'd0, data_from_mem[31:24]};
                            default : data_to_reg = 32'd0;
                        endcase             
                    end
                    `HWORD : begin
                        if (aligned) begin
                            addr_post = starting_addr;
                             if (write) begin
                               case (byte_offset) 
                                 2'b00 : data_to_mem = {16'd0, data_from_reg[15:0]};
                                 2'b01 : data_to_mem = {8'd0, data_from_reg[15:0], 8'd0};
                                 2'b10 : data_to_mem = {data_from_reg[15:0], 16'd0};
                                 default : data_to_mem = 32'd0;
                             endcase    
                             data_be = 4'b0011 << byte_offset;     
                           end else begin
                               case (byte_offset) 
                                   2'b00 : data_to_reg = {{16{data_from_mem[15]}}, data_from_mem[15:0]};
                                   2'b01 : data_to_reg = {{16{data_from_mem[23]}}, data_from_mem[23:8]};
                                   2'b10 : data_to_reg = {{16{data_from_mem[31]}}, data_from_mem[31:16]};
                                   default : data_to_reg = 32'd0;
                               endcase     
                           end
                        end else begin
                            addr_post = starting_addr + 4;
                            if (write) begin
                                data_to_mem = {24'd0, data_from_reg[15:8]};
                                data_be = 4'b0001;    
                            end else begin
                                data_to_reg = {{16{data_from_mem[7]}},data_from_mem[7:0],prev_value_Q[7:0]};
                            end
                        end
                    end
                    `HWORDU : begin
                        if (aligned) begin
                            addr_post = starting_addr;
                           case (byte_offset) 
                               2'b00 : data_to_reg = {16'd0, data_from_mem[15:0]};
                               2'b01 : data_to_reg = {16'd0, data_from_mem[23:8]};
                               2'b10 : data_to_reg = {16'd0, data_from_mem[31:16]};
                               default : data_to_reg = 32'd0;
                           endcase     
                        end else begin
                            addr_post = starting_addr + 4;
                            data_to_reg = {16'd0,data_from_mem[7:0],prev_value_Q[7:0]};
                        end    
                    end
                    `WORD : begin
                        if (aligned) begin
                            addr_post = starting_addr;
                            if (write) begin
                                data_to_mem = data_from_reg;
                                data_be = 4'b1111;     
                            end else begin
                               data_to_reg = data_from_mem;    
                           end
                        end else begin
                            addr_post = starting_addr + 4;
                            if (write) begin
                                case (byte_offset)
                                    2'b01 : data_to_mem = {24'd0, data_from_reg[31:24]};
                                    2'b10 : data_to_mem = {16'd0, data_from_reg[31:16]};
                                    2'b11 : data_to_mem = {8'd0, data_from_reg[31:8]};
                                    default : data_to_mem = 32'd0;
                                endcase 
                                data_be = (byte_offset == 2'b01)?(4'b0001):(byte_offset == 2'b10)?(4'b0011):(byte_offset == 2'b11)?(4'b0111):(4'b0000);   
                            end else begin
                                case (byte_offset)
                                    2'b01 : data_to_reg = {data_from_mem[7:0], prev_value_Q[23:0]};
                                    2'b10 : data_to_reg = {data_from_mem[15:0],prev_value_Q[15:0]};
                                    2'b11 : data_to_reg = {data_from_mem[23:0],prev_value_Q[7:0]};
                                    default : data_to_reg = 32'd0;
                                endcase 
                            end
                        end
                    end 
                    default : begin
                        addr_post = 32'd0;
                        data_to_mem = 32'd0;
                        data_to_reg = 32'd0; 
                        data_be = 4'b0000;     
                    end
                endcase     
            end
            S2 : begin
                case (width)
                    `HWORD : begin
                        addr_post = starting_addr;
                        if (write) begin
                            data_to_mem = {data_from_reg[7:0], 24'd0};
                            data_be = 4'b1000;    
                        end else begin
                            data_to_reg = 32'd0;
                        end
                    end
                    `HWORDU : begin
                        addr_post = starting_addr;
                        data_to_reg = 32'd0;
                    end
                    `WORD : begin
                        addr_post = starting_addr;
                        if (write) begin
                            case (byte_offset)
                                2'b01 : data_to_mem = {data_from_reg[23:0], 8'd0};
                                2'b10 : data_to_mem = {data_from_reg[15:0], 16'd0};
                                2'b11 : data_to_mem = {data_from_reg[7:0], 24'd0};
                                default : data_to_mem = 32'd0;
                            endcase 
                            data_be = 4'b1111 << byte_offset;  
                        end else begin
                            data_to_reg = 32'd0;
                        end    
                    end 
                    default : begin
                        addr_post = 32'd0;
                        data_to_mem = 32'd0;
                        data_to_reg = 32'd0; 
                        data_be = 4'b0000;     
                    end
                endcase
            end
            default: begin
                addr_post = 32'd0;
                data_to_mem = 32'd0;
                data_to_reg = 32'd0; 
                data_be = 4'b0000; 
            end  
        endcase            
    end
    
    always @ (cur_state, width, byte_offset, data_from_reg, data_from_mem, prev_value_Q) begin
        prev_value_D = 32'd0;
        case (cur_state)
            S0,
            S1 : prev_value_D = prev_value_Q;
            S2 : begin
                case (width)
                    `HWORD,
                    `HWORDU : begin
                        prev_value_D = {24'd0, data_from_mem[31:24]};    
                    end
                    `WORD : begin
                        case (byte_offset)
                            2'b01 : prev_value_D = {8'd0, data_from_mem[31:8]};
                            2'b10 : prev_value_D = {16'd0, data_from_mem[31:16]};
                            2'b11 : prev_value_D = {24'd0, data_from_mem[31:24]};
                            default : prev_value_D = 32'd0;  
                        endcase  
                    end
                    default : prev_value_D = 32'd0; 
                endcase        
            end
            default : prev_value_D = 32'd0;
        endcase
    end
        
endmodule
