module WriteSystem_ahb3lite_top(
                (* mark_debug = "true" *) 
                input   wire                                     S_AHB_HCLK, 
                (* mark_debug = "true" *) input   wire           S_AHB_HRESETN,

                (* mark_debug = "true" *) input   wire           [31:0]  S_AHB_HADDR,
                (* mark_debug = "true" *) input   wire           [3:0]   S_AHB_HPROT, // Not Used
                (* mark_debug = "true" *) input   wire           [1:0]   S_AHB_HTRANS,
                (* mark_debug = "true" *) input   wire           [2:0]   S_AHB_HSIZE,
                (* mark_debug = "true" *) input   wire           S_AHB_HWRITE,
                (* mark_debug = "true" *) input   wire           [31:0]  S_AHB_HWDATA,
                (* mark_debug = "true" *) input   wire           [2:0]   S_AHB_HBURST,
                (* mark_debug = "true" *) input   wire           S_AHB_HMASTLOCK,      // Not Used
                (* mark_debug = "true" *) output  wire           S_AHB_HREADY,
                (* mark_debug = "true" *) output   wire          [31:0]  S_AHB_HRDATA,
                (* mark_debug = "true" *) output  wire           S_AHB_HRESP
);
                // Memory Signals
                (* mark_debug = "true" *) wire                   [31:0] mem_WR_addr;
                (* mark_debug = "true" *) wire                   mem_write_flag;
                (* mark_debug = "true" *) wire                   [31:0] HWDATA_toMem;



assign S_AHB_HRDATA = 32'b0;

WriteSystemDMA_slave WriteSystemDMA_slave_0 (
                        .HCLK(S_AHB_HCLK), 
                        .HRESETn(S_AHB_HRESETN), 
                        
                        .HADDR(S_AHB_HADDR), 
                        .HWDATA(S_AHB_HWDATA), 
                        .HWRITE(S_AHB_HWRITE),
                        
                        .HBURST(S_AHB_HBURST), 
                        .HSIZE(S_AHB_HSIZE),
                        .HTRANS(S_AHB_HTRANS),

                        .HREADY(1'b1),
                        .HRESP(S_AHB_HRESP),
                        .HREADYOUT(S_AHB_HREADY),

                        .mem_WR_addr(mem_WR_addr),
                        .mem_write_flag(mem_write_flag),
                        .HWDATA_toMem(HWDATA_toMem)
);

external_memory external_memory_0(
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
