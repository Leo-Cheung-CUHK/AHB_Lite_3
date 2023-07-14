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
                input HRESP_state   HRESP,

                // To Verifier
                output logic  [5:0]  o_RCC_Words_N,
                output logic  [15:0] o_RCC_DMA_ADDR_HIGH,
                output logic  [15:0] o_RCC_DMA_ADDR_LOW,

                output logic  [31:0] o_init_data
    );

    logic   CPU_Start;
    logic   CPU_Work;

    logic   [5:0]  RCC_BUFFER_LENGTH;
    logic   [15:0] RCC_DMA_ADDR_HIGH;
    logic   [15:0] RCC_DMA_ADDR_LOW;

    logic   [5:0]   RCC_Words_CNT;
    logic   [5:0]   RCC_Words_N;

    logic   [31:0]  i_HADDR;
    logic   [31:0]  temp_addr;
    logic   [31:0]  i_HWDATA;
    logic   [31:0]  temp_data;

    logic   BUSY_STATE_ON;
    logic   [15:0] BUSY_STATE_N;
    logic   [15:0] BUSY_STATE_counter;
    logic   HOLD_STATE_ON;
    logic   [15:0] HOLD_STATE_N;
    logic   [15:0] HOLD_STATE_counter;

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

                RCC_BUFFER_LENGTH <= i_RCC_BUFFER_LENGTH;
                RCC_DMA_ADDR_HIGH <= i_RCC_DMA_ADDR_HIGH;
                RCC_DMA_ADDR_LOW  <= i_RCC_DMA_ADDR_LOW;
                i_HADDR           <= {i_RCC_DMA_ADDR_HIGH, i_RCC_DMA_ADDR_LOW};
                i_HWDATA          <= random_DATA;
                o_init_data       <= random_DATA;
           end
    endtask;

    node_state State = Idle;

    assign  RCC_Words_N  = ((RCC_BUFFER_LENGTH[0] | RCC_BUFFER_LENGTH[1]) == 0)?
    (RCC_BUFFER_LENGTH >> 2) : (RCC_BUFFER_LENGTH >> 2) + 1;

    assign o_RCC_Words_N = RCC_Words_N;
    assign o_RCC_DMA_ADDR_HIGH = RCC_DMA_ADDR_HIGH;
    assign o_RCC_DMA_ADDR_LOW  = RCC_DMA_ADDR_LOW;
    
    always_comb begin 
        case (RCC_Words_N)
            1  : HBURST = SINGLE;
            4  : HBURST = INCR4;
            8  : HBURST = INCR8;
            16 : HBURST = INCR16;
            default: HBURST = INCR;
        endcase
    end

    // Maintain state machine
    always_ff@(posedge HCLK)
    begin
        if (HRESETn == 0) begin
            RCC_Words_CNT      <= 0;
            State              <= Idle;
            BUSY_STATE_ON <= 0;
            BUSY_STATE_N <= 0;
            BUSY_STATE_counter <= 0;

            HOLD_STATE_ON <= 0;
            HOLD_STATE_N <= 0;
            HOLD_STATE_counter <= 0;

            CPU_Work     <= 0;
        end else begin
            case(State)
                Idle: begin 
                    RCC_Words_CNT <= 0;
                    BUSY_STATE_counter <= 0;

                    HOLD_STATE_ON <= 0;
                    HOLD_STATE_N <= 0;
                    HOLD_STATE_counter <= 0;
                    if (CPU_Start == 1) begin 
                        State <= Address_Phase;

                        if (HBURST != SINGLE) begin 
                            BUSY_STATE_ON <= $urandom_range(0,1);
                            BUSY_STATE_N  <= $urandom_range(1,5);
                        end else begin 
                            BUSY_STATE_ON <= 0;
                            BUSY_STATE_N  <= 0;
                        end

                        CPU_Work     <= 1;                        
                    end else  begin 
                        State <= State;
                        CPU_Work     <= 0;
                    end
                end

                Address_Phase: begin
                    if (BUSY_STATE_ON == 1) begin 
                        State              <= Wait_State;
                        BUSY_STATE_counter <= 0;
                        BUSY_STATE_ON <= 0;
                    end else begin 
                        State          <= Data_Phase;
                        RCC_Words_CNT  <= RCC_Words_N - 1; 
                        HOLD_STATE_ON  <= $urandom_range(0,1);
                        HOLD_STATE_N   <= $urandom_range(1,5);
                    end
                end

                Wait_State : begin 
                    if (BUSY_STATE_counter == BUSY_STATE_N - 1) begin 
                        BUSY_STATE_counter <= 0;
                        State              <= Data_Phase;
                        RCC_Words_CNT      <= RCC_Words_N - 1; 
                        HOLD_STATE_ON  <= $urandom_range(0,1);
                        HOLD_STATE_N   <= $urandom_range(1,5);
                    end else begin 
                        BUSY_STATE_counter <= BUSY_STATE_counter + 1;
                        State              <= State;
                    end
                end

                Data_Phase: begin 
                    if (HREADY == 1) begin 
                        if (RCC_Words_CNT == 0)  begin 
                            State         <= Idle;
                            CPU_Work      <= 0;
                        end else if (HOLD_STATE_ON == 1) begin
                            State        <= Hold_State;
                            HOLD_STATE_counter <= 0;
                            RCC_Words_CNT <= RCC_Words_CNT - 1; 
                        end else begin
                            State         <= State; 
                            RCC_Words_CNT <= RCC_Words_CNT - 1; 
                        end 
                    end             
                end

                Hold_State : begin 
                    if (HOLD_STATE_counter == HOLD_STATE_N - 1) begin 
                        HOLD_STATE_counter <= 0;
                        State              <= Data_Phase;
                        HOLD_STATE_ON  <= $urandom_range(0,1);
                        HOLD_STATE_N   <= $urandom_range(1,5);

                    end else begin 
                        HOLD_STATE_counter <= HOLD_STATE_counter + 1;
                        State              <= State;
                    end
                end

                default: begin
                    State         <= Idle;
                    RCC_Words_CNT <= 0;

                    BUSY_STATE_ON <= 0;
                    BUSY_STATE_N <= 0;
                    BUSY_STATE_counter <= 0;

                    HOLD_STATE_ON <= 0;
                    HOLD_STATE_N <= 0;
                    HOLD_STATE_counter <= 0;

                    CPU_Work      <= 0;
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
                if (RCC_Words_CNT == 0) 
                    HTRANS = IDLE;
                else
                    HTRANS = SEQ;

                HWRITE = WRITE;
                HADDR  = temp_addr;
                HWDATA = temp_data;
            end

            Wait_State, Hold_State: begin
                HTRANS = BUSY;
                HWRITE = WRITE;
                HADDR  = temp_addr;
                HWDATA = temp_data;
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
                    if ((HTRANS == NONSEQ && (HBURST == INCR || HBURST == INCR4 || HBURST == INCR8 || HBURST == INCR16) ) || (HTRANS == NONSEQ && HBURST == SINGLE && RCC_Words_N > 1) )
                        temp_addr <= i_HADDR - 1;
                    else 
                        temp_addr <= i_HADDR;

                    temp_data <= i_HWDATA;
                end

                Data_Phase: begin
                    if (HREADY == 1) begin 
                        if (HTRANS == SEQ && (HBURST == INCR || HBURST == INCR4 || HBURST == INCR8 || HBURST == INCR16)) 
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
                
                Wait_State, Hold_State: begin
                    temp_addr <= temp_addr;
                    temp_data <= temp_data;
                end

                default: begin 
                    temp_addr <= 32'b0;
                    temp_data <= 32'b0;
                end
            endcase
        end
    end

endmodule