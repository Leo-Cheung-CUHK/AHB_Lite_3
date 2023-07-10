`timescale 1ns/1ps

/////////////////////////////////////////////////////////////////////
import ahb3lite_pkg::* ;

class randNumGen;
        rand bit burst_type;
        randc bit [5:0] RCC_BUFFER_LENGTH;
        randc bit [10:0] RCC_DMA_ADDR_LOW;
        randc bit [15:0] RCC_DMA_ADDR_HIGH;
        randc bit [31:0] RCC_DMA_INIT_DATA;

endclass

module test_master();

        bit             HCLK;
        logic           HRESETn;
        bit             SLOW_CLK;
        logic           SLOW_RESETn;
       
        logic           i_CoreSystemStart;
        logic           i_Read_Request;

        // output from the Top Module
        logic           [7:0] O_serialized_output;
        logic           O_serialized_output_valid;
        logic           [1:0] O_Serialize_Counter;
        logic           [15:0] O_Bytes_Counter;

        logic           [15:0] O_RCC_BYTE_CNT; // [15:6] - reserved 

        // DMA-related Registers 
        logic           [15:0] RCC_BUFFER_LENGTH;  // [15:6] - reserved 
        logic           [15:0] RCC_DMA_ADDR_HIGH;
        logic           [15:0] RCC_DMA_ADDR_LOW;
       
        logic           [5:0]  RCC_BUFFER_LENGTH_IN_WORDS;

        // Parameters to be randomized
        HBURST_Type     HBURST; 

        // Run time counter
        logic           [63 : 0]  Test_N = 0;

test_top test_top(
                        .HCLK(HCLK), 
                        .SLOW_CLK(SLOW_CLK), 
                        .HRESETn(HRESETn), 
                        .SLOW_RESETn(SLOW_RESETn), 
                        .i_CoreSystemStart(i_CoreSystemStart),
                        .i_Read_Request(i_Read_Request)
);

defparam test_top.CoreSystem_top_ahb.FIFO_Master_Side_0.DSIZE = 32;
defparam test_top.CoreSystem_top_ahb.FIFO_Master_Side_0.ASIZE = 6;

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
        i_CoreSystemStart <= 0;
        Test_N <= Test_N + 1;
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
            test_top.external_memory.MemoryClass_init.randomize();
        end

        @(posedge HCLK)
        begin
            if (randNumGen_Int.RCC_BUFFER_LENGTH == 0) 
                RCC_BUFFER_LENGTH <= 1;    
            else
                RCC_BUFFER_LENGTH <= randNumGen_Int.RCC_BUFFER_LENGTH;
        end

        @(posedge HCLK) begin
            RCC_BUFFER_LENGTH_IN_WORDS  = ((RCC_BUFFER_LENGTH[0] | RCC_BUFFER_LENGTH[1]) == 0)?
            (RCC_BUFFER_LENGTH >> 2) : (RCC_BUFFER_LENGTH >> 2) + 1;
        end

        @(posedge HCLK)
        begin
            if ((randNumGen_Int.burst_type == 0) || (RCC_BUFFER_LENGTH_IN_WORDS == 1) )
                HBURST            <= SINGLE;
            else 
                HBURST            <= INCR;

            RCC_DMA_ADDR_HIGH <= 16'h0000;
            RCC_DMA_ADDR_LOW  <= randNumGen_Int.RCC_DMA_ADDR_LOW;

        end

        @(posedge HCLK);

        test_top.CPU_top_ahb.CPU_DMA_slave_0.Configure_Slave(1'b1);
        test_top.CPU_top_ahb.CPU_DMA_master_0.CPU_Write(1'b1, HBURST, RCC_BUFFER_LENGTH, RCC_DMA_ADDR_HIGH
        ,RCC_DMA_ADDR_LOW, randNumGen_Int.RCC_DMA_INIT_DATA);

        test_top.CoreSystem_top_ahb.CoreSystemDMA_master_0.Configure_Master(HBURST);
        test_top.CoreSystem_top_ahb.CoreSystemDMA_slave_0.Configure_Slave(1'b1, 1'b0, 1'b0);
        test_top.Register_Updater_0.CPU_Reg_Write(RCC_DMA_ADDR_HIGH,RCC_DMA_ADDR_LOW,RCC_BUFFER_LENGTH);



        @(posedge HCLK)
        begin
            i_CoreSystemStart <= 1;
            test_top.CPU_top_ahb.CPU_DMA_master_0.CPU_Write(1'b0, HBURST, RCC_BUFFER_LENGTH, RCC_DMA_ADDR_HIGH
            ,RCC_DMA_ADDR_LOW, randNumGen_Int.RCC_DMA_INIT_DATA);
        end

        @(posedge HCLK)
        begin
            i_CoreSystemStart <= 0;
        end

        @(posedge SLOW_CLK)
        begin
            i_Read_Request <= 1;
        end

        @(posedge test_top.CoreSystem_top_ahb.O_serialized_output_valid)
        begin
            i_Read_Request <= 0;
        end

        @(negedge test_top.CoreSystem_top_ahb.FIFO_Reader_Helper_0.State);

        repeat(4) @(posedge SLOW_CLK);
    end

end

endmodule