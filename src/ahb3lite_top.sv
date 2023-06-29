module ahb3lite_top(
                input   logic           HCLK, 
                input   logic           HRESETn,
                input   logic           SLOW_CLK,
                input   logic           SLOW_RESETn,
                input   logic           i_Read_Request,
                input   logic           i_SystemStart
);
                logic                   SystemStart;

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
                logic                   [1:0]   HSEL;

                logic                   mem_write_flag;
                logic                   mem_read_flag;
                logic                   [31:0] mem_WR_addr;
                logic                   [31:0]  HRDATA_fromMem;
                
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
                logic                   FIFO_prog_full;
                logic                   FIFO_prog_empty;

                logic                   [7:0] O_serialized_output;
                logic                   O_serialized_output_valid;
                logic                   [1:0] Serialize_Counter;

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
assign  FIFO_wr_en  = o_HRDATA_En && ~ FIFO_prog_full;
assign  FIFO_rd_en  = o_FIFO_rd_en;

Verifier  Verifier_1(
                        .CLK(SLOW_CLK),
                        .RESETn(SLOW_RESETn),

                        .i_RCC_DMA_ADDR_HIGH(o_RCC_DMA_ADDR_HIGH),
                        .i_RCC_DMA_ADDR_LOW(o_RCC_DMA_ADDR_LOW),

                        .Read_Request(i_Read_Request),

                        .i_Reader_FIFO_rd_en(o_FIFO_rd_en),
                        .i_serialized_output(O_serialized_output),
                        .i_serialized_output_valid(O_serialized_output_valid),
                        .Serialize_Counter(Serialize_Counter),

                        .DMA_READ(verifier_DMA_READ_Flag),
                        .DMA_READ_addr(verifier_DMA_READ_Addr),

                        .i_HRDATA(verifier_DMA_READ_Data)
);

FIFO_Reader_Helper  FIFO_Reader_Helper_1 (
                        .CLK(SLOW_CLK),
                        .RESETn(SLOW_RESETn),

                        .Read_Request(i_Read_Request),

                        .i_RCC_BUFFER_LENGTH(o_RCC_BUFFER_LENGTH),
                        .i_FIFO_prog_empty(FIFO_prog_empty),
                        .i_FIFO_dout(FIFO_dout),

                        .o_FIFO_rd_en(o_FIFO_rd_en),

                        .serialized_output(O_serialized_output),
                        .serialized_output_valid(O_serialized_output_valid),
                        .Serialize_Counter(Serialize_Counter)
);

async_fifo  FIFO_Master_Side_1(
                        .wreq(FIFO_wr_en),
                        .wclk(HCLK),
                        .wrst_n(HRESETn),

                        .rreq(FIFO_rd_en),
                        .rclk(SLOW_CLK),
                        .rrst_n(SLOW_RESETn),

                        .wdata(FIFO_din),
                        .rdata(FIFO_dout),

                        .wfull(FIFO_prog_full),
                        .rempty(FIFO_prog_empty),

                        .number(FIFO_data_count)
);

CPU_Registers CPU_Module (
                        .HCLK(HCLK),
                        .HRESETn(HRESETn),

                        .SystemStart(SystemStart),
                        .Master_Done(Master_Done),

                        .NewCommandOn(NewCommandOn),
                        .o_RCC_BUFFER_LENGTH(o_RCC_BUFFER_LENGTH),
                        .o_RCC_DMA_ADDR_HIGH(o_RCC_DMA_ADDR_HIGH),
                        .o_RCC_DMA_ADDR_LOW(o_RCC_DMA_ADDR_LOW)
);

ahb3lite_master master(
                        .HCLK(HCLK), 
                        .HRESETn(HRESETn), 

                        .i_SystemStart(i_SystemStart),
                        .SystemStart(SystemStart),

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

ahb3lite_slave slave (
                        .HCLK(HCLK), 
                        .HRESETn(HRESETn), 
                        
                        .SystemStart(SystemStart),

                        .HREADYOUT(HREADYOUT),
                        .HRDATA(HRDATA), 
                        .HRDATA_En(HRDATA_En),
                        .HRESP(HRESP),
                        
                        .HADDR(HADDR), 
                        .HBURST(HBURST) , 
                        .HSIZE(HSIZE),
                        .HTRANS(HTRANS),
                        .HWRITE(HWRITE), 

                        .mem_read_flag(mem_read_flag),
                        .mem_WR_addr(mem_WR_addr),
                        .HRDATA_fromMem(HRDATA_fromMem)
);

ahb3lite_memory external_memory(
                        .read_flag(mem_read_flag),
                        .WR_addr(mem_WR_addr),
                        .HRDATA(HRDATA_fromMem),

                        .read_flag_1(verifier_DMA_READ_Flag),
                        .WR_addr_1(verifier_DMA_READ_Addr),
                        .HRDATA_1(verifier_DMA_READ_Data)
);
endmodule
