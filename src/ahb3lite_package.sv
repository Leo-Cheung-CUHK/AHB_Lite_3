
////////////////////////////////////////////////////////////////////////////////////////////////
// ahb3lite_pkg.sv
// Author: Kirtan Mehta, Mohammad Suheb Zameer, Sai Tawale, Raveena Khandelwal
// 
// Date : 12 March 2018
// .......................................
// Description:
// AHBlite package to containing all parameters, enum and logic
/////////////////////////////////////////////////////////////////////////////////////////////////   

package ahb3lite_pkg;
  
    typedef enum logic [2:0] { Idle, GetReady, Address_Phase, Wait_State, Data_Phase, Wait_In_Data_State} node_state;

    typedef enum logic [1:0] { IDLE, BUSY, NONSEQ, SEQ} HTRANS_state;

    typedef enum logic [3:0] { SINGLE, INCR, WRAP4, INCR4, WRAP8, INCR8, WRAP16, INCR16} HBURST_Type;

    typedef enum logic  {ERROR, OKAY} HRESP_state;

    typedef enum logic { Helper_IDLE, Helper_READ} FIFO_Reader_Help_state;

    typedef enum logic [1:0] { Verifier_IDLE, Verifier_Start, Verifier_CHECK} Verifier_state;

    localparam WRITE = 1'b1;
    localparam READ = 1'b0;
    parameter WORD = 3'b010;

endpackage 