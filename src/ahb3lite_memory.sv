`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.06.2023 15:16:11
// Design Name: 
// Module Name: ahb3lite_memory
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
class MemoryClass;
    rand  bit [7:0]  Memory [4096];
endclass

module ahb3lite_memory(

    input logic read_flag,
    input logic [31:0] WR_addr,
    output logic [31:0] HRDATA,

    input logic read_flag_1,
    input logic [31:0] WR_addr_1,
    output logic [31:0] HRDATA_1

    );
    MemoryClass MemoryClass_init = new();

    assign HRDATA = (read_flag == 1)? 
    {MemoryClass_init.Memory[WR_addr + 3],MemoryClass_init.Memory[WR_addr + 2],MemoryClass_init.Memory[WR_addr + 1],MemoryClass_init.Memory[WR_addr]} 
    : 0;

    assign HRDATA_1 = (read_flag_1 == 1)? 
    {MemoryClass_init.Memory[WR_addr_1 + 3],MemoryClass_init.Memory[WR_addr_1 + 2],MemoryClass_init.Memory[WR_addr_1 + 1],MemoryClass_init.Memory[WR_addr_1]} 
    : 0;

endmodule
