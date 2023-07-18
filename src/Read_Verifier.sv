`timescale 1ns / 1ps
module Read_Verifier(
    input  bit          CLK,
    input  logic        RESETn,

    input logic         [15:0] i_RCC_DMA_ADDR_HIGH,
    input logic         [15:0] i_RCC_DMA_ADDR_LOW,
    input logic         [5:0]  i_RCC_BUFFER_LENGTH,

    input  logic        Read_Request,

    input logic         i_Reader_FIFO_rd_en,
    input logic         [7:0] i_serialized_output,
    input logic         i_serialized_output_valid,
    input logic         [1:0] Serialize_Counter,

    output logic        DMA_READ,
    output logic        [31:0] DMA_READ_addr,
    input logic         [31:0] i_HRDATA
    );

    logic               data_error;
    logic               [31:0] internal_HRDATA;
    Verifier_state      State;
    logic               [31:0] bytes_counter;
    logic               len_error;

    always_ff@(posedge CLK) begin
        if (!RESETn) begin
            State <= Verifier_IDLE;
            DMA_READ_addr   <= 0;

        end else begin
            case (State)
                Verifier_IDLE : begin 
                    if (Read_Request == 1) begin
                        State            <= Verifier_Start;
                        DMA_READ         <= 1;
                        DMA_READ_addr    <= {i_RCC_DMA_ADDR_HIGH, i_RCC_DMA_ADDR_LOW};

                    end else begin
                        State           <= State;
                        DMA_READ        <= 0;
                        DMA_READ_addr   <= 0;
                    end
                end

                Verifier_Start : begin 
                    DMA_READ      <= 0; 
                    DMA_READ_addr <= DMA_READ_addr;

                    if (i_serialized_output_valid == 1) 
                        State <= Verifier_CHECK;
                    else
                        State <= State;
                end

                Verifier_CHECK : begin 
                    if  (i_Reader_FIFO_rd_en == 1) begin
                        DMA_READ      <= 1;
                        DMA_READ_addr <= DMA_READ_addr - 1;

                    end else begin
                        DMA_READ      <= 0; 
                        DMA_READ_addr <= DMA_READ_addr;
                    end

                    if (i_serialized_output_valid == 0) 
                        State <= Verifier_IDLE;
                    else
                        State <= State;
                end

                default: begin
                    State <= Verifier_IDLE;
                    DMA_READ        <= 0;
                    DMA_READ_addr   <= 0;
                end
            endcase
        end
    end

    always_ff@(posedge CLK) begin
        if (!RESETn) begin
            bytes_counter <= 0;
            len_error     <= 0;

        end else begin
            case (State)
                Verifier_Start : begin 
                    if (i_serialized_output_valid == 1)
                        bytes_counter <= bytes_counter + 1;
                    else 
                        bytes_counter <= 0;
                end

                Verifier_CHECK : begin 
                    if (i_serialized_output_valid == 1)
                        bytes_counter <= bytes_counter + 1;
                    else begin
                        if (bytes_counter != i_RCC_BUFFER_LENGTH)
                            len_error <= 1;
                        else 
                            len_error <= 0;
                        
                        bytes_counter <= 0;
                    end
                end

                default: begin
                    len_error     <= 0;
                    bytes_counter <= 0;
                end
            endcase
        end
    end

    always_comb begin
        case (State)
            Verifier_Start, Verifier_CHECK : begin 
                if (DMA_READ == 1)
                    internal_HRDATA = i_HRDATA;
                else
                    internal_HRDATA = internal_HRDATA;

                if (i_serialized_output_valid == 1) 
                    case (Serialize_Counter)
                        0 : begin
                            data_error = (i_serialized_output != internal_HRDATA[31:24]) ? 1 : 0;
                        end
                        1 : begin
                            data_error = (i_serialized_output != internal_HRDATA[23:16]) ? 1 : 0;
                        end
                        2 : begin
                            data_error = (i_serialized_output != internal_HRDATA[15:8]) ? 1 : 0;
                        end
                        3 :begin
                            data_error = (i_serialized_output != internal_HRDATA[7:0]) ? 1 : 0;
                        end
                    endcase 
                else
                    data_error = 0;
            end

            default: begin
                data_error      = 0;
                internal_HRDATA = 0;
            end
        endcase
    end
endmodule
