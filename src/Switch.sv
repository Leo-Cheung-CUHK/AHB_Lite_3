`timescale 1ns / 1ps

module Switch(    
                input  logic HCLK, 
                input  logic HRESETn,

                input  logic WriteSystem_slave_done,
                input  logic ReadSystem_slave_done,
                input  logic Other_slave_done,

                input  HTRANS_state WriteSystem_HTRANS,
                input  HTRANS_state ReadSystem_HTRANS,
                input  HTRANS_state Other_HTRANS,

                output logic WriteSystem_HREADY,                
                output logic ReadSystem_HREADY,
                output logic Other_HREADY              
    );

    logic [2:0] Ongoing_v;
    logic [2:0] Choice_v;

    assign WriteSystem_HREADY = Choice_v[0];
    assign ReadSystem_HREADY  = Choice_v[1];
    assign Other_HREADY       = Choice_v[2];


    always_ff @(posedge HCLK) begin

        if (!HRESETn == 1)  
            Ongoing_v          <= 0;
        else begin 

            if (WriteSystem_slave_done == 1)  
                Ongoing_v[0] <= 0;
            else if (WriteSystem_HTRANS == NONSEQ && Ongoing_v[0] == 0)  
                Ongoing_v[0] <= 1;
            else  
                Ongoing_v[0] <= Ongoing_v[0];

            if (ReadSystem_slave_done == 1)  
                Ongoing_v[1] <= 0;
            else if (ReadSystem_HTRANS == NONSEQ && Ongoing_v[1] == 0) 
                Ongoing_v[1] <= 1;
            else  
                Ongoing_v[1] <= Ongoing_v[1];

            if (Other_slave_done == 1) 
                Ongoing_v[2] <= 0;
            else if (Other_HTRANS == NONSEQ && Ongoing_v[2] == 0) 
                Ongoing_v[2] <= 1;
            else 
                Ongoing_v[2] <= Ongoing_v[2];
        end
    end

    always_ff @(posedge HCLK ) begin
        if (!HRESETn == 1)  
            Choice_v <= 0;
        else begin 
            if (Choice_v[0] == 1) begin 
                if (Ongoing_v[0] == 0) begin 
                    Choice_v[0] <= 0;

                    if (Ongoing_v[1] == 1) 
                        Choice_v[1] <= 1;
                    else if (Ongoing_v[2] == 1) 
                        Choice_v[2] <= 1;
                    else 
                        Choice_v    <= 0;
                end else 
                    Choice_v <= Choice_v;

            end else if (Choice_v[1] == 1) begin 
                if (Ongoing_v[1] == 0) begin 
                    Choice_v[1] <= 0;

                    if (Ongoing_v[0] == 1) 
                        Choice_v[0] <= 1;
                    else if (Ongoing_v[2] == 1) 
                        Choice_v[2] <= 1;
                    else 
                        Choice_v    <= 0;
                end else 
                    Choice_v <= Choice_v;

            end else if (Choice_v[2] == 1) begin 
                if (Ongoing_v[2] == 0) begin 
                    Choice_v[2] <= 0;

                    if (Ongoing_v[0] == 1) 
                        Choice_v[0] <= 1;
                    else if (Ongoing_v[1] == 1) 
                        Choice_v[1] <= 1;
                    else 
                        Choice_v    <= 0;
                end else 
                    Choice_v <= Choice_v;

            end else begin 
                if (Ongoing_v[0] == 1) 
                    Choice_v[0] <= 1;
                else if (Ongoing_v[1] == 1) 
                    Choice_v[1] <= 1;
                else if (Ongoing_v[2] == 1) 
                    Choice_v[2] <= 1;
                else 
                    Choice_v    <= 0;
            end
        end
    end
        
endmodule
