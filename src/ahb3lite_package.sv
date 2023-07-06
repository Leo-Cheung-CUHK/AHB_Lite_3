package ahb3lite_pkg;
    typedef enum logic [2:0] { Idle, GetReady, Address_Phase, Wait_State, Data_Phase} node_state;
    typedef enum logic [1:0] { IDLE, BUSY, NONSEQ, SEQ} HTRANS_state;
    typedef enum logic [3:0] { SINGLE, INCR, WRAP4, INCR4, WRAP8, INCR8, WRAP16, INCR16} HBURST_Type;
    typedef enum logic {ERROR, OKAY} HRESP_state;
    typedef enum logic {Helper_IDLE, Helper_READ} FIFO_Reader_Help_state;
    typedef enum logic [1:0] { Verifier_IDLE, Verifier_Start, Verifier_CHECK} Verifier_state;

    localparam WRITE = 1'b1;
    localparam READ = 1'b0;
    parameter  WORD = 3'b010;
endpackage 
