`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/25/2022 03:24:00 PM
// Design Name: 
// Module Name: system
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


module system(
    input BOARD_CLK,
    input BOARD_RESN,
    output [3:0] BOARD_LED,
    output [2:0] BOARD_LED_RGB0,
    output [2:0] BOARD_LED_RGB1,
    input [3:0] BOARD_BUTTON,
    input [3:0] BOARD_SWITCH,
    output BOARD_VGA_HSYNC,
    output BOARD_VGA_VSYNC,
    output [3:0] BOARD_VGA_R,
    output [3:0] BOARD_VGA_G,
    output [3:0] BOARD_VGA_B,
    input BOARD_UART_RX,
    output BOARD_UART_TX
);
    reg clk;
    `ifdef XILINX_SIMULATOR
    // Vivado Simulator (XSim) specific code
    initial
        begin
            clk=0;
        end
        always
        #5 clk=~clk;
     `else
        always @(BOARD_CLK)
            clk=BOARD_CLK;
    `endif
            
    wire clk_proc, res;
    wire cached_instr_req_1, cached_instr_gnt_1, cached_instr_rvalid_1;
    wire instr_gnt_1, instr_rvalid_1, instr_req_1;
    wire [31:0] cached_instr_adr_1, instr_adr_1, instr_read_1, cached_instr_read_1;
    
    wire cached_instr_req_2, cached_instr_gnt_2, cached_instr_rvalid_2;
    wire instr_gnt_2, instr_rvalid_2, instr_req_2;
    wire [31:0] cached_instr_adr_2, instr_adr_2, instr_read_2, cached_instr_read_2;
    
    wire instr_req, instr_gnt, instr_rvalid;
    wire [31:0] instr_adr, instr_read;
    
    wire data_gnt_1, data_r_valid_1, data_req_1, data_write_enable_1;
    wire [3:0] data_be_1;
    wire [31:0] data_read_1, data_addr_1, data_write_1;
    
    wire data_gnt_2, data_r_valid_2, data_req_2, data_write_enable_2;
    wire [3:0] data_be_2;
    wire [31:0] data_read_2, data_addr_2, data_write_2;
    
    wire data_req, data_gnt, data_r_valid, data_write_enable;
    wire [3:0] data_be;
    wire [31:0] data_read, data_addr, data_write;
    
    
    wire irq, irq_ack;
    wire [4:0] irq_id, irq_ack_id;  
    
    wire cache_res;
    proc #(.ID(1)) processor_1(
        //Group 1
        .clk(clk_proc),
        .res(res),
        
        //Group 2    
        .instr_gnt(cached_instr_gnt_1),
        .instr_r_valid(cached_instr_rvalid_1),
        .instr_read(cached_instr_read_1),
        .instr_req(cached_instr_req_1),
        .instr_addr(cached_instr_adr_1),
        
        //Group 3   
        .data_gnt(data_gnt_1),
        .data_r_valid(data_r_valid_1),
        .data_read(data_read_1),
        .data_req(data_req_1),
        .data_write_enable(data_write_enable_1),
        .data_be(data_be_1),
        .data_addr(data_addr_1),   
        .data_write(data_write_1),
        
        //Group 4
        .irq(irq),
        .irq_id(irq_id),
        .irq_ack(irq_ack),
        .irq_ack_id(irq_ack_id)
    );
    
    instr_cache #(.LOG_SIZE(6)) instr1(
        .clk(clk_proc),
        .res(cache_res),

        .cached_instr_req(cached_instr_req_1),
        .cached_instr_adr(cached_instr_adr_1),
        .cached_instr_gnt(cached_instr_gnt_1),
        .cached_instr_rvalid(cached_instr_rvalid_1),
        .cached_instr_read(cached_instr_read_1),
        
        .instr_gnt(instr_gnt_1),
        .instr_rvalid(instr_rvalid_1),
        .instr_read(instr_read_1),
        .instr_req(instr_req_1),
        .instr_adr(instr_adr_1)         
    );
    
    proc #(.ID(2)) processor_2(
            //Group 1
            .clk(clk_proc),
            .res(res),
            
            //Group 2    
            .instr_gnt(cached_instr_gnt_2),
            .instr_r_valid(cached_instr_rvalid_2),
            .instr_read(cached_instr_read_2),
            .instr_req(cached_instr_req_2),
            .instr_addr(cached_instr_adr_2),
            
            //Group 3   
            .data_gnt(data_gnt_2),
            .data_r_valid(data_r_valid_2),
            .data_read(data_read_2),
            .data_req(data_req_2),
            .data_write_enable(data_write_enable_2),
            .data_be(data_be_2),
            .data_addr(data_addr_2),   
            .data_write(data_write_2),
            
            //Group 4, for the moment, proc 2 doesn't process any interrupts
            .irq(1'b0),
            .irq_id(5'b00000),
            .irq_ack(irq_ack),
            .irq_ack_id(irq_ack_id)
        );
    instr_cache #(.LOG_SIZE(6)) instr_2(
            .clk(clk_proc),
            .res(cache_res),
    
            .cached_instr_req(cached_instr_req_2),
            .cached_instr_adr(cached_instr_adr_2),
            .cached_instr_gnt(cached_instr_gnt_2),
            .cached_instr_rvalid(cached_instr_rvalid_2),
            .cached_instr_read(cached_instr_read_2),
            
            .instr_gnt(instr_gnt_2),
            .instr_rvalid(instr_rvalid_2),
            .instr_read(instr_read_2),
            .instr_req(instr_req_2),
            .instr_adr(instr_adr_2)         
        );
        
    arbitrator arbitrator_1(
             .clk(clk_proc),
             .res(res),
             
             .instr_req_1(instr_req_1),
             .instr_adr_1(instr_adr_1),
             
             .instr_req_2(instr_req_2),
             .instr_adr_2(instr_adr_2),
             
             .instr_req(instr_req),
             .instr_adr(instr_adr),
             .data_req(data_req),
             .data_addr(data_addr),     
                
             .instr_gnt(instr_gnt),
             .instr_rvalid(instr_rvalid),
             .instr_read(instr_read),
             
             .instr_gnt_1(instr_gnt_1),
             .instr_rvalid_1(instr_rvalid_1),
             .instr_read_1(instr_read_1),
             
             .instr_gnt_2(instr_gnt_2),
             .instr_rvalid_2(instr_rvalid_2),
             .instr_read_2(instr_read_2),
             
             .data_req_1(data_req_1),
             .data_write_enable_1(data_write_enable_1),
             .data_write_1(data_write_1),
             .data_be_1(data_be_1),
             .data_addr_1(data_addr_1),
              
             .data_req_2(data_req_2),
             .data_write_enable_2(data_write_enable_2),
             .data_write_2(data_write_2),
             .data_be_2(data_be_2),
             .data_addr_2(data_addr_2),
             
             .data_gnt(data_gnt),
             .data_r_valid(data_r_valid),
             .data_read(data_read),
             
             .data_gnt_1(data_gnt_1),
             .data_r_valid_1(data_r_valid_1),
             .data_read_1(data_read_1),
             
             .data_gnt_2(data_gnt_2),
             .data_r_valid_2(data_r_valid_2),
             .data_read_2(data_read_2)
        );
    
    pulpus pul(
         /* BOARD SIGNALS */
         .BOARD_CLK(clk),
         .BOARD_RESN(BOARD_RESN),   
         
         .BOARD_LED(BOARD_LED),
         .BOARD_LED_RGB0(BOARD_LED_RGB0),
         .BOARD_LED_RGB1(BOARD_LED_RGB1),
         
         .BOARD_BUTTON(BOARD_BUTTON),
         .BOARD_SWITCH(BOARD_SWITCH),
         
         .BOARD_VGA_HSYNC(BOARD_VGA_HSYNC),
         .BOARD_VGA_VSYNC(BOARD_VGA_VSYNC),
         .BOARD_VGA_R(BOARD_VGA_R),
         .BOARD_VGA_B(BOARD_VGA_B),
         .BOARD_VGA_G(BOARD_VGA_G),      
         .BOARD_UART_RX(BOARD_UART_RX),
         .BOARD_UART_TX(BOARD_UART_TX),  
         /* CORE SIGNALS */
         .CPU_CLK(clk_proc),  
         .CPU_RES(res),
         .CACHE_RES(cache_res), 
         // Instruction memory interface
         .INSTR_REQ(instr_req),
         .INSTR_GNT(instr_gnt),
         .INSTR_RVALID(instr_rvalid),
         .INSTR_ADDR(instr_adr),
         .INSTR_RDATA(instr_read),
       
         // Data memory interface
         .DATA_REQ(data_req),
         .DATA_GNT(data_gnt),
         .DATA_RVALID(data_r_valid),
         .DATA_WE(data_write_enable),
         .DATA_BE(data_be),
         .DATA_ADDR(data_addr),
         .DATA_WDATA(data_write),
         .DATA_RDATA(data_read),
         // Interrupt outputs
         .IRQ(irq),                 // level sensitive IR lines
         .IRQ_ID(irq_id),
         // Interrupt inputs
         .IRQ_ACK(irq_ack),             // irq ack
         .IRQ_ACK_ID(irq_ack_id)                  
      );    
    
endmodule
