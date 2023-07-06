import ahb3lite_pkg::* ;

    module CoreSystemDMA_slave
    (
                // Global signals       
                input bit HCLK,
                input logic HRESETn,

                input logic CoreSystemStart,

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
    
    logic [15:0] wait_state_counter;
    logic [7:0] data_state_counter;
    logic [3:0] hold_state_counter;

    logic ReadyOn;
    logic WAIT_STATE_ON;
    logic [15:0] WAIT_STATE_N;

    logic HOLD_STATE_ON;
    logic [3:0] HOLD_STATE_N;
    logic [2:0] HOLD_STATE_INDEX;

    task  Configure_Slave(input logic i_ReadyOn, input logic i_WAIT_STATE_ON, 
    input logic [15:0] i_WAIT_STATE_N);
        ReadyOn           <= i_ReadyOn;
        WAIT_STATE_ON     <= i_WAIT_STATE_ON;
        WAIT_STATE_N      <= i_WAIT_STATE_N;
    endtask 

    assign HRDATA = (mem_read_flag == 1) ? HRDATA_fromMem : 0;
    assign HRDATA_En = mem_read_flag;

    always_ff@(posedge HCLK )
    begin
        if (HRESETn == 0) begin
            State              <= Idle;
            HREADYOUT          <= 0;
            wait_state_counter <= 0;
            data_state_counter <= 0;

            mem_WR_addr        <= 0;
            HRESP              <= OKAY;
        end else begin
            case(State)
                Idle: begin 
                    HRESP <= OKAY;
                    HREADYOUT          <= 0;
                    wait_state_counter <= 0;
                    data_state_counter <= 0;

                    mem_WR_addr        <= 0;
                    HRESP              <= OKAY;
                    if (CoreSystemStart == 1) begin
                        if (ReadyOn == 1) begin
                            State       <= GetReady;
                            HREADYOUT   <= 1;
                        end else
                            State       <= Idle;

                    end else begin
                        State           <= Idle;
                        HREADYOUT       <= 0;
                    end
                end

                GetReady: begin 
                    State <= Address_Phase;
                end

                Address_Phase: begin   
                    mem_WR_addr         <= HADDR; 
                    wait_state_counter  <= 0;
                    data_state_counter  <= 0;

                    if (WAIT_STATE_ON == 1) begin
                        State           <= Wait_State;
                        HREADYOUT       <= 0;
                    end else begin
                        State           <= Data_Phase;
                        HREADYOUT       <= 1;
                    end
                end

                Wait_State: begin   
                    if (wait_state_counter < WAIT_STATE_N - 1) begin
                        wait_state_counter <= wait_state_counter + 1;
                        State              <= State;
                        HREADYOUT          <= 0;
                    end else begin
                        State              <= Data_Phase;
                        HREADYOUT          <= 1;
                        wait_state_counter <= 0;
                    end
                end

                Data_Phase: begin  
                    data_state_counter <= data_state_counter + 1;

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
                    State                              <= Idle;
                    HREADYOUT                          <= 0;
                    wait_state_counter                 <= 0;
                    mem_WR_addr                        <= 0;
                    data_state_counter                 <= 0;
                end
            endcase
        end
    end

    always_comb
    begin 
        case(State)
            Idle, Address_Phase, Wait_State: begin
                mem_read_flag     = 0;
            end 
            
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