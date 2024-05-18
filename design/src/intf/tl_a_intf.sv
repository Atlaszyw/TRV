interface tl_a_intf (
    input clock,
    input reset
);
    import tilelink_pkg::*;

    tl_a_opcode_e               opcode;
    logic         [        2:0] param;  // reserved must be 0
    logic         [ TL_SZW-1:0] size;
    logic         [TL_SRCW-1:0] source;
    logic         [  TL_AW-1:0] address;
    logic         [ TL_DBW-1:0] mask;
    logic         [  TL_DW-1:0] data;
    logic                       corrupt;
    logic                       valid;
    logic                       ready;

    modport master(output valid, opcode, param, size, source, address, mask, data, input ready);
    modport slave(input valid, opcode, param, size, source, address, mask, data, output ready);
endinterface  //tlul_a_intf
