`timescale 1ns / 1ps

class MemoryClass;
    rand  bit [31:0]  Memory [4096];
endclass

module ahb3lite_memory(

    input  logic [31:0] WR_addr,
    input  logic read_flag,
    input  logic write_flag,
    output logic [31:0] HRDATA,
    input  logic [31:0] HWDATA,

    input  logic monitor_flag,
    input  logic [31:0] monitor_addr,
    output logic [31:0] monitor_DATA,

    output bit BUSY //simulate the case where the memory is read by others (used explicitly by testbench)
    );
    MemoryClass MemoryClass_init = new;

    // Read Data from Memory to slave
    assign HRDATA       = (read_flag == 1)? MemoryClass_init.Memory[WR_addr]: 0;
    // Write Data to Memory
    assign MemoryClass_init.Memory[WR_addr] = (write_flag == 1)? HWDATA: 0;
    // Read Data from Memory to verifier
    assign monitor_DATA = (monitor_flag == 1)? MemoryClass_init.Memory[monitor_addr]: 0;

endmodule
