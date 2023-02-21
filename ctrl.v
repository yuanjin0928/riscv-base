`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/08 08:33:07
// Design Name: 
// Module Name: ctrl
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

module ctrl(
    input clk,
    input res,
    
    input         instr_gnt,
    input         instr_r_valid,
    input  [6:0]  instr_opcode, 
    output        instr_req,
    
    input         data_gnt,
    input         data_r_valid, 
    output        data_req,
    output        data_write_enable,
    
    input         irq,
    output        irq_ack,
    
    input         mret, //mret or csrrs   
    
    //aligned memory access
    input  [1:0]  times_required,
    output        mem_access,
    output        mem_write, 
    output        finished_once,     
    
    output        pc_en,
    output        pc_backup_en,
    output        instr_en,
    output        instr_rst,
    output        irq_id_en,
    output        irq_ack_id_en,
    output        INT,
    output        instr_done,
    output [13:0] ctr_code
);

    reg instr_req, data_req, data_write_enable, instr_en, instr_rst, pc_en, pc_backup_en, irq_ack_id_en, irq_ack, INT, instr_done;
    //cur_int_state: 0: one interrupt has been accepted 1: no interrupt has been accepted
    reg int_Q;
    reg int_D;
    reg int_running_Q;    //have interrupt being processed
    reg int_running_D;
    reg mem_access;
    reg mem_write;  //store or load
    reg int_rst;
    reg [13:0] ctr_code;
    
    //State
    parameter INITIAL = 0, INSTR_WAIT_GNT = 1, INSTR_WAIT_VALID = 2, INSTR_EXE = 3, READ_DATA_WAIT_GNT = 4, 
              WRITE_DATA_WAIT_GNT = 5, DATA_WAIT_VALID = 6, INT_PROC = 7; //WRITE_DATA = 7, ;
    reg [2:0] cur_state, next_state;   
    
    always @ (posedge clk, posedge res) begin
        if (res) begin
            cur_state     <= INITIAL;  
            int_Q         <= 1'b1;
            int_running_Q <= 1'b0;
        end else begin
            cur_state     <= next_state;
            int_Q         <= int_D;
            int_running_Q <= int_running_D;
        end
    end
    
    always @ (int_Q, irq, int_rst) begin
        int_D = 1'b1;
        case (int_Q)
            1'b0: begin
                if (int_rst) begin
                    int_D = 1'b1;
                end else begin
                    int_D = 1'b0;     
                end
            end
            1'b1: begin
                if(irq) begin
                    int_D = 1'b0;    
                end
            end
            default: int_D = 1'b1;
        endcase
    end
    assign irq_id_en = int_Q;
    
    always @ (int_running_Q, INT, int_rst) begin
        int_running_D = 1'b0;
        case (int_running_Q)
            1'b0 : begin
                if (INT) begin
                    int_running_D = 1'b1;
                end
            end
            1'b1 : begin
                if (int_rst) begin
                    int_running_D = 1'b0;
                end else begin
                    int_running_D = 1'b1;
                end
           end
           default : int_running_D = 1'b0;
        endcase
    end
    
    always @ (cur_state,instr_gnt,instr_r_valid,mem_access,mem_write,times_required,data_gnt,data_r_valid,int_Q,int_running_Q) begin
        case(cur_state)
            INITIAL       : begin
                next_state = INSTR_WAIT_GNT;
            end
            INSTR_WAIT_GNT: begin
               if (instr_gnt) begin
                    next_state = INSTR_WAIT_VALID;
               end else begin
                    next_state = INSTR_WAIT_GNT;
               end 
            end            
            INSTR_WAIT_VALID: begin
               if (instr_r_valid) begin
                    next_state = INSTR_EXE;
               end else begin
                    next_state = INSTR_WAIT_VALID;
               end 
            end 
            INSTR_EXE: begin
                if (mem_access) begin
                    if(mem_write) begin
                        next_state = WRITE_DATA_WAIT_GNT;
                    end else begin
                        next_state = READ_DATA_WAIT_GNT;    
                    end
                end else if (!int_Q && !int_running_Q) begin
                    next_state = INT_PROC;
                end else begin
                    next_state = INSTR_WAIT_GNT;
                end   
            end
            INT_PROC: begin
                next_state = INSTR_WAIT_GNT;
            end
            READ_DATA_WAIT_GNT: begin
                if (data_gnt) begin
                    next_state = DATA_WAIT_VALID;
                end else begin
                    next_state = READ_DATA_WAIT_GNT;
                end    
            end
            DATA_WAIT_VALID: begin
                if (data_r_valid) begin
                    if (times_required != 2'b00) begin
                        next_state = READ_DATA_WAIT_GNT;
                    end else if (!int_Q && !int_running_Q) begin
                        next_state = INT_PROC;
                    end else begin
                        next_state = INSTR_WAIT_GNT;
                    end
                end else begin
                    next_state = DATA_WAIT_VALID;
                end
            end
            WRITE_DATA_WAIT_GNT: begin
                if (data_gnt) begin
                    if (times_required != 2'b00) begin
                        next_state = WRITE_DATA_WAIT_GNT;
                    end else if(!int_Q && !int_running_Q) begin
                        next_state = INT_PROC;
                    end else begin
                        next_state = INSTR_WAIT_GNT;    
                    end
                end else begin
                    next_state = WRITE_DATA_WAIT_GNT;
                end    
            end
//            WRITE_DATA: begin
//                if (times_required != 2'b00) begin
//                    next_state = WRITE_DATA_WAIT_GNT;
//                end else if(!int_Q && !int_running_Q) begin
//                    next_state = INT_PROC;
//                end else begin
//                    next_state = INSTR_WAIT_GNT;    
//                end
//            end
            default: begin
                    next_state = INSTR_WAIT_GNT;
            end  
        endcase    
    end
    assign finished_once = (cur_state == DATA_WAIT_VALID) ? (data_r_valid) : 
                           (cur_state == WRITE_DATA_WAIT_GNT) ? (data_gnt) : 1'b0;
        
    //output logic
    always @ (cur_state) begin
        instr_req         = 1'b0;
        data_req          = 1'b0;
        pc_en             = 1'b0;
        pc_backup_en      = 1'b0;
        instr_en          = 1'b0;
        instr_rst         = 1'b0;
        irq_ack_id_en     = 1'b0;
        data_write_enable = 1'b0;
        INT               = 1'b0; 
        irq_ack           = 1'b0;                
        case (cur_state)
            INITIAL       : begin
            end
            INSTR_WAIT_GNT: begin
                instr_req = 1'b1; 
                instr_rst = 1'b1;                        
            end                         
            INSTR_WAIT_VALID: begin
                instr_req = 1'b0;   
                instr_en  = 1'b1;            
            end       
            INSTR_EXE: begin   
                pc_en = 1'b1;
            end  
            READ_DATA_WAIT_GNT: begin
                data_req = 1'b1;
            end
            WRITE_DATA_WAIT_GNT: begin
                data_req = 1'b1;
                data_write_enable = 1'b1;
            end
            DATA_WAIT_VALID: begin
                data_req  = 1'b0;               
            end
//            WRITE_DATA: begin
//                data_req  = 1'b0;
//                data_write_enable = 1'b1;
//            end 
            INT_PROC: begin
                irq_ack       = 1'b1; 
                instr_rst     = 1'b1; 
                pc_en         = 1'b1; 
                pc_backup_en  = 1'b1; 
                irq_ack_id_en = 1'b1;
                INT           = 1'b1;         
            end    
            default: begin
                instr_req         = 1'b0;
                data_req          = 1'b0;
                pc_en             = 1'b0;
                pc_backup_en      = 1'b0;
                instr_en          = 1'b0;
                instr_rst         = 1'b0;
                irq_ack_id_en     = 1'b0;
                data_write_enable = 1'b0;
                INT               = 1'b0;
                irq_ack           = 1'b0;
            end
        endcase
    end
    
    //ctr_code, bit 13: CSRReq, bit 12: Branch, bit 11: MemtoReg (0: data_path, 1: mem), bit 10: ALUSrc (0: reg_data, 1: imm), bit 9: RegWrite
    //bit 8 LUI (0: AUIPC, 1:LUI), bit 7: ALUtoMem (0: alu_res, 1: imm), bit 6: Jump, bit 5: JAL (0: JALR, 1: JAL), bit 4: RET
    //bit 3-0: ALUOp
    always @ (instr_opcode,mret) begin
        mem_access = 1'b0;
        mem_write  = 1'b0;
        int_rst    = 1'b0;
        ctr_code   = 14'b00_0000_0000_0000;
        case (instr_opcode)
            `OPCODE_OP     : ctr_code = 14'b00_0010_0000_0000;
            `OPCODE_OPIMM  : ctr_code = 14'b00_0110_0000_0001;  
            `OPCODE_STORE  : begin 
                ctr_code = 14'b00_0100_0000_0010;
                mem_access = 1'b1;
                mem_write = 1'b1;
             end
            `OPCODE_LOAD   : begin
                ctr_code = 14'b00_1110_0000_0011;
                mem_access = 1'b1;
             end
            `OPCODE_BRANCH : ctr_code = 14'b01_0000_0010_0100;
            `OPCODE_JALR   : ctr_code = 14'b00_0010_1100_0101;
            `OPCODE_JAL    : ctr_code = 14'b00_0010_1110_0110;
            `OPCODE_AUIPC  : ctr_code = 14'b00_0010_1000_0111;
            `OPCODE_LUI    : ctr_code = 14'b00_0011_1000_1000;
            `OPCODE_MRET   : begin
                if (mret) begin
                    int_rst  = 1'b1;
                    ctr_code = 14'b00_0000_0001_1001;
                end else begin
                    ctr_code = 14'b10_0010_0000_1001;
                end
            end
            default        : ctr_code = 14'b00_0000_0000_0000;
        endcase    
    end
    
    //check whether one instruction has been processed
    always @ (cur_state, mem_access, data_r_valid, times_required) begin
        instr_done = 1'b0;
        case (cur_state)
            INSTR_EXE: begin 
                if (!mem_access)
                    instr_done = 1'b1;  
            end  
            DATA_WAIT_VALID: begin
                if (data_r_valid && times_required == 2'b00)
                    instr_done = 1'b1;              
            end
            WRITE_DATA_WAIT_GNT: begin
                if (data_gnt && times_required == 2'b00)
                    instr_done = 1'b1;
            end 
            default: instr_done = 1'b0;
        endcase        
    end
       
endmodule
