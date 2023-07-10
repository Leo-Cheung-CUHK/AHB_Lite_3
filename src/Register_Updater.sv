`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.06.2023 11:09:46
// Design Name: 
// Module Name: CPU_Registers
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
import ahb3lite_pkg::* ;


module Register_Updater(
    input  bit           HCLK,
    input  logic         HRESETn,

    output logic  [5:0]  o_RCC_BUFFER_LENGTH,
    output logic  [15:0] o_RCC_DMA_ADDR_HIGH,
    output logic  [15:0] o_RCC_DMA_ADDR_LOW
);
    bit   NewCommandFlag;

    logic  [5:0]  RCC_BUFFER_LENGTH;
    logic  [15:0] RCC_DMA_ADDR_HIGH;
    logic  [15:0] RCC_DMA_ADDR_LOW;

    task CPU_Reg_Write(input logic [15:0] i_RCC_DMA_ADDR_HIGH, input logic [15:0] i_RCC_DMA_ADDR_LOW,  input logic [5:0] i_RCC_BUFFER_LENGTH);        
           @(posedge HCLK) begin
                NewCommandFlag    <= 1;
                RCC_DMA_ADDR_HIGH <= i_RCC_DMA_ADDR_HIGH;
                RCC_DMA_ADDR_LOW  <= i_RCC_DMA_ADDR_LOW;
                RCC_BUFFER_LENGTH <= i_RCC_BUFFER_LENGTH;
           end
    endtask;

    always_ff@(posedge HCLK)
    begin
        if (!HRESETn) begin
            
            RCC_BUFFER_LENGTH <= 0;
            RCC_DMA_ADDR_HIGH <= 0;
            RCC_DMA_ADDR_LOW  <= 0;

            o_RCC_BUFFER_LENGTH <= 0;
            o_RCC_DMA_ADDR_HIGH <= 0;
            o_RCC_DMA_ADDR_LOW  <= 0;

            NewCommandFlag      <= 0;

        end else begin
            if (NewCommandFlag == 1) begin 
                    NewCommandFlag      <= 0;

                    o_RCC_BUFFER_LENGTH <= RCC_BUFFER_LENGTH;
                    o_RCC_DMA_ADDR_HIGH <= RCC_DMA_ADDR_HIGH;
                    o_RCC_DMA_ADDR_LOW  <= RCC_DMA_ADDR_LOW ;  
            end
        end
    end

endmodule