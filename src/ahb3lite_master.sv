import ahb3lite_pkg::* ;

module ahb3lite_master(

            // AHB protocol inputs and ouptuts
                input bit           HCLK,
                input logic         HRESETn,

                input  logic        i_SystemStart,
                output logic        SystemStart,

                // To/From Slave
                input logic         HREADY,
                input logic [31:0]  HRDATA,
                input logic         HRDATA_En,
                input HRESP_state   HRESP,

                output logic [31:0] HADDR,
                output HBURST_Type  HBURST,
                output logic [2:0]  HSIZE,
                output HTRANS_state HTRANS, 
                output logic        HWRITE,
                
                // To/From CPU Registers
                input logic         NewCommandOn,
                input logic         [5:0]  i_RCC_BUFFER_LENGTH,
                input logic         [15:0] i_RCC_DMA_ADDR_HIGH,
                input logic         [15:0] i_RCC_DMA_ADDR_LOW,
                output logic        Master_Done,

                output logic [31:0] o_HRDATA,
                output logic        o_HRDATA_En
    );

    logic   [5:0]   RCC_Words_CNT;
    logic   [5:0]   RCC_Words_N;
    logic   [5:0]   RCC_BUFFER_LENGTH;
    logic   [31:0]  i_HADDR;
    logic   [31:0]  temp_addr;

    task Configure_Master(input HBURST_Type i_HBURST);        
           @(posedge HCLK) begin
                HSIZE   <= WORD;
                HBURST  <= i_HBURST;
           end
    endtask;

    node_state State = Idle;

    assign  SystemStart = i_SystemStart;
    assign  o_HRDATA  = HRDATA;
    assign  o_HRDATA_En = HRDATA_En;
    assign  RCC_Words_N  = ((RCC_BUFFER_LENGTH[0] | RCC_BUFFER_LENGTH[1]) == 0)?
    (RCC_BUFFER_LENGTH >> 2) : (RCC_BUFFER_LENGTH >> 2) + 1;

    // Maintain state machine
    always_ff@(posedge HCLK)
    begin
        if (HRESETn == 0) begin
            State         <= Idle;
            RCC_Words_CNT <= 0;
            HSIZE         <= 0;
            Master_Done   <= 0;
            i_HADDR       <= 0;

        end else begin
            case(State)
                Idle: begin 
                    RCC_Words_CNT <= 0;
                    HSIZE         <= 0;
                    Master_Done   <= 0;
                    i_HADDR       <= 0;

                    if (i_SystemStart == 1)  
                        State <= GetReady;
                    else  
                        State <= Idle;
                end

                GetReady: begin 
                    if (NewCommandOn == 1) begin
                        // Update registers information from CPU 
                        RCC_BUFFER_LENGTH   <= i_RCC_BUFFER_LENGTH;
                        i_HADDR             <= {i_RCC_DMA_ADDR_HIGH, i_RCC_DMA_ADDR_LOW};

                        if (HREADY == 1)
                            State <= Address_Phase;
                        else 
                            State <= Idle;

                    end else
                        State <= State;
                end

                Address_Phase: begin
                    State         <= Data_Phase;
                    RCC_Words_CNT <= RCC_Words_N - 1; 
                end

                Data_Phase: begin 
                    if (HREADY == 1) begin 
                        if (RCC_Words_CNT == 0) begin 
                            State        <= Idle; 
                            Master_Done  <= 1;

                        end else begin
                            State        <= State; 
                            RCC_Words_CNT <= RCC_Words_CNT - 1; 
                        end 
                    end             
                end

                default: begin
                    State         <= Idle;
                    RCC_Words_CNT <= 0;
                    HSIZE         <= 0;
                    Master_Done   <= 0;
                    i_HADDR       <= 0;
                end
            endcase
        end
    end         

    // Update status parameters
    always_comb begin
        case (State)
            GetReady: begin
                HTRANS = NONSEQ;
                HWRITE = READ;
                HADDR  = i_HADDR;
            end

            Address_Phase: begin
                HTRANS = NONSEQ;
                HWRITE = READ;
                HADDR  = i_HADDR;
            end

            Data_Phase: begin
                HADDR  = temp_addr;
                if (RCC_Words_N > 1) 
                    if (HBURST == INCR) 
                        if  (RCC_Words_CNT == 0)
                            HTRANS = BUSY;
                        else
                            HTRANS = SEQ;
                            
                    else if (HBURST == SINGLE)
                        if  (RCC_Words_CNT == 0)
                            HTRANS = IDLE;
                        else
                            HTRANS = NONSEQ;
            end

            default: begin
                HWRITE           = 1;
                HADDR            = 0;
                HTRANS           = IDLE;
            end
        endcase
    end

    // Update address
    always_ff@(posedge HCLK)
    begin
        if (HRESETn == 0) begin
            temp_addr <= 0;
        end else begin
            case(State)
                Address_Phase: begin
                    if ((HTRANS == NONSEQ && HBURST == INCR) || (HTRANS == NONSEQ && HBURST == SINGLE && RCC_Words_N > 1) )
                        temp_addr <= i_HADDR - 1;
                    else 
                        temp_addr <= i_HADDR;
                end

                Data_Phase: begin
                    if (HREADY == 1)
                        if (HTRANS == SEQ && HBURST == INCR) 
                            temp_addr <= temp_addr - 1;   
                        else if (HTRANS == NONSEQ && HBURST == SINGLE && RCC_Words_CNT != 0) 
                            temp_addr <= temp_addr - 1;   
                        else 
                            temp_addr <= temp_addr;
                    else
                        temp_addr     <= temp_addr;
                end
                
                default: 
                    temp_addr         <= 0;
            endcase
        end
    end

endmodule