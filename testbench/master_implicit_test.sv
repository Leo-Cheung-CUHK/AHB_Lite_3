`timescale 1ns/1ps

/////////////////////////////////////////////////////////////////////
import ahb3lite_pkg::* ;

class randNumGen;
        rand bit wait_state_on;
        rand bit [3:0] slave_wait_N;
        rand bit [5:0] RCC_BUFFER_LENGTH;
        rand bit wait_in_data_on;
        rand bit [3:0] slave_wait_in_data_N;
        rand bit [2:0] slave_wait_in_data_index;
        rand bit burst_type;
        rand bit [10:0] RCC_DMA_ADDR_LOW;
endclass

module test_master();

        bit             HCLK;
        logic           HRESETn;
        bit             SLOW_CLK;
        logic           SLOW_RESETn;
       
        logic           i_SystemStart;
        logic           i_Read_Request;
       
        logic           [5:0]  RCC_BUFFER_LENGTH;
        logic           [15:0] RCC_DMA_ADDR_HIGH;
        logic           [15:0] RCC_DMA_ADDR_LOW;
       
        logic           [5:0]  RCC_Words_N;


        // Parameters to be randomized
        HBURST_Type     HBURST; 

        logic           i_ReadyOn;
        logic           i_wait_state_on;
        logic           i_wait_during_data_state_on;

        logic           [3:0]  i_WAIT_STATE_N;
        logic           [3:0] i_WAIT_DURING_DATA_STATE_N;
        logic           [2:0] i_WAIT_DURING_DATA_STATE_INDEX;
        logic           [5  : 0] i_FIFO_prog_empty_thresh;
        logic           [5  : 0] i_FIFO_prog_full_thresh;

ahb3lite_top top_ahb(   .HCLK(HCLK), 
                        .SLOW_CLK(SLOW_CLK), 
                        .HRESETn(HRESETn), 
                        .SLOW_RESETn(SLOW_RESETn), 
                        .i_SystemStart(i_SystemStart),
                        .i_Read_Request(i_Read_Request)
);

defparam top_ahb.FIFO_Master_Side_1.DSIZE = 32;
defparam top_ahb.FIFO_Master_Side_1.ASIZE = 6;

randNumGen randNumGen_Int = new();

initial
begin
    forever
        #21 HCLK = ~HCLK; 
end 

initial
begin
    forever
        #504 SLOW_CLK = ~SLOW_CLK; 
end 

always
begin
    @(posedge HCLK)
    begin
        HRESETn <= 0;
        i_SystemStart <= 0;
    end

    @(posedge HCLK)
    begin
        HRESETn <= 1;
    end

    @(posedge SLOW_CLK)
    begin
        SLOW_RESETn <= 0;
    end 

    @(posedge SLOW_CLK)
    begin
        SLOW_RESETn <= 1;
    end

    @(posedge HCLK);

    repeat(100) @(posedge HCLK) begin 

        @(posedge HCLK)
        begin
            randNumGen_Int.randomize();
            top_ahb.external_memory.MemoryClass_init.randomize();
        end

        @(posedge HCLK);

        @(posedge HCLK)
        begin
            i_ReadyOn <= 1;

            if (randNumGen_Int.slave_wait_N == 0) begin
                i_wait_state_on   <= 0;
                i_WAIT_STATE_N    <= 0;
            end else begin
                i_wait_state_on   <= randNumGen_Int.wait_state_on;
                i_WAIT_STATE_N    <= randNumGen_Int.slave_wait_N;
            end

            if (randNumGen_Int.RCC_BUFFER_LENGTH == 0) 
                RCC_BUFFER_LENGTH <= 1;    
            else
                RCC_BUFFER_LENGTH <= randNumGen_Int.RCC_BUFFER_LENGTH;
        end

        @(posedge HCLK);

        @(posedge HCLK) begin
            RCC_Words_N  = ((RCC_BUFFER_LENGTH[0] | RCC_BUFFER_LENGTH[1]) == 0)?
            (RCC_BUFFER_LENGTH >> 2) : (RCC_BUFFER_LENGTH >> 2) + 1;
        end

        @(posedge HCLK);

        @(posedge HCLK)
        begin
            if (RCC_Words_N < 2) begin
                i_wait_during_data_state_on   <= 0;
                i_WAIT_DURING_DATA_STATE_N    <= 0;
            end else begin 
                if (randNumGen_Int.slave_wait_in_data_N[0] == 0) begin 
                    i_wait_during_data_state_on   <= 0;
                    i_WAIT_DURING_DATA_STATE_N    <= 0;
                end else begin 
                    i_wait_during_data_state_on   <= randNumGen_Int.wait_in_data_on;
                    i_WAIT_DURING_DATA_STATE_N    <= randNumGen_Int.slave_wait_in_data_N;
                end
            end
        end

        @(posedge HCLK);

        @(posedge HCLK)
        begin
            if (i_wait_during_data_state_on != 0) 
                if (randNumGen_Int.slave_wait_in_data_index >= RCC_Words_N -1)
                    i_WAIT_DURING_DATA_STATE_INDEX <= RCC_Words_N - 2;
                else 
                    i_WAIT_DURING_DATA_STATE_INDEX <= randNumGen_Int.slave_wait_in_data_index;
            else  
                i_WAIT_DURING_DATA_STATE_INDEX <= 0;

            if ((randNumGen_Int.burst_type == 0) || (RCC_Words_N == 1) )
                HBURST            <= SINGLE;
            else 
                HBURST            <= INCR;

            RCC_DMA_ADDR_HIGH <= 16'h0000;
            RCC_DMA_ADDR_LOW  <= randNumGen_Int.RCC_DMA_ADDR_LOW;

            // FIFO Configuration
            i_FIFO_prog_empty_thresh <= 2;
            i_FIFO_prog_full_thresh  <= 30;

        end

        @(posedge HCLK);

        top_ahb.configure_FIFO(i_FIFO_prog_empty_thresh, i_FIFO_prog_full_thresh);  
        top_ahb.master.Configure_Master(HBURST);
        top_ahb.slave.Configure_Slave(i_ReadyOn, i_wait_state_on, i_wait_during_data_state_on,
        i_WAIT_STATE_N, i_WAIT_DURING_DATA_STATE_N, i_WAIT_DURING_DATA_STATE_INDEX);

        @(posedge HCLK);

        top_ahb.CPU_Module.CPU_Reg_Write(RCC_DMA_ADDR_HIGH,RCC_DMA_ADDR_LOW,RCC_BUFFER_LENGTH);

        @(posedge HCLK)
        begin
            i_SystemStart <= 1;
        end

        @(posedge HCLK)
        begin
            i_SystemStart <= 0;
        end

        @(posedge SLOW_CLK)
        begin
            i_Read_Request <= 1;
        end

        @(posedge top_ahb.FIFO_Reader_Helper_1.State)
        begin
            i_Read_Request <= 0;
        end

        @(negedge top_ahb.FIFO_Reader_Helper_1.State);

        repeat(4) @(posedge SLOW_CLK);
    end

end

endmodule