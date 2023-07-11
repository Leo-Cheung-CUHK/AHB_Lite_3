`timescale 1ns / 1ps

module Switch(    
                input  logic HCLK, 
                input  logic HRESETn,

                output logic CPU_HREADY,                
                output logic CoreSystem_HREADY                
    );

    // TODO: Switch logic
    assign  CPU_HREADY = 1;
    assign  CoreSystem_HREADY = 1;

endmodule
