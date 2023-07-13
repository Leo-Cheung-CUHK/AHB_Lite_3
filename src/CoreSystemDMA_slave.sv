import ahb3lite_pkg::* ;

    module CoreSystemDMA_slave
    (
                // Global signals       
                input bit HCLK,
                input logic HRESETn,

                input logic [31:0] HADDR,
                output logic [31:0] HRDATA,
                input logic HWRITE,

                input HBURST_Type HBURST,
                input logic [2:0] HSIZE,
                input HTRANS_state HTRANS,

                // To/From Master
                output HRESP_state HRESP,
                input  logic HREADY,
                output logic HREADYOUT,

                output logic HRDATA_En,

                // Memory signals
                output logic [31:0] mem_WR_addr, 
                output logic  mem_read_flag,
                input  logic [31:0] HRDATA_fromMem,

                output logic slave_done
);
  
    node_state State;
    
    assign HRDATA = (mem_read_flag == 1) ? HRDATA_fromMem : 0;
    assign HRDATA_En = mem_read_flag;

    assign HREADYOUT = HREADY;

    always_ff@(posedge HCLK )
    begin
        if (HRESETn == 0) begin
            State              <= Idle;
            mem_WR_addr        <= 0;
            HRESP              <= OKAY;
            slave_done         <= 0;

        end else begin
            case(State)
                Idle: begin 
                    if (HTRANS == NONSEQ) begin 
                        State       <= Data_Phase;                        
                        mem_WR_addr <= HADDR; 
                    end else begin 
                        State       <= State;
                        mem_WR_addr <= 32'b0; 
                    end

                    HRESP      <= OKAY;
                    slave_done <= 0;
                end

                Data_Phase: begin  
                    if (HBURST == SINGLE) begin
                        if (HREADY == 1)
                            mem_WR_addr <= HADDR; 
                        else 
                            mem_WR_addr <= mem_WR_addr; 
                             
                        if (HTRANS == NONSEQ) begin 
                            State      <= State;
                        end else begin 
                            State      <= Idle;
                            slave_done <= 1;
                        end

                    end else if (HBURST == INCR) begin
                        if (HREADY == 1)
                            mem_WR_addr <= HADDR; 
                        else 
                            mem_WR_addr <= mem_WR_addr;

                        if (HTRANS == BUSY) begin
                            State       <= Idle;
                            slave_done  <= 1;
                        end else begin 
                            State       <= State;
                        end
                    end else
                        State           <= State;
                end

                default: begin
                    State               <= Idle;
                    mem_WR_addr         <= 0;
                    slave_done          <= 0;
                end
            endcase
        end
    end

    always_comb
    begin 
        case(State)
            Data_Phase: begin 
                if(HWRITE == 0 && HREADY == 1)  
                    mem_read_flag  = 1;
                else  
                    mem_read_flag  = 0;
            end 

            default: begin
                mem_read_flag     = 0;
            end
        endcase
    end

    endmodule