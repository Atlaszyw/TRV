interface tl_d_intf (
    input clock,
    input reset
);
    import tilelink_pkg::*;

    tl_d_opcode_e                opcode;
    logic         [         2:0] param;
    logic         [  TL_SZW-1:0] size;
    logic         [ TL_SRCW-1:0] source;
    logic         [TL_SINKW-1:0] sink;
    logic         [   TL_DW-1:0] data;
    logic                        error;
    logic                        valid;
    logic                        ready;

    // d通道的master是从机
    modport master(output valid, opcode, param, size, source, sink, data, error, input ready);
    // d通道的slave是主机
    modport slave(input valid, opcode, param, size, source, sink, data, error, output ready);
endinterface  // tl_d_intf
