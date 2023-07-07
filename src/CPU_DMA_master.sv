import ahb3lite_pkg::* ;

module CPU_DMA_master(

            // AHB protocol inputs and ouptuts
                input bit           HCLK,
                input logic         HRESETn,

                output logic [31:0] HADDR,
                output logic [31:0] HWDATA,
                output logic        HWRITE,

                output HBURST_Type  HBURST,
                output logic [2:0]  HSIZE,
                output HTRANS_state HTRANS, 

                input logic         HREADY,
                input HRESP_state   HRESP
    );

    logic   CPU_Start;

    logic   [5:0]  RCC_BUFFER_LENGTH;
    logic   [15:0] RCC_DMA_ADDR_HIGH;
    logic   [15:0] RCC_DMA_ADDR_LOW;

    logic   [5:0]   RCC_Words_CNT;
    logic   [5:0]   RCC_Words_N;

    logic   [31:0]  i_HADDR;
    logic   [31:0]  temp_addr;
    logic   [31:0]  i_HWDATA;
    logic   [31:0]  temp_data;

    task CPU_Write(  
                            input i_CPU_Start,
                            input HBURST_Type i_HBURST, 
                            input logic [5:0]  i_RCC_BUFFER_LENGTH,
                            input logic [15:0] i_RCC_DMA_ADDR_HIGH,
                            input logic [15:0] i_RCC_DMA_ADDR_LOW,
                            input logic [31:0] random_DATA
    );        
           @(posedge HCLK) begin
                HSIZE       <= WORD;
                CPU_Start   <= i_CPU_Start;
                HBURST      <= i_HBURST;

                RCC_BUFFER_LENGTH <= i_RCC_BUFFER_LENGTH;
                RCC_DMA_ADDR_HIGH <= i_RCC_DMA_ADDR_HIGH;
                RCC_DMA_ADDR_LOW  <= i_RCC_DMA_ADDR_LOW;
                i_HADDR           <= {i_RCC_DMA_ADDR_HIGH, i_RCC_DMA_ADDR_LOW};
                i_HWDATA          <= random_DATA;
           end
    endtask;

    node_state State = Idle;
    assign  RCC_Words_N  = ((RCC_BUFFER_LENGTH[0] | RCC_BUFFER_LENGTH[1]) == 0)?
    (RCC_BUFFER_LENGTH >> 2) : (RCC_BUFFER_LENGTH >> 2) + 1;

    // Maintain state machine
    always_ff@(posedge HCLK)
    begin
        if (HRESETn == 0) begin
            RCC_Words_CNT <= 0;
            HSIZE         <= 0;
            State         <= Idle;

        end else begin
            case(State)
                Idle: begin 
                    RCC_Words_CNT <= 0;
                    HSIZE         <= 0;

                    if (CPU_Start == 1)  
                        State <= GetReady;
                    else  
                        State <= Idle;
                end

                GetReady: begin 
                    if (HREADY == 1)
                        State <= Address_Phase;
                    else 
                        State <= State;
                end

                Address_Phase: begin
                    State         <= Data_Phase;
                    RCC_Words_CNT <= RCC_Words_N - 1; 
                end

                Data_Phase: begin 
                    if (HREADY == 1) begin 
                        if (RCC_Words_CNT == 0) 
                            State        <= Idle;
                        else begin
                            State        <= State; 
                            RCC_Words_CNT <= RCC_Words_CNT - 1; 
                        end 
                    end             
                end

                default: begin
                    State         <= Idle;
                    RCC_Words_CNT <= 0;
                    HSIZE         <= 0;
                end
            endcase
        end
    end         

    // Update status parameters
    always_comb begin
        case (State)
            GetReady: begin
                HTRANS = IDLE;
                HWRITE = WRITE;
                HADDR  = i_HADDR;
                HWDATA = 32'b0;
            end

            Address_Phase: begin
                HTRANS = NONSEQ;
                HWRITE = WRITE;
                HADDR  = i_HADDR;
                HWDATA = 32'b0;
            end

            Data_Phase: begin
                HADDR  = temp_addr;
                HWDATA = temp_data;

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
                HWRITE = READ;
                HADDR  = 32'b0;
                HTRANS = IDLE;
                HWDATA = 32'b0;
            end
        endcase
    end

    // Update address
    always_ff@(posedge HCLK)
    begin
        if (HRESETn == 0) begin
            temp_addr <= 32'b0;
            temp_data <= 32'b0;
        end else begin
            case(State)
                Address_Phase: begin
                    if ((HTRANS == NONSEQ && HBURST == INCR) || (HTRANS == NONSEQ && HBURST == SINGLE && RCC_Words_N > 1) )
                        temp_addr <= i_HADDR - 1;
                    else 
                        temp_addr <= i_HADDR;

                    temp_data <= i_HWDATA;
                end

                Data_Phase: begin
                    if (HREADY == 1) begin 
                        if (HTRANS == SEQ && HBURST == INCR) 
                            temp_addr <= temp_addr - 1;   
                        else if (HTRANS == NONSEQ && HBURST == SINGLE && RCC_Words_CNT != 0) 
                            temp_addr <= temp_addr - 1;   
                        else 
                            temp_addr <= temp_addr;
                        temp_data <= temp_data + 1'h1;
                    end else begin
                        temp_addr <= temp_addr;
                        temp_data <= temp_data;
                    end
                end
                
                default: begin 
                    temp_addr <= 32'b0;
                    temp_data <= 32'b0;
                end
            endcase
        end
    end

endmodule