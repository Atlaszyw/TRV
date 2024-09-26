module wb
    import tinyriscv_pkg::*;
(
    input clk_i,
    input rst_ni,

    input [RegAddrBus - 1:0] reg_waddr_i,
    input [    RegBus - 1:0] reg_wdata_i,
    input                    reg_wen_i,

    output logic [RegAddrBus - 1:0] reg_waddr_o,
    output logic [    RegBus - 1:0] reg_wdata_o,
    output logic                    reg_wen_o
);

    always_comb begin : reg_ctrl_pass
        reg_waddr_o = reg_waddr_i;
        reg_wdata_o = reg_wdata_i;
        reg_wen_o   = reg_wen_i;
    end : reg_ctrl_pass

endmodule
