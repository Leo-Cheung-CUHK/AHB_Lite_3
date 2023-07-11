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
                output  logic           [15:0] O_RCC_BYTE_CNT,

                // Memory Signals
                output logic            [31:0] mem_WR_addr,
                output logic            mem_read_flag,
                input  logic            [31:0]  HRDATA_fromMem,

                // Register Signals
                input  logic            [5:0]  i_RCC_BUFFER_LENGTH,
                input  logic            [15:0] i_RCC_DMA_ADDR_HIGH,
                input  logic            [15:0] i_RCC_DMA_ADDR_LOW,

                // Verifier signals
                output logic            o_FIFO_rd_en,

                // From Switch 
                input  logic            HREADY
);
                // CoreSystem 
                logic                   [31:0]  HADDR;
                logic                   [31:0]  HRDATA;
                logic                   HWRITE;

                HBURST_Type             HBURST;
                logic                   [2:0]   HSIZE;
                HTRANS_state            HTRANS;

                logic                   HREADYOUT;
                HRESP_state             HRESP;

                logic                   HRDATA_En;

                logic                   [31:0]  o_HRDATA;
                logic                   o_HRDATA_En;

                // FIFO Signals
                logic                   [31 : 0] FIFO_din;
                logic                   FIFO_wr_en;
                logic                   FIFO_rd_en;
                logic                   [31 : 0] FIFO_dout;
                logic                   FIFO_valid;
                logic                   [5 : 0] FIFO_data_count;
                logic                   FIFO_full;
                logic                   FIFO_empty;

assign  FIFO_din    = o_HRDATA;
assign  FIFO_wr_en  = o_HRDATA_En && ~ FIFO_full;
assign  FIFO_rd_en  = o_FIFO_rd_en;

FIFO_Reader_Helper  FIFO_Reader_Helper_0 (
                        .CLK(SLOW_CLK),
                        .RESETn(SLOW_RESETn),

                        .Read_Request(i_Read_Request),
                        
                        .i_RCC_BUFFER_LENGTH(i_RCC_BUFFER_LENGTH),
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

CoreSystemDMA_master CoreSystemDMA_master_0(
                        .HCLK(HCLK), 
                        .HRESETn(HRESETn), 

                        .i_CoreSystemStart(i_CoreSystemStart),

                        .HADDR(HADDR), 
                        .HRDATA(HRDATA), 
                        .HWRITE(HWRITE),

                        .HBURST(HBURST), 
                        .HSIZE(HSIZE),
                        .HTRANS(HTRANS),

                        .HREADY(HREADYOUT), 
                        .HRESP(HRESP),

                        .i_RCC_BUFFER_LENGTH(i_RCC_BUFFER_LENGTH),
                        .i_RCC_DMA_ADDR_HIGH(i_RCC_DMA_ADDR_HIGH),
                        .i_RCC_DMA_ADDR_LOW(i_RCC_DMA_ADDR_LOW),

                        .o_HRDATA(o_HRDATA),
                        .o_HRDATA_En(o_HRDATA_En),
                        .HRDATA_En(HRDATA_En)

);

CoreSystemDMA_slave CoreSystemDMA_slave_0 (
                        .HCLK(HCLK), 
                        .HRESETn(HRESETn), 
                        
                        .HADDR(HADDR), 
                        .HRDATA(HRDATA), 
                        .HWRITE(HWRITE), 

                        .HBURST(HBURST) , 
                        .HSIZE(HSIZE),
                        .HTRANS(HTRANS),

                        .HREADY(HREADY),
                        .HREADYOUT(HREADYOUT),
                        .HRESP(HRESP),
                        
                        .HRDATA_En(HRDATA_En),

                        .mem_WR_addr(mem_WR_addr),
                        .mem_read_flag(mem_read_flag),
                        .HRDATA_fromMem(HRDATA_fromMem)
);
endmodule
