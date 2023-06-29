import ahb3lite_pkg::* ;

    module ahb3lite_slave
    (
                // Global signals       
                input bit HCLK,
                input logic HRESETn,

                input logic SystemStart,

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
                output logic  mem_read_flag,
                output logic [31:0] mem_WR_addr, 
                input  logic [31:0] HRDATA_fromMem                
    );
  
    node_state State;
    
    logic [3:0] wait_state_counter;
    logic [7:0] data_state_counter;
    logic [3:0] wait_during_data_state_counter;

    logic ReadyOn;
    logic wait_state_on;
    logic wait_during_data_state_on;
    logic [3:0] WAIT_STATE_N;
    logic [3:0] WAIT_DURING_DATA_STATE_N;
    logic [2:0] WAIT_DURING_DATA_STATE_INDEX;

    task  Configure_Slave(input logic i_ReadyOn, input logic i_wait_state_on, input  logic i_wait_during_data_state_on, 
    input logic [3:0] i_WAIT_STATE_N, input logic [3:0] i_WAIT_DURING_DATA_STATE_N, input logic [2:0] i_WAIT_DURING_DATA_STATE_INDEX);
        ReadyOn                       <= i_ReadyOn;
        wait_state_on                 <= i_wait_state_on;
        wait_during_data_state_on     <= i_wait_during_data_state_on;
        WAIT_STATE_N                  <= i_WAIT_STATE_N;
        WAIT_DURING_DATA_STATE_N      <= i_WAIT_DURING_DATA_STATE_N;
        WAIT_DURING_DATA_STATE_INDEX  <= i_WAIT_DURING_DATA_STATE_INDEX;
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
                    if (SystemStart == 1) begin
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
                    data_state_counter <= 0;

                    if (wait_state_on == 1) begin
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
                    data_state_counter                  <= data_state_counter + 1;

                    if ((wait_during_data_state_on == 1) && (data_state_counter == WAIT_DURING_DATA_STATE_INDEX) ) begin
                        mem_WR_addr                     <= HADDR;
                        wait_during_data_state_counter  <= 0;
                        State                           <= Wait_In_Data_State;
                        HREADYOUT                       <= 0;

                    end else begin 
                        if (HBURST == SINGLE) begin
                            mem_WR_addr     <= HADDR; 
                            if (HTRANS == NONSEQ) begin
                                State           <= State;
                            end else 
                                State           <= Idle;

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
                end

                Wait_In_Data_State: begin   
                    if (wait_during_data_state_counter < WAIT_DURING_DATA_STATE_N - 1) begin
                        wait_during_data_state_counter <= wait_during_data_state_counter + 1;
                        State                          <= State;
                        HREADYOUT                      <= 0;
                    end else begin
                        State                          <= Data_Phase;
                        HREADYOUT                      <= 1;
                        wait_during_data_state_counter <= 0;
                    end
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
                    mem_read_flag = 0;
                else 
                    mem_read_flag = 1;
            end 

            default: begin
                mem_read_flag     = 0;
            end

        endcase
    end

    endmodule