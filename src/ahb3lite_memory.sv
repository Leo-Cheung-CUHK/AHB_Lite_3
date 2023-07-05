`timescale 1ns / 1ps

class MemoryClass;
    rand  bit [31:0]  Memory [4096];
endclass

module ahb3lite_memory(

    input logic read_flag,
    input logic [31:0] WR_addr,
    output logic [31:0] HRDATA,

    input logic read_flag_1,
    input logic [31:0] WR_addr_1,
    output logic [31:0] HRDATA_1,

    output bit BUSY //simulate the case where the memory is read by others (used explicitly by testbench)
    );
    MemoryClass MemoryClass_init = new;

    assign HRDATA   = (read_flag == 1)? MemoryClass_init.Memory[WR_addr]: 0;
    assign HRDATA_1 = (read_flag_1 == 1)? MemoryClass_init.Memory[WR_addr_1]: 0;

endmodule
