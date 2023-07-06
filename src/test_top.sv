module test_top(
        input logic           HCLK,
        input logic           HRESETn,
        input logic           SLOW_CLK,
        input logic           SLOW_RESETn,
        input logic           i_Read_Request,
        input logic           i_CoreSystemStart
);

// Core system 
logic           [7:0] O_serialized_output;
logic           O_serialized_output_valid;
logic           [1:0] O_Serialize_Counter;
logic           [15:0] O_Bytes_Counter;
logic           [15:0] O_RCC_BYTE_CNT;

logic            [31:0] core_mem_READ_addr;
logic            core_mem_read_flag;
logic            [31:0]  core_HRDATA_fromMem;

logic            CoreSystem_Master_Done;
logic            NewCommandOn;

// CPU system 
logic            [31:0] CPU_mem_WRITE_addr;
logic            CPU_mem_write_flag;
logic            [31:0]  CPU_HWDATA_toMem;

//Memory interface 
logic            [31:0] mem_READ_addr;
logic            mem_read_flag;
logic            [31:0]  HRDATA_fromMem;

logic            [31:0] mem_WRITE_addr;
logic            mem_write_flag;
logic            [31:0]  HRDATA_toMem;

// Register Updater
logic            [5:0]  o_RCC_BUFFER_LENGTH;
logic            [15:0] o_RCC_DMA_ADDR_HIGH;
logic            [15:0] o_RCC_DMA_ADDR_LOW;

// verifier 
logic            verifier_DMA_READ_Flag;
logic            [31:0] verifier_DMA_READ_Addr;
logic            [31:0] verifier_DMA_READ_Data;
logic            o_FIFO_rd_en;

// Todo: switch logic
assign mem_READ_addr = core_mem_READ_addr;
assign mem_read_flag = core_mem_read_flag;
assign core_HRDATA_fromMem = HRDATA_fromMem;

assign mem_WRITE_addr = CPU_mem_WRITE_addr;
assign mem_write_flag = CPU_mem_write_flag;
assign HRDATA_toMem = CPU_HWDATA_toMem;

Verifier  Verifier_0(
                        .CLK(SLOW_CLK),
                        .RESETn(SLOW_RESETn),

                        .i_RCC_DMA_ADDR_HIGH(o_RCC_DMA_ADDR_HIGH),
                        .i_RCC_DMA_ADDR_LOW(o_RCC_DMA_ADDR_LOW),
                        .i_RCC_BUFFER_LENGTH(o_RCC_BUFFER_LENGTH),

                        .Read_Request(i_Read_Request),

                        .i_Reader_FIFO_rd_en(o_FIFO_rd_en),
                        .i_serialized_output(O_serialized_output),
                        .i_serialized_output_valid(O_serialized_output_valid),
                        .Serialize_Counter(O_Serialize_Counter),

                        .DMA_READ(verifier_DMA_READ_Flag),
                        .DMA_READ_addr(verifier_DMA_READ_Addr),
                        .i_HRDATA(verifier_DMA_READ_Data)
);

CoreSystem_ahb3lite_top CoreSystem_top_ahb(
                        .HCLK(HCLK), 
                        .SLOW_CLK(SLOW_CLK), 
                        .HRESETn(HRESETn), 
                        .SLOW_RESETn(SLOW_RESETn), 
                        .i_CoreSystemStart(i_CoreSystemStart),
                        .i_Read_Request(i_Read_Request),

                        .O_serialized_output(O_serialized_output),
                        .O_serialized_output_valid(O_serialized_output_valid),
                        .O_Serialize_Counter(O_Serialize_Counter),
                        .O_Bytes_Counter(O_Bytes_Counter),
                        .O_RCC_BYTE_CNT(O_RCC_BYTE_CNT),

                        .mem_WR_addr(core_mem_READ_addr),
                        .mem_read_flag(core_mem_read_flag),
                        .HRDATA_fromMem(core_HRDATA_fromMem),

                        .NewCommandOn(NewCommandOn),
                        .Master_Done(CoreSystem_Master_Done),
                        .i_RCC_BUFFER_LENGTH(o_RCC_BUFFER_LENGTH),
                        .i_RCC_DMA_ADDR_HIGH(o_RCC_DMA_ADDR_HIGH),
                        .i_RCC_DMA_ADDR_LOW(o_RCC_DMA_ADDR_LOW),

                        .o_FIFO_rd_en(o_FIFO_rd_en)
);


CPU_ahb3lite_top CPU_top_ahb(
                        .HCLK(HCLK),
                        .HRESETn(HRESETn),
                        
                        .mem_WR_addr(CPU_mem_WRITE_addr),
                        .mem_write_flag(CPU_mem_write_flag),
                        .HWDATA_toMem(CPU_HWDATA_toMem)
);

ahb3lite_memory external_memory(
                        .READ_addr(mem_READ_addr),
                        .read_flag(mem_read_flag),
                        .HRDATA(HRDATA_fromMem),

                        .WRITE_addr(mem_WRITE_addr),
                        .write_flag(mem_write_flag),
                        .HWDATA(HRDATA_toMem),

                        // Below ports are for verifier
                        .monitor_flag(verifier_DMA_READ_Flag),
                        .monitor_addr(verifier_DMA_READ_Addr),
                        .monitor_DATA(verifier_DMA_READ_Data)
);

// This updater updates three global registers:
//(RCC_BUFFER_LENGTH, RCC_DMA_ADDR_HIGH, RCC_DMA_ADDR_LOW)
Register_Updater Register_Updater_0 (
                        .HCLK(HCLK),
                        .HRESETn(HRESETn),
                        .i_CoreSystemStart(i_CoreSystemStart),

                        .NewCommandOn(NewCommandOn),
                        .CoreSystem_Master_Done(CoreSystem_Master_Done),

                        .o_RCC_BUFFER_LENGTH(o_RCC_BUFFER_LENGTH),
                        .o_RCC_DMA_ADDR_HIGH(o_RCC_DMA_ADDR_HIGH),
                        .o_RCC_DMA_ADDR_LOW(o_RCC_DMA_ADDR_LOW)
);

endmodule
