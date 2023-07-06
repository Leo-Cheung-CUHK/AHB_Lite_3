module CoreSystem_ahb3lite_top(
                input   logic           HCLK, 
                input   logic           HRESETn,
                input   logic           SLOW_CLK,
                input   logic           SLOW_RESETn,
                input   logic           i_Read_Request,
                input   logic           i_CoreSystemStart,

                output  logic           [7:0] O_serialized_output,
                output  logic           O_serialized_output_valid,
                output  logic           [1:0] O_Serialize_Counter,
                output  logic           [15:0] O_Bytes_Counter,
                output  logic           [15:0] O_RCC_BYTE_CNT
);
                // CoreSystem 
                logic                   CoreSystemStart;

                logic                   [31:0]  HADDR;
                HBURST_Type             HBURST;
                logic                   [2:0]   HSIZE;
                logic                   HREADY;
                HRESP_state             HRESP;
                logic                   HREADYOUT;
                logic                   [31:0]  HRDATA;
                logic                   HRDATA_En;
                                
                logic                   HWRITE;

                HTRANS_state            HTRANS;

                logic                   [31:0] mem_WR_addr;
                logic                   mem_read_flag;
                logic                   mem_write_flag;
                logic                   [31:0]  HRDATA_fromMem;
                logic                   [31:0]  HWDATA_toMem;

                logic                   [31:0]  o_HRDATA;
                logic                   o_HRDATA_En;

                //CPU Signals
                logic                   NewCommandOn;
                logic                   o_FIFO_rd_en;
                logic                   [5:0]  o_RCC_BUFFER_LENGTH;
                logic                   [15:0] o_RCC_DMA_ADDR_HIGH;
                logic                   [15:0] o_RCC_DMA_ADDR_LOW;

                logic                   Master_Done;

                // FIFO Signals
                logic                   [31 : 0] FIFO_din;
                logic                   FIFO_wr_en;
                logic                   FIFO_rd_en;
                logic                   [5  : 0] FIFO_prog_empty_thresh;
                logic                   [5  : 0] FIFO_prog_full_thresh;
                logic                   [31 : 0] FIFO_dout;
                logic                   FIFO_valid;
                logic                   [5 : 0] FIFO_data_count;
                logic                   FIFO_full;
                logic                   FIFO_empty;

                logic                   verifier_DMA_READ_Flag;
                logic                   [31 : 0] verifier_DMA_READ_Addr;
                logic                   [31 : 0] verifier_DMA_READ_Data;

task configure_FIFO(input [5  : 0] i_FIFO_prog_empty_thresh,input [5  : 0] i_FIFO_prog_full_thresh);        
        @(posedge HCLK) begin
            FIFO_prog_empty_thresh <= i_FIFO_prog_empty_thresh;
            FIFO_prog_full_thresh  <= i_FIFO_prog_full_thresh;
        end
endtask;

assign  FIFO_din    = o_HRDATA;
assign  FIFO_wr_en  = o_HRDATA_En && ~ FIFO_full;
assign  FIFO_rd_en  = o_FIFO_rd_en;

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

FIFO_Reader_Helper  FIFO_Reader_Helper_0 (
                        .CLK(SLOW_CLK),
                        .RESETn(SLOW_RESETn),

                        .Read_Request(i_Read_Request),
                        
                        .i_RCC_BUFFER_LENGTH(o_RCC_BUFFER_LENGTH),
                        .i_FIFO_empty(FIFO_empty),
                        .i_FIFO_dout(FIFO_dout),

                        .o_FIFO_rd_en(o_FIFO_rd_en),

                        .serialized_output(O_serialized_output),
                        .serialized_output_valid(O_serialized_output_valid),
                        .Serialize_Counter(O_Serialize_Counter),
                        .Bytes_Counter(O_Bytes_Counter),
                        .RCC_BYTE_CNT(O_RCC_BYTE_CNT)
);

async_fifo  FIFO_Master_Side_0(
                        .wreq(FIFO_wr_en),
                        .wclk(HCLK),
                        .wrst_n(HRESETn),

                        .rreq(FIFO_rd_en),
                        .rclk(SLOW_CLK),
                        .rrst_n(SLOW_RESETn),

                        .wdata(FIFO_din),
                        .rdata(FIFO_dout),

                        .wfull(FIFO_full),
                        .rempty(FIFO_empty),

                        .number(FIFO_data_count)
);

// This updater updates three global registers:
//(RCC_BUFFER_LENGTH, RCC_DMA_ADDR_HIGH, RCC_DMA_ADDR_LOW)
Register_Updater Register_Updater_0 (
                        .HCLK(HCLK),
                        .HRESETn(HRESETn),

                        .CoreSystemStart(CoreSystemStart),
                        .Master_Done(Master_Done),

                        .NewCommandOn(NewCommandOn),
                        .o_RCC_BUFFER_LENGTH(o_RCC_BUFFER_LENGTH),
                        .o_RCC_DMA_ADDR_HIGH(o_RCC_DMA_ADDR_HIGH),
                        .o_RCC_DMA_ADDR_LOW(o_RCC_DMA_ADDR_LOW)
);

CoreSystemDMA_master CoreSystemDMA_master_0(
                        .HCLK(HCLK), 
                        .HRESETn(HRESETn), 

                        .i_CoreSystemStart(i_CoreSystemStart),
                        .CoreSystemStart(CoreSystemStart),

                        .HREADY(HREADYOUT), 
                        .HRDATA(HRDATA), 
                        .HRDATA_En(HRDATA_En),
                        .HRESP(HRESP),

                        .HADDR(HADDR), 
                        .HBURST(HBURST), 
                        .HSIZE(HSIZE),
                        .HTRANS(HTRANS),
                        .HWRITE(HWRITE),

                        .Master_Done(Master_Done),

                        .NewCommandOn(NewCommandOn),
                        .i_RCC_BUFFER_LENGTH(o_RCC_BUFFER_LENGTH),
                        .i_RCC_DMA_ADDR_HIGH(o_RCC_DMA_ADDR_HIGH),
                        .i_RCC_DMA_ADDR_LOW(o_RCC_DMA_ADDR_LOW),

                        .o_HRDATA(o_HRDATA),
                        .o_HRDATA_En(o_HRDATA_En)
);

CoreSystemDMA_slave CoreSystemDMA_slave_0 (
                        .HCLK(HCLK), 
                        .HRESETn(HRESETn), 
                        
                        .CoreSystemStart(CoreSystemStart),

                        .HREADYOUT(HREADYOUT),
                        .HRDATA(HRDATA), 
                        .HRDATA_En(HRDATA_En),
                        .HRESP(HRESP),
                        
                        .HADDR(HADDR), 
                        .HBURST(HBURST) , 
                        .HSIZE(HSIZE),
                        .HTRANS(HTRANS),
                        .HWRITE(HWRITE), 

                        .mem_WR_addr(mem_WR_addr),
                        .mem_read_flag(mem_read_flag),
                        .HRDATA_fromMem(HRDATA_fromMem)
);

ahb3lite_memory external_memory(
                        .WR_addr(mem_WR_addr),
                        .read_flag(mem_read_flag),
                        .write_flag(mem_write_flag),
                        .HRDATA(HRDATA_fromMem),
                        .HWDATA(HRDATA_toMem),

                        // Below ports are for verifier
                        .monitor_flag(verifier_DMA_READ_Flag),
                        .monitor_addr(verifier_DMA_READ_Addr),
                        .monitor_DATA(verifier_DMA_READ_Data)
);
endmodule
