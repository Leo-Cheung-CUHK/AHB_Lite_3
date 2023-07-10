module CPU_ahb3lite_top(
                input   logic           HCLK, 
                input   logic           HRESETn,

                // Memory Signals
                output logic            [31:0] mem_WR_addr,
                output logic            mem_write_flag,
                output logic            [31:0] HWDATA_toMem
);
                logic                   [31:0]  HADDR;
                logic                   [31:0]  HWDATA;
                logic                   HWRITE;

                HBURST_Type             HBURST;
                logic                   [2:0]   HSIZE;
                HTRANS_state            HTRANS;

                logic                   HREADY;
                HRESP_state             HRESP;

                logic                   [5:0] RCC_Words_N;
                logic                   [15:0] RCC_DMA_ADDR_HIGH;
                logic                   [15:0] RCC_DMA_ADDR_LOW;

                logic                   [31:0] o_init_data;
CPU_DMA_master CPU_DMA_master_0(
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

                        .o_RCC_Words_N(RCC_Words_N),
                        .o_RCC_DMA_ADDR_HIGH(RCC_DMA_ADDR_HIGH),
                        .o_RCC_DMA_ADDR_LOW(RCC_DMA_ADDR_LOW),

                        .o_init_data(o_init_data)
);

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


CPU_Verifier CPU_Verifier_0(
                        .HCLK(HCLK), 
                        .HRESETn(HRESETn),

            // From Master 
                        .HTRANS(HTRANS),
                        .RCC_Words_N(RCC_Words_N),
                        .RCC_DMA_ADDR_HIGH(RCC_DMA_ADDR_HIGH),
                        .RCC_DMA_ADDR_LOW(RCC_DMA_ADDR_LOW),

            // Memory Signals
                        .mem_WR_addr(mem_WR_addr),
                        .mem_write_flag(mem_write_flag),
                        .HWDATA_toMem(HWDATA_toMem),
                        .init_data(o_init_data)
);

endmodule
