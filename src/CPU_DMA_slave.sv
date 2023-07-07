import ahb3lite_pkg::* ;

    module CPU_DMA_slave
    (
                // Global signals       
                input bit HCLK,
                input logic HRESETn,

                input logic [31:0] HADDR,
                input logic [31:0] HWDATA,
                input logic HWRITE,

                input HBURST_Type HBURST,
                input logic [2:0] HSIZE,
                input HTRANS_state HTRANS,

                output HRESP_state HRESP,
                output logic HREADY,
                
                // Memory signals
                output logic [31:0] mem_WR_addr, 
                output logic  mem_write_flag,
                output logic [31:0] HWDATA_toMem            
    );
    node_state State;
    logic ReadyOn;
    logic WAIT_STATE_ON;

    task  Configure_Slave(input logic i_ReadyOn);
        ReadyOn  <= i_ReadyOn;
    endtask 

    assign HWDATA_toMem = (mem_write_flag == 1) ? HWDATA : 0;

    always_ff@(posedge HCLK )
    begin
        if (HRESETn == 0) begin
            State              <= Idle;
            HREADY             <= 0;
            mem_WR_addr        <= 0;
            HRESP              <= OKAY;
        end else begin
            case(State)
                Idle: begin 
                    HRESP           <= OKAY;
                    mem_WR_addr     <= 0;

                    if (ReadyOn == 1) begin 
                        State       <= GetReady;
                        HREADY      <= 1;
                    end else  begin 
                        State       <= State;
                        HREADY      <= 0;
                    end
                end

                GetReady: begin
                    if (HTRANS == NONSEQ) begin 
                        State       <= Data_Phase;
                        mem_WR_addr <= HADDR; 
                    end else begin 
                        State       <= State;
                        mem_WR_addr <= 32'b0; 
                    end
                end

                Data_Phase: begin
                    if (HBURST == SINGLE) begin
                        if (HTRANS == NONSEQ) begin
                            // SINGLE Busrts
                            State        <= State;
                            mem_WR_addr  <= HADDR; 
                        end else begin 
                            State        <= Idle;
                            mem_WR_addr  <= 32'b0; 
                        end
                
                    end else if (HBURST == INCR || HBURST == INCR4 || HBURST == INCR8 || HBURST == INCR16) begin
                        if (HTRANS == SEQ) begin 
                            State       <= State;
                            mem_WR_addr <= HADDR; 
                        end else if (HTRANS == IDLE) begin
                            State       <= Idle;
                            mem_WR_addr <= 32'b0; 
                        end else begin 
                            State       <= Idle;
                            mem_WR_addr <= 32'b0; 
                        end 

                    end else begin 
                        State        <= Idle;
                        mem_WR_addr  <= 32'b0; 
                    end
                end

                default: begin
                    State               <= Idle;
                    HREADY              <= 1;
                    mem_WR_addr         <= 0;
                end
            endcase
        end
    end

    always_comb
    begin 
        case(State)
            Data_Phase: begin 
                if(HWRITE == 1) 
                    mem_write_flag = 1;
                else  
                    mem_write_flag = 0;
            end 

            default: begin
                mem_write_flag    = 0;
            end

        endcase
    end

    endmodule