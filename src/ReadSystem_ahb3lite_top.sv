import ahb3lite_pkg::* ;

module ReadSystem_ahb3lite_top(
                input   wire           HCLK, 
                input   wire           HRESETn,
                input   wire           SLOW_CLK,
                input   wire           SLOW_RESETn,
                input   wire           i_Read_Request,
                input   wire           i_ReadSystemStart,

                output  wire           [7:0] O_serialized_output,
                output  wire           O_serialized_output_valid,
                output  wire           [1:0] O_Serialize_Counter,
                output  wire           [15:0] O_Bytes_Counter,
                output  wire           [15:0] O_RCC_BYTE_CNT,

                // Memory Signals
                output wire            [31:0] mem_WR_addr,
                output wire            mem_read_flag,
                input  wire            [31:0]  HRDATA_fromMem,

                // Register Signals
                input  wire            [5:0]  i_RCC_BUFFER_LENGTH,
                input  wire            [15:0] i_RCC_DMA_ADDR_HIGH,
                input  wire            [15:0] i_RCC_DMA_ADDR_LOW,

                // Verifier signals
                output wire            o_FIFO_rd_en,

                // From Switch 
                input  wire            HREADY,

                output HTRANS_state    o_HTRANS,

                output wire            slave_done,
                output wire            FIFO_Reader_Done
);
                // ReadSystem 
                wire                   [31:0]  HADDR;
                wire                   [31:0]  HRDATA;
                wire                   HWRITE;

                HBURST_Type            HBURST;
                wire                   [2:0]   HSIZE;
                HTRANS_state           HTRANS;

                wire                   HREADYOUT;
                HRESP_state            HRESP;

                wire                   HRDATA_En;

                wire                   [31:0]  o_HRDATA;
                wire                   o_HRDATA_En;

                // FIFO Signals
                wire                   [31 : 0] FIFO_din;
                wire                   FIFO_wr_en;
                wire                   FIFO_rd_en;
                wire                   [31 : 0] FIFO_dout;
                wire                   FIFO_valid;
                wire                   [5 : 0] FIFO_data_count;
                wire                   FIFO_full;
                wire                   FIFO_empty;

assign  o_HTRANS    = HTRANS;

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
                        .RCC_BYTE_CNT(O_RCC_BYTE_CNT),
                        .FIFO_Reader_Done(FIFO_Reader_Done)
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

ReadSystemDMA_master ReadSystemDMA_master_0(
                        .HCLK(HCLK), 
                        .HRESETn(HRESETn), 

                        .i_ReadSystemStart(i_ReadSystemStart),

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

ReadSystemDMA_slave ReadSystemDMA_slave_0 (
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
                        .HRDATA_fromMem(HRDATA_fromMem),

                        .slave_done(slave_done)
);
endmodule
