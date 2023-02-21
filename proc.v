`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/05/08 08:32:45
// Design Name: 
// Module Name: proc
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
`define INSTR_STORAGE_ADDR 32'h1C00_8000

module proc
#(  
    parameter ID = 1
)
(
    //Group 1
    input clk,
    input res,
    
    //Group 2    
    input         instr_gnt,
    input         instr_r_valid,
    input  [31:0] instr_read,
    output        instr_req,
    output [31:0] instr_addr,
    
    //Group 3   
    input         data_gnt,
    input         data_r_valid,
    input  [31:0] data_read,
    output        data_req,
    output        data_write_enable,
    output [3:0]  data_be,
    output [31:0] data_addr,   
    output [31:0] data_write,
    
    //Group 4
    input       irq,
    input  [4:0] irq_id,
    output       irq_ack,
    output [4:0] irq_ack_id
);
    
    //Program counter related signals
    wire        pc_mode;
    wire        pc_en;
    wire        pc_backup_en;
    wire [31:0] pc_value;
    wire [31:0] pc_backup;
    wire [31:0] pc_jump_address;
    
    //Instrction register signals
    wire instr_reg_en;
    wire instr_reg_rst;
    wire instr_en;
    wire instr_rst;
    wire [31:0] instr;
    
    //Control unit signals
    wire        mret;   //mret or csrrs
    wire        instr_done;
    wire        CSRReq, Branch, MemtoReg, ALUSrc, RegWrite, LUI, ALUtoMem, Jump, JAL, RET;
    wire [3:0]  ALUOp;
    wire [6:0]  instr_opcode;
    wire [13:0] ctr_code;
    
    //Interrupt signals
    wire        INT;
    wire        irq_id_en;
    wire        irq_ack_id_en;
    wire [4:0]  cur_irq_id;
    
    //Register set signals
    wire [31:0] reg_read_Q0, reg_read_Q1;
    wire [31:0] reg_write_data;
    
    //ALU signals
    wire        alu_cmp;
    wire [5:0]  alu_ctrl;
    wire [31:0] alu_result;
    wire [31:0] alu_rs1;
    wire [31:0] alu_rs2;
    
    //memory access control signals
    wire [1:0] times_required;
    wire mem_access;
    wire mem_write;
    wire finished_once;
    wire [31:0] load_data;
    
    //immediate generator signals
    wire [31:0] imm;
    
    //MUX for instruction CSRRS
    wire [31:0] csr_data;
    wire [31:0] post_mux_CSR;
    
    //Mux for instruction LUI, AUIPC
    wire [31:0] data_LUI;
    wire [31:0] data_AUIPC;
    wire [31:0] post_mux_LUI;
    wire [31:0] post_mux_Jump;
    wire [31:0] data_prev_mem;
    
    //Mux for instruction JAL, JALR
    wire [31:0] data_jump;

    //Program counter
    assign pc_mode = (alu_cmp & Branch) | Jump | INT | RET;
    assign pc_jump_address = (INT == 1'b1) ? (`INSTR_STORAGE_ADDR + {cur_irq_id, 2'b0}) : 
                             (RET == 1'B1) ? (pc_backup) :
                             (JAL == 1'b1) ? (pc_value + {imm[30:0], 1'b0}) : (reg_read_Q0 + imm);
    program_counter pc(
        .D(pc_jump_address),    //Jump address
        .MODE(pc_mode),         //Operating mode(when MODE = 1,load a jump address,otherwise increment by 4)
        .ENABLE(pc_en),         //Enable signal,only with ENABLE = 1, jump address can be loaded or the program counter can be incremented
        .RES(res),              //Reset,with RES = 1,the program counter is initialized with the boot ROM adress(0x1A00_0000)
        .CLK(clk),              //Clock input
        .PC_OUT(pc_value)       //Program counter output
    );
    assign instr_addr = pc_value;   //connect pc directly to the instruction memory
    
    //store current pc when interrupt happens
    REG_DRE_32 pc_backup_reg(
        .D(pc_value),
        .Q(pc_backup),
        .CLK(clk),
        .RES(res),
        .ENABLE(pc_backup_en)    
    );
    
    //instruction register  
    //Is it a good idea to reset the register after completing one instruction
    //Is it a good idea to connect the enable port with a logic gate 
    assign instr_reg_en  = instr_r_valid & instr_en;
    assign instr_reg_rst = instr_rst | res;
    REG_DRE_32 instr_reg(
        .D(instr_read),
        .Q(instr),
        .CLK(clk),
        .RES(instr_reg_rst),
        .ENABLE(instr_reg_en)
    );
    
    //Control unit
    assign instr_opcode = instr[6:0];
    ctrl ctrl_unit(
        .clk(clk),
        .res(res),
        
        .instr_gnt(instr_gnt),
        .instr_r_valid(instr_r_valid),
        .instr_req(instr_req),  
        .instr_opcode(instr_opcode),
   
        .data_gnt(data_gnt),
        .data_r_valid(data_r_valid),
        .data_req(data_req),
        .data_write_enable(data_write_enable),
        
        .irq(irq),
        .irq_ack(irq_ack),
        
        .mret(mret),
        
        .times_required(times_required),
        .mem_access(mem_access),
        .mem_write(mem_write), 
        .finished_once(finished_once),  
        
        .pc_en(pc_en),
        .pc_backup_en(pc_backup_en),
        .instr_en(instr_en),
        .instr_rst(instr_rst),
        .irq_id_en(irq_id_en),
        .irq_ack_id_en(irq_ack_id_en),
        .INT(INT),
        .instr_done(instr_done),
        .ctr_code(ctr_code)
    ); 
    assign mret     = (instr_opcode == `OPCODE_MRET && instr[14:12] == 3'b000) ? 1'b1 : 1'b0;
    assign CSRReq   = ctr_code[13];
    assign Branch   = ctr_code[12];
    assign MemtoReg = ctr_code[11];
    assign ALUSrc   = ctr_code[10];
    assign RegWrite = ctr_code[9];
    assign LUI      = ctr_code[8];
    assign ALUtoMem = ctr_code[7];
    assign Jump     = ctr_code[6];
    assign JAL      = ctr_code[5];
    assign RET      = ctr_code[4];
    assign ALUOp    = ctr_code[3:0];
    
    //CSR
    CSR #(.ID(ID)) csr_unit(
        .clk(clk),
        .res(res),
        .request(CSRReq),
        .instr_done(instr_done),
        .A(instr[31:20]),
        .mode(reg_read_Q0),
        .Q(csr_data)
    );
    
    //Iinterrupt
    //irq id
    int_proc irq_id_reg(
        .clk(clk),
        .res(res),
        .enable(irq_id_en),
        .irq_id_D(irq_id),
        .irq_id_Q(cur_irq_id)
    );    
    assign irq_ack_id = irq_ack_id_en ? cur_irq_id : 5'b00000;
    //assign irq_ack_id = cur_irq_id;
    
    
    //Register set
    register register_set(
        .D(reg_write_data),          //Data input
        .A_D(instr[11:7]),           //Destination address for the input data D
        .A_Q0(instr[19:15]),         //Address for output data Q0, Q1
        .A_Q1(instr[24:20]),
        .write_enable(RegWrite),    //if write_enable = '1', then the input data is written into the register
        .RES(res),                  //Reset, if RES = '1', all registers are set to 0
        .CLK(clk),                  //Clock input
        .Q0(reg_read_Q0),           //Data output
        .Q1(reg_read_Q1)            //Data output       
    );
    
    //Immediate generator
    imm_gen imm_gen_unit(
        .instr(instr),
        .imm(imm)
    );
    
    //ALU control
    ALU_control alu_ctrl_unit(
        .ALUOp(ALUOp),
        .func_bits({instr[30],instr[25],instr[14:12]}),
        .alu_ctr(alu_ctrl)    
    );
    
    //ALU source opeand 2 selection mux
    MUX_2x1_32 mux_alu_rs2(
        .I0(reg_read_Q1),
        .I1(imm),
        .S(ALUSrc),
        .Y(alu_rs2)
    );
  
    //ALU unit
    assign alu_rs1 = reg_read_Q0; 
    alu alu_unit(
        .alu_ctr(alu_ctrl),
        .alu_rs1(alu_rs1),
        .alu_rs2(alu_rs2),
        .alu_res(alu_result),
        .alu_cmp(alu_cmp)
    );
    
    //memmory access control unit
    mem_access_ctrl mem_access_ctrl_unit(
        .clk(clk),
        .res(res),
        .access(mem_access),
        .write(mem_write),
        .finished_once(finished_once),
        .width(instr[14:12]),
        .addr_pre(alu_result),
        .data_from_mem(data_read),
        .data_from_reg(reg_read_Q1),
        .times_required(times_required), 
        .data_be(data_be),
        .addr_post(data_addr),
        .data_to_mem(data_write),
        .data_to_reg(load_data)
    );
    
    //select data generated by LUI or AUIPC
    assign data_LUI = imm;
    assign data_AUIPC = pc_value + imm;    
    MUX_2x1_32 mux_LUI(
        .I0(data_AUIPC),
        .I1(data_LUI),
        .S(LUI),
        .Y(post_mux_LUI)
    );
    
    //select value generated by jump or winner between LUI and AUIPC
    assign data_jump = pc_value + 4;
    MUX_2x1_32 mux_Jump(
        .I0(post_mux_LUI),
        .I1(data_jump),
        .S(Jump),
        .Y(post_mux_Jump)
    );   
    
    MUX_2x1_32 mux_CSR(
        .I0(alu_result),
        .I1(csr_data),
        .S(CSRReq),
        .Y(post_mux_CSR)
    );

    MUX_2x1_32 mux_prev_mem(
        .I0(post_mux_CSR),
        .I1(post_mux_Jump),
        .S(ALUtoMem),
        .Y(data_prev_mem)
    );
             
    MUX_2x1_32 mux_post_mem(
        .I0(data_prev_mem),
        .I1(load_data),
        .S(MemtoReg),
        .Y(reg_write_data)
    );     
endmodule
