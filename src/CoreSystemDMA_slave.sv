import ahb3lite_pkg::* ;

    module CoreSystemDMA_slave
    (
                // Global signals       
                input bit HCLK,
                input logic HRESETn,

                // To/From Master
                output logic HREADYOUT,
                output logic [31:0] HRDATA,
                output logic HRDATA_En,
                output HRESP_state HRESP,

                input logic [31:0] HADDR,
                input HBURST_Type HBURST,
                input logic [2:0] HSIZE,
                input HTRANS_state HTRANS,
                input logic HWRITE,
                
                // Memory signals
                output logic [31:0] mem_WR_addr, 
                output logic  mem_read_flag,
                input  logic [31:0] HRDATA_fromMem
);
  
    node_state State;
    
    assign HRDATA = (mem_read_flag == 1) ? HRDATA_fromMem : 0;
    assign HRDATA_En = mem_read_flag;

    always_ff@(posedge HCLK )
    begin
        if (HRESETn == 0) begin
            State              <= Idle;
            HREADYOUT          <= 0;
            mem_WR_addr        <= 0;
            HRESP              <= OKAY;

        end else begin
            case(State)
                Idle: begin 
                    HRESP              <= OKAY;
                    HREADYOUT          <= 1;
                    HRESP              <= OKAY;

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
                        mem_WR_addr     <= HADDR; 
                        if (HTRANS == NONSEQ) begin
                            State       <= State;
                        end else 
                            State       <= Idle;
                    end else if (HBURST == INCR) begin
                        mem_WR_addr     <= HADDR; 
                        if (HTRANS == BUSY) begin
                            State       <= Idle;
                            HREADYOUT   <= 0;
                        end else 
                            State       <= State;
                    end else
                        State           <= State;
                end

                default: begin
                    State               <= Idle;
                    HREADYOUT           <= 0;
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
                    mem_read_flag  = 0;
                else  
                    mem_read_flag  = 1;
            end 

            default: begin
                mem_read_flag     = 0;
            end
        endcase
    end

    endmodule