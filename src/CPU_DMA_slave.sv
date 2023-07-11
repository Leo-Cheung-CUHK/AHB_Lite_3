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
                input  logic HREADY,
                output logic HREADYOUT,
                
                // Memory signals
                output logic [31:0] mem_WR_addr, 
                output logic  mem_write_flag,
                output logic [31:0] HWDATA_toMem            
    );
    node_state State;
    logic WAIT_STATE_ON;

    logic [31:0] mem_WR_addr_log;

    assign HWDATA_toMem = (mem_write_flag == 1) ? HWDATA : 0;

    always_ff@(posedge HCLK )
    begin
        if (HRESETn == 0) begin
            State              <= Idle;
            HREADYOUT          <= 1;
            mem_WR_addr        <= 0;
            HRESP              <= OKAY;
            mem_WR_addr_log    <= 0;
        end else begin
            case(State)
                Idle: begin 
                    HRESP           <= OKAY;
                    mem_WR_addr_log <= 0;

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
                        end else if (HTRANS == IDLE) begin
                            State       <= Idle;
                            mem_WR_addr <= 32'b0; 
                        end else begin 
                            State        <= Idle;
                            mem_WR_addr  <= 32'b0; 
                        end
                
                    end else if (HBURST == INCR || HBURST == INCR4 || HBURST == INCR8 || HBURST == INCR16) begin
                        if (HTRANS == SEQ) begin 
                            State       <= State;
                            mem_WR_addr <= HADDR; 
                        end else if (HTRANS == BUSY) begin
                            State           <= BUSY_State;
                            mem_WR_addr     <= mem_WR_addr; 
                            mem_WR_addr_log <= HADDR; // save the last address 
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
                        mem_WR_addr_log <= 0;
                    end
                end

                BUSY_State: begin 
                    if (HTRANS == BUSY) begin
                        State       <= BUSY_State;
                        mem_WR_addr     <= mem_WR_addr; 
                        mem_WR_addr_log <= mem_WR_addr_log;
                    end else if (HTRANS == SEQ) begin 
                        State       <= Data_Phase;
                        mem_WR_addr <= mem_WR_addr_log; 
                        mem_WR_addr_log <= 0;
                    end else if (HTRANS == IDLE) begin
                        State       <= Idle;
                        mem_WR_addr <= 32'b0; 
                        mem_WR_addr_log <= 0;

                    end else begin 
                        State       <= Idle;
                        mem_WR_addr <= 32'b0; 
                        mem_WR_addr_log <= 0;

                    end 
                end

                default: begin
                    State           <= Idle;
                    HREADYOUT       <= 1;
                    mem_WR_addr     <= 0;
                    mem_WR_addr_log <= 0;

                end
            endcase
        end
    end

    always_comb
    begin 
        case(State)
            Data_Phase: begin 
                if(HWRITE == 1 && HTRANS != BUSY) 
                    mem_write_flag = 1;
                else  
                    mem_write_flag = 0;
            end 

            BUSY_State: begin 
                if (HTRANS != BUSY)
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