`timescale 1ns / 1ps

import ahb3lite_pkg::* ;

module FIFO_Reader_Helper(
    input  bit           CLK,
    input  logic         RESETn,
    
    input  logic         Read_Request,

    input  logic         [5:0] i_RCC_BUFFER_LENGTH,
    input  logic         i_FIFO_empty,
    input  logic         [31 : 0] i_FIFO_dout,
    output logic         o_FIFO_rd_en,

    output logic         [7:0] serialized_output,
    output logic         serialized_output_valid,

    output logic         [1:0]  Serialize_Counter,
    output logic         [15:0] Bytes_Counter,
    output logic         [15:0] RCC_BYTE_CNT,

    output logic         FIFO_Reader_Done
    );

    FIFO_Reader_Help_state    State;

    logic                [15:0] Words_Counter;
    logic                [15:0] RCC_Words_N;

    logic                internal_read_enable;

    assign RCC_BYTE_CNT = (serialized_output_valid == 1) ? (i_RCC_BUFFER_LENGTH - Bytes_Counter) : 0;

    always_ff@(posedge CLK) begin
        if (!RESETn) begin
            State         <= Helper_IDLE;
            Words_Counter <= 0;
            Serialize_Counter <= 0;
            Bytes_Counter <= 0;
            internal_read_enable <= 0;
            FIFO_Reader_Done     <= 0;

        end else begin
            case (State)
                Helper_IDLE : begin 
                    Serialize_Counter <= 0;
                    internal_read_enable <= 0;
                    FIFO_Reader_Done  <= 0;

                    if ((i_RCC_BUFFER_LENGTH[0] | i_RCC_BUFFER_LENGTH[1]) == 0)
                        RCC_Words_N  <= (i_RCC_BUFFER_LENGTH >> 2);
                    else 
                        RCC_Words_N  <= (i_RCC_BUFFER_LENGTH >> 2) + 1;
                        
                    if (Read_Request && i_FIFO_empty == 0 && FIFO_Reader_Done == 0)  begin 
                        Bytes_Counter <= 1;
                        Words_Counter <= 1;
                        State <= Helper_READ;  
                        internal_read_enable <= 1;                          
                    end else begin
                        Bytes_Counter <= 0;
                        Words_Counter <= 0;
                        State <= Helper_IDLE;
                    end
                end

                Helper_READ : begin 
                    if (Read_Request && i_FIFO_empty == 0)  begin  
                        // Update Serialize Counter 
                        case (Serialize_Counter)
                            0, 1, 2: begin
                                Serialize_Counter <= Serialize_Counter + 1;
                            end

                            3: begin
                                Serialize_Counter <= 0;

                                if (Words_Counter <= RCC_Words_N - 1  && i_FIFO_empty == 0) 
                                    Words_Counter <= Words_Counter + 1;
                                else begin 
                                    Words_Counter <= 0;
                                    State <= Helper_IDLE;
                                end
                            end 
                        endcase

                        if (Bytes_Counter == i_RCC_BUFFER_LENGTH) begin 
                            Bytes_Counter <= Bytes_Counter  + 1;
                            internal_read_enable <= 0;                       
                            State <= Helper_IDLE;
                            FIFO_Reader_Done <= 1;
                        end else begin 
                            Bytes_Counter <= Bytes_Counter  + 1;
                            internal_read_enable <= 1; 
                            State <= State;   
                        end

                    end else begin 
                        Serialize_Counter <= Serialize_Counter;
                        Words_Counter     <= Words_Counter;
                        Bytes_Counter     <= Bytes_Counter;
                        internal_read_enable <= 0; 

                        if (Bytes_Counter == i_RCC_BUFFER_LENGTH) begin 
                            State <= Helper_IDLE;
                            FIFO_Reader_Done <= 1;
                        end else begin 
                            State <= State;   
                        end
                    end
                end

            endcase
        end
    end
    
    always_comb begin
        if (internal_read_enable == 1) begin 
            case (Serialize_Counter)
                    0: begin
                        serialized_output = i_FIFO_dout[31:24];
                        o_FIFO_rd_en  = 0;
                    end 
                    1: begin
                        serialized_output = i_FIFO_dout[23:16];
                        o_FIFO_rd_en  = 0;
                    end 
                    2: begin
                        serialized_output = i_FIFO_dout[15:8];
                        o_FIFO_rd_en  = 0;
                    end 
                    3: begin
                        serialized_output = i_FIFO_dout[7:0];
                        o_FIFO_rd_en  = 1;
                    end 
            endcase
            if (Bytes_Counter <= i_RCC_BUFFER_LENGTH)
                serialized_output_valid = 1;
            else 
                serialized_output_valid = 0;
        end else begin 
            if (FIFO_Reader_Done == 1) 
                o_FIFO_rd_en = 1;
            else 
                o_FIFO_rd_en = 0;

            serialized_output = 0;
            serialized_output_valid = 0;
        end
    end


endmodule
