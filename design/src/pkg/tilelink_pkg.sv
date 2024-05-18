package tilelink_pkg;
    localparam int unsigned TL_AW = 32;  // Address width in bits
    localparam int unsigned TL_DW = 32;  // Data width in bits
    localparam int unsigned TL_SRCW = 8;  // Source id width in bits
    localparam int unsigned TL_SINKW = 1;  // Sink id width in bits
    localparam int unsigned TL_DBW = (TL_DW >> 3);  // Data mask width in bits
    localparam int unsigned TL_SZW = $clog2($clog2(TL_DBW) + 1);  // Size width in bits

    localparam int unsigned AHB_AW = 32;  // Address width in bits
    localparam int unsigned AHB_DW = 32;  // Data width in bits
    localparam int unsigned AHB_DS = (TL_DW >> 3);  // Data strobe width in bits
    localparam int unsigned AHB_NM = 8;  // Manager id width in bits

    typedef enum logic [2:0] {
        PutFullData    = 3'h0,
        PutPartialData = 3'h1,
        Get            = 3'h4
    } tl_a_opcode_e;

    typedef enum logic [2:0] {
        AccessAck     = 3'h0,
        AccessAckData = 3'h1
    } tl_d_opcode_e;
endpackage
