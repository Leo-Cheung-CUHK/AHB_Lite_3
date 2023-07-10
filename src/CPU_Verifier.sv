import ahb3lite_pkg::* ;

module CPU_Verifier (
            input   logic           HCLK, 
            input   logic           HRESETn,

            // From Master 
            input HTRANS_state      HTRANS,

            input   logic           [5:0]  RCC_Words_N,
            input   logic           [15:0] RCC_DMA_ADDR_HIGH,
            input   logic           [15:0] RCC_DMA_ADDR_LOW,

            // Memory Signals
            input   logic           [31:0] mem_WR_addr,
            input   logic           mem_write_flag,
            input   logic           [31:0] HWDATA_toMem,

            input   logic           [31:0] init_data
    );

    logic data_error;
    logic addr_error;

    logic len_error;  

    Verifier_state State;
    logic [31:0]  RCC_DMA_ADDR; 

    logic [31:0] len_counter;
    logic [31:0] next_expected_data;
    logic [31:0] next_expected_addr;

    assign RCC_DMA_ADDR = {RCC_DMA_ADDR_HIGH, RCC_DMA_ADDR_LOW};

    assign data_error = (mem_write_flag == 1) ? ((next_expected_data != HWDATA_toMem) ? 1 : 0) : 0;
    assign addr_error = (mem_write_flag == 1) ? ((next_expected_addr != next_expected_addr)? 1 : 0) : 0;

    always_ff@(posedge HCLK) begin
        if (!HRESETn) begin 
            State         <= Verifier_IDLE;  
            len_error     <= 0;
            len_counter   <= 0;
            next_expected_data <= 0;
            next_expected_addr <= 0;
        end else begin
            case (State)
                Verifier_IDLE: begin 
                    if (HTRANS == IDLE) begin 
                        State         <= Verifier_IDLE;  
                        len_error     <= 0;
                        len_counter   <= 0;
                        next_expected_data <= 0;
                        next_expected_addr <= 0;

                    end else begin  
                        State         <= Verifier_CHECK; 
                        len_error     <= 0;
                        len_counter   <= 0;
                        next_expected_data <= init_data;
                        next_expected_addr <= RCC_DMA_ADDR;
                    end
                end 

                Verifier_CHECK: begin 
                    if (HTRANS == IDLE) begin 
                        // A transfer is finished
                        State         <= Verifier_IDLE;  
                        len_counter   <= 0;
                        next_expected_data <= 0;
                        next_expected_addr <= 0;
                        if (len_counter == RCC_Words_N - 1) 
                            len_error     <= 0;
                        else 
                            len_error     <= 1;

                    end else begin 
                        State <= Verifier_CHECK;      
                        if (mem_write_flag == 1) begin 
                            len_error     <= 0;
                            len_counter   <= len_counter + 1;
                            next_expected_data <= next_expected_data + 1;
                            next_expected_addr <= next_expected_addr - 1;
                        end else begin
                            len_error     <= 0;
                            len_counter   <= len_counter;
                            next_expected_data <= next_expected_data;
                            next_expected_addr <= next_expected_addr;
                        end
                    end 
                end

                default: begin 
                    State         <= Verifier_IDLE;  
                    len_error     <= 0;
                    len_counter   <= 0;
                    next_expected_data <= 0;
                end
            endcase
        end
        
    end

    
endmodule