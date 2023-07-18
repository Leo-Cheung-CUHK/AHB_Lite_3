module WriteSystem_ahb3lite_top(
                input   logic           HCLK, 
                input   logic           HRESETn,

                // Memory Signals
                output logic            [31:0] mem_WR_addr,
                output logic            mem_write_flag,
                output logic            [31:0] HWDATA_toMem,

                // From Switch 
                input  logic            HREADY,
                output HTRANS_state     o_HTRANS,

                output logic            slave_done
);
                logic                   [31:0]  HADDR;
                logic                   [31:0]  HWDATA;
                logic                   HWRITE;

                HBURST_Type             HBURST;
                logic                   [2:0]   HSIZE;
                HTRANS_state            HTRANS;

                HRESP_state             HRESP;
                logic                   HREADYOUT;

                logic                   [5:0] RCC_Words_N;
                logic                   [15:0] RCC_DMA_ADDR_HIGH;
                logic                   [15:0] RCC_DMA_ADDR_LOW;

                logic                   [31:0] o_init_data;

assign o_HTRANS = HTRANS;

WriteSystemDMA_master WriteSystemDMA_master_0(
                        .HCLK(HCLK), 
                        .HRESETn(HRESETn), 

                        .HADDR(HADDR), 
                        .HWDATA(HWDATA), 
                        .HWRITE(HWRITE),

                        .HBURST(HBURST), 
                        .HSIZE(HSIZE),
                        .HTRANS(HTRANS),

                        .HREADY(HREADYOUT), 
                        .HRESP(HRESP),

                        .o_RCC_Words_N(RCC_Words_N),
                        .o_RCC_DMA_ADDR_HIGH(RCC_DMA_ADDR_HIGH),
                        .o_RCC_DMA_ADDR_LOW(RCC_DMA_ADDR_LOW),

                        .o_init_data(o_init_data)
);

WriteSystemDMA_slave WriteSystemDMA_slave_0 (
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
                        .HREADYOUT(HREADYOUT),

                        .mem_WR_addr(mem_WR_addr),
                        .mem_write_flag(mem_write_flag),
                        .HWDATA_toMem(HWDATA_toMem),

                        .slave_done(slave_done)
);


Write_Verifier Write_Verifier_0(
                        .HCLK(HCLK), 
                        .HRESETn(HRESETn),

            // From Master 
                        .HTRANS(HTRANS),
                        .RCC_Words_N(RCC_Words_N),
                        .RCC_DMA_ADDR_HIGH(RCC_DMA_ADDR_HIGH),
                        .RCC_DMA_ADDR_LOW(RCC_DMA_ADDR_LOW),
            // From Slave
                        .HREADY(HREADY),
            // Memory Signals
                        .mem_WR_addr(mem_WR_addr),
                        .mem_write_flag(mem_write_flag),
                        .HWDATA_toMem(HWDATA_toMem),
                        .init_data(o_init_data)
);

endmodule