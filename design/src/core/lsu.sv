`timescale 1ns / 1ns

module lsu
    import tinyriscv_pkg::*;
(
    // CPU 内部接口
    input                   req_valid,
    output logic            req_ready,
    input            [31:0] addr,
    input            [31:0] wdata,
    output logic     [31:0] rdata,
    input  bytelen_e        bytelen,
    input                   ls,         // 00: load, 01: store
    input                   sign,

    // APB 接口
    apb4_intf.master apb_mst
);

    // 状态机状态定义
    typedef enum logic {
        DISABLE,
        ENABLE
    } state_t;

    state_t cs, ns;
    always_ff @(posedge apb_mst.PCLK) begin : state_tran
        if (~apb_mst.PRESETn) cs <= DISABLE;
        else cs <= ns;
    end : state_tran

    always_comb begin : state_next
        ns = cs;
        case (cs)
            DISABLE: if (req_valid) ns = ENABLE;
            ENABLE:  if (apb_mst.PREADY) ns = DISABLE;
            default: ;
        endcase

    end : state_next

    assign apb_mst.PENABLE = (cs == ENABLE);

    // 内部握手信号
    always_comb begin : comb_logic
        apb_mst.PSEL   = req_valid;
        apb_mst.PADDR  = {addr[31:2], 2'b00};
        apb_mst.PWRITE = ls;
        req_ready      = apb_mst.PREADY & apb_mst.PENABLE;
    end : comb_logic

    always_comb begin : rdata_logic
        rdata = '0;
        if (apb_mst.PREADY & apb_mst.PENABLE & apb_mst.PSEL) begin
            case (bytelen)
                B: begin
                    if (sign)
                        case (addr[1:0])
                            2'b00:   rdata = {{24{apb_mst.PRDATA[7]}}, apb_mst.PRDATA[7:0]};
                            2'b01:   rdata = {{24{apb_mst.PRDATA[15]}}, apb_mst.PRDATA[15:8]};
                            2'b10:   rdata = {{24{apb_mst.PRDATA[23]}}, apb_mst.PRDATA[23:16]};
                            default: rdata = {{24{apb_mst.PRDATA[31]}}, apb_mst.PRDATA[31:24]};
                        endcase
                    else
                        case (addr[1:0])
                            2'b00:   rdata = {24'b0, apb_mst.PRDATA[7:0]};
                            2'b01:   rdata = {24'b0, apb_mst.PRDATA[15:8]};
                            2'b10:   rdata = {24'b0, apb_mst.PRDATA[23:16]};
                            default: rdata = {24'b0, apb_mst.PRDATA[31:24]};
                        endcase
                end
                H: begin
                    if (sign) begin
                        if (~addr[1]) rdata = {{16{apb_mst.PRDATA[15]}}, apb_mst.PRDATA[15:0]};
                        else rdata = {{16{apb_mst.PRDATA[31]}}, apb_mst.PRDATA[31:16]};
                    end
                    else begin
                        if (~addr[1]) rdata = {16'b0, apb_mst.PRDATA[15:0]};
                        else rdata = {16'b0, apb_mst.PRDATA[31:16]};
                    end

                end
                W: begin
                    rdata = apb_mst.PRDATA;
                end
                default: ;
            endcase
        end
    end : rdata_logic

    always_comb begin : wdata_pstrb_logic
        apb_mst.PWDATA = '0;
        apb_mst.PSTRB  = 4'b0000;
        if (apb_mst.PSEL) begin
            case (bytelen)
                B: begin
                    case (addr[1:0])
                        2'b00: begin
                            apb_mst.PWDATA = {24'b0, wdata[7:0]};
                            apb_mst.PSTRB  = 4'b0001;
                        end
                        2'b01: begin
                            apb_mst.PWDATA = {24'b0, wdata[7:0]};
                            apb_mst.PSTRB  = 4'b0010;
                        end
                        2'b10: begin
                            apb_mst.PWDATA = {24'b0, wdata[7:0]};
                            apb_mst.PSTRB  = 4'b0100;
                        end
                        2'b11: begin
                            apb_mst.PWDATA = {24'b0, wdata[7:0]};
                            apb_mst.PSTRB  = 4'b1000;
                        end
                    endcase
                end
                H: begin
                    case (addr[1])
                        1'b0: begin
                            apb_mst.PWDATA = {16'b0, wdata[15:0]};
                            apb_mst.PSTRB  = 4'b0011;
                        end
                        1'b1: begin
                            apb_mst.PWDATA = {wdata[15:0], 16'b0};
                            apb_mst.PSTRB  = 4'b1100;
                        end
                    endcase
                end
                W: begin
                    apb_mst.PWDATA = wdata;
                    apb_mst.PSTRB  = 4'b1111;
                end
                default: ;
            endcase
        end
        else;
    end : wdata_pstrb_logic

endmodule
