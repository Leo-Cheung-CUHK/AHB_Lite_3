`timescale 1ns / 1ps

module Switch(    
                input  logic HCLK, 
                input  logic HRESETn,

                input  logic CoreSystem_slave_done,
                input  logic CPU_slave_done,
                input  logic Other_slave_done,

                input  HTRANS_state CoreSystem_HTRANS,
                input  HTRANS_state CPU_HTRANS,
                input  HTRANS_state Other_HTRANS,

                output logic CPU_HREADY,                
                output logic CoreSystem_HREADY,
                output logic Other_HREADY              
    );

    logic CoreSystem_Ongoing;
    logic CPU_Ongoing;
    logic Other_Ongoing;

    always_ff @(posedge HCLK) begin
        if (!HRESETn == 1) begin 
            CoreSystem_Ongoing <= 0;
            CPU_Ongoing        <= 0;
            Other_Ongoing      <= 0;
        end else begin 
            if (CoreSystem_slave_done == 1)
                CoreSystem_Ongoing <= 0;
            else if (CoreSystem_HTRANS == NONSEQ && CoreSystem_Ongoing == 0)
                CoreSystem_Ongoing <= 1;
            else 
                CoreSystem_Ongoing <= CoreSystem_Ongoing;

            if (CPU_slave_done == 1)
                CPU_Ongoing <= 0;
            else if (CPU_HTRANS == NONSEQ && CPU_Ongoing == 0)
                CPU_Ongoing <= 1;
            else 
                CPU_Ongoing <= CPU_Ongoing;

            if (Other_slave_done == 1)
                Other_Ongoing <= 0;
            else if (Other_HTRANS == NONSEQ && Other_Ongoing == 0)
                Other_Ongoing <= 1;
            else 
                Other_Ongoing <= Other_Ongoing;
        end
    end
    
    // Switch logic
    always_comb begin 
        if (!HRESETn == 1) begin 
            CPU_HREADY = 0;                
            CoreSystem_HREADY = 0;
            Other_HREADY = 0;     
        end else begin
            if (CPU_Ongoing == 1) begin
                CPU_HREADY = 1;
                CoreSystem_HREADY = 0;
                Other_HREADY = 0;     
            end else if (CPU_Ongoing == 0 && CoreSystem_Ongoing == 1) begin 
                CPU_HREADY = 0;
                CoreSystem_HREADY = 1;
                Other_HREADY = 0;  
            end else if (CPU_Ongoing == 0 && CoreSystem_Ongoing == 0 && Other_Ongoing == 1) begin 
                CPU_HREADY = 0;
                CoreSystem_HREADY = 0;
                Other_HREADY = 1; 
            end else begin 
                CPU_HREADY = 0;
                CoreSystem_HREADY = 0;
                Other_HREADY = 0; 
            end
        end
    end

endmodule
