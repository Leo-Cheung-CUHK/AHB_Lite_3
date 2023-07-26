module test_top(
        input logic           HCLK,
        input logic           HRESETn,
        input logic           SLOW_CLK,
        input logic           SLOW_RESETn,
        input logic           i_Read_Request,
        input logic           i_ReadSystemStart,
        input logic           i_VeriferStart
);

// Core system 
logic           [7:0] O_serialized_output;
logic           O_serialized_output_valid;
logic           [1:0] O_Serialize_Counter;
logic           [15:0] O_Bytes_Counter;
logic           [15:0] O_RCC_BYTE_CNT;

logic            ReadSystem_Master_Done;
logic            NewCommandOn;

//Memory interface 
logic            [31:0] mem_READ_addr;
logic            mem_read_flag;
logic            [31:0]  HRDATA_fromMem;

logic            [31:0] mem_WRITE_addr;
logic            mem_write_flag;
logic            [31:0]  HWDATA_toMem;

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
logic           ReadSystem_HREADY;
logic           WriteSystem_HREADY;
logic           Other_HREADY;

HTRANS_state    ReadSystem_HTRANS;
HTRANS_state    WriteSystem_HTRANS;
HTRANS_state    Other_HTRANS;

logic           ReadSystem_slave_done;
logic           WriteSystem_slave_done;
logic           Other_slave_done;

logic           FIFO_Reader_Done;

Read_Verifier  Read_Verifier_0(
                        .CLK(SLOW_CLK),
                        .RESETn(SLOW_RESETn),

                        .i_RCC_DMA_ADDR_HIGH(o_RCC_DMA_ADDR_HIGH),
                        .i_RCC_DMA_ADDR_LOW(o_RCC_DMA_ADDR_LOW),
                        .i_RCC_BUFFER_LENGTH(o_RCC_BUFFER_LENGTH),

                        .i_VerifierStart(i_VeriferStart),
                        .FIFO_Reader_Done(FIFO_Reader_Done),

                        .i_Reader_FIFO_rd_en(o_FIFO_rd_en),
                        .i_serialized_output(O_serialized_output),
                        .i_serialized_output_valid(O_serialized_output_valid),
                        .Serialize_Counter(O_Serialize_Counter),

                        .DMA_READ(verifier_DMA_READ_Flag),
                        .DMA_READ_addr(verifier_DMA_READ_Addr),
                        .i_HRDATA(verifier_DMA_READ_Data)
);

ReadSystem_ahb3lite_top ReadSystem_top_ahb(
                        .HCLK(HCLK), 
                        .SLOW_CLK(SLOW_CLK), 
                        .HRESETn(HRESETn), 
                        .SLOW_RESETn(SLOW_RESETn), 
                        .i_ReadSystemStart(i_ReadSystemStart),
                        .i_Read_Request(i_Read_Request),

                        .O_serialized_output(O_serialized_output),
                        .O_serialized_output_valid(O_serialized_output_valid),
                        .O_Serialize_Counter(O_Serialize_Counter),
                        .O_Bytes_Counter(O_Bytes_Counter),
                        .O_RCC_BYTE_CNT(O_RCC_BYTE_CNT),

                        .mem_WR_addr(mem_READ_addr),
                        .mem_read_flag(mem_read_flag),
                        .HRDATA_fromMem(HRDATA_fromMem),

                        .i_RCC_BUFFER_LENGTH(o_RCC_BUFFER_LENGTH),
                        .i_RCC_DMA_ADDR_HIGH(o_RCC_DMA_ADDR_HIGH),
                        .i_RCC_DMA_ADDR_LOW(o_RCC_DMA_ADDR_LOW),

                        .o_FIFO_rd_en(o_FIFO_rd_en),
                        .HREADY(ReadSystem_HREADY),
                        .o_HTRANS(ReadSystem_HTRANS),

                        .slave_done(ReadSystem_slave_done),
                        .FIFO_Reader_Done(FIFO_Reader_Done)
);

WriteSystem_ahb3lite_top WriteSystem_top_ahb(
                        .HCLK(HCLK),
                        .HRESETn(HRESETn),
                        
                        .mem_WR_addr(mem_WRITE_addr),
                        .mem_write_flag(mem_write_flag),
                        .HWDATA_toMem(HWDATA_toMem),

                        .HREADY(WriteSystem_HREADY),
                        .o_HTRANS(WriteSystem_HTRANS),

                        .slave_done(WriteSystem_slave_done)
);

// To simulate a busy-traffic case
WriteSystem_ahb3lite_top other_ahb(
                        .HCLK(HCLK),
                        .HRESETn(HRESETn),

                        .HREADY(Other_HREADY),
                        .o_HTRANS(Other_HTRANS),

                        .slave_done(Other_slave_done)
);

Switch  switch_0 (
                        .HCLK(HCLK),
                        .HRESETn(HRESETn),

                        .ReadSystem_slave_done(ReadSystem_slave_done),
                        .WriteSystem_slave_done(WriteSystem_slave_done),
                        .Other_slave_done(Other_slave_done),

                        .ReadSystem_HTRANS(ReadSystem_HTRANS),
                        .WriteSystem_HTRANS(WriteSystem_HTRANS),
                        .Other_HTRANS(Other_HTRANS),

                        .ReadSystem_HREADY(ReadSystem_HREADY),
                        .WriteSystem_HREADY(WriteSystem_HREADY),                
                        .Other_HREADY(Other_HREADY)      
);

external_memory external_memory_0(
                        .HCLK(HCLK),
                        .HRESETn(HRESETn),

                        .READ_addr(mem_READ_addr),
                        .read_flag(mem_read_flag),
                        .HRDATA(HRDATA_fromMem),

                        .WRITE_addr(mem_WRITE_addr),
                        .write_flag(mem_write_flag),
                        .HWDATA(HWDATA_toMem),

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

                        .o_RCC_BUFFER_LENGTH(o_RCC_BUFFER_LENGTH),
                        .o_RCC_DMA_ADDR_HIGH(o_RCC_DMA_ADDR_HIGH),
                        .o_RCC_DMA_ADDR_LOW(o_RCC_DMA_ADDR_LOW)
);

endmodule
