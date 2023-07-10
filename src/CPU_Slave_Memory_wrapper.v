module CPU_ahb3lite_top(
                input   wire           HCLK, 
                input   wire           HRESETn,

                input   wire           [31:0]  HADDR,
                input   wire           [31:0]  HWDATA,
                input   wire           HWRITE,
                input   wire           [2:0]   HBURST,
                input   wire           [2:0]   HSIZE,
                input   wire           [1:0]   HTRANS,

                output   wire          HREADY,
                output   wire          HRESP
);
                // Memory Signals
                wire                   [31:0] mem_WR_addr;
                wire                   mem_write_flag;
                wire                   [31:0] HWDATA_toMem;

CPU_DMA_slave CPU_DMA_slave_0 (
                        .HCLK(HCLK), 
                        .HRESETn(HRESETn), 
                        
                        .HADDR(HADDR), 
                        .HWDATA(HWDATA), 
                        .HWRITE(HWRITE),
                        
                        .HBURST(HBURST), 
                        .HSIZE(HSIZE),
                        .HTRANS(HTRANS),

                        .HREADY(HREADY),
                        .HRESP(HRESP),

                        .mem_WR_addr(mem_WR_addr),
                        .mem_write_flag(mem_write_flag),
                        .HWDATA_toMem(HWDATA_toMem)
);

ahb3lite_memory external_memory(
                        .HCLK(HCLK),
                        .HRESETn(HRESETn),
                        
                        .READ_addr(32'b0),
                        .read_flag(1'b0),
                        .HRDATA(32'b0),

                        .WRITE_addr(mem_WR_addr),
                        .write_flag(mem_write_flag),
                        .HWDATA(HWDATA_toMem),

                        // Below ports are for verifier
                        .monitor_flag(1'b0),
                        .monitor_addr(32'b0),
                        .monitor_DATA(32'b0)
);

endmodule
