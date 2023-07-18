`timescale 1ns / 1ps

module external_memory(    
                input  logic HCLK, 
                input  logic HRESETn,

                input  logic [31:0] READ_addr,
                input  logic read_flag,
                output logic [31:0] HRDATA,

                input  logic [31:0] WRITE_addr,
                input  logic write_flag,
                input  logic [31:0] HWDATA,

                input  logic monitor_flag,
                input  logic [31:0] monitor_addr,
                output logic [31:0] monitor_DATA
    );
    bit [31:0]  Memory [4096];

    always_comb begin
        if (read_flag == 1) 
            HRDATA = Memory[READ_addr];
    end

    always_comb begin
        if (monitor_flag == 1) 
            monitor_DATA = Memory[monitor_addr];
    end

    always_ff@(posedge HCLK) begin 
        if (write_flag == 1)
           Memory[WRITE_addr] <= HWDATA;
    end

endmodule
