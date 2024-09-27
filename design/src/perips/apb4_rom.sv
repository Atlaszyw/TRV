/*
 Copyright 2020 Blue Liang, liangkangnan@163.com

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

module apb4_rom
    import tinyriscv_pkg::*;
#(
    parameter int unsigned ADDR_WIDTH  = 13,       // 地址宽度（表示支持的地址空间，例如 4KB）
    parameter int unsigned DATA_WIDTH  = 32,       // 数据宽度（通常为 32 位或 64 位）
    parameter string       MemInitFile = "lw.mif"
) (
    // APB4 接口
    apb4_intf.slave apb_if,

    input [MemAddrBus - 1:0] addr_i,  // addr

    output logic [DATA_WIDTH - 1:0] data_o  // read data
);
    localparam int unsigned Depth = (1 << (ADDR_WIDTH - $clog2(DATA_WIDTH / 8))) - 1;
    localparam int unsigned Width = DATA_WIDTH;
    // 内部 RAM 存储器
    logic [                     DATA_WIDTH-1:0] mem       [Depth];

    // 内部信号
    logic [                     ADDR_WIDTH-1:0] addr_reg;
    logic [ADDR_WIDTH-1 : $clog2(DATA_WIDTH/8)] word_addr;

    assign word_addr = apb_if.PADDR[ADDR_WIDTH-1 : $clog2(DATA_WIDTH/8)];

    // 写操作
    always_ff @(posedge apb_if.PCLK) begin
        if (apb_if.PWRITE && apb_if.PENABLE && apb_if.PREADY) begin
            // 检查地址是否在范围内
            if (word_addr < (1 << (ADDR_WIDTH - $clog2(DATA_WIDTH / 8)))) begin
                // 使用 PSTRB 信号进行字节选通写入
                for (int i = 0; i < DATA_WIDTH / 8; i++) begin
                    if (apb_if.PSTRB[i]) begin
                        mem[word_addr][i*8 +: 8] <= apb_if.PWDATA[i*8 +: 8];
                    end
                end
            end
            // 如果地址超出范围，可以选择忽略或产生错误
        end
    end

    // 读操作
    logic [DATA_WIDTH-1:0] data_out;
    always_ff @(posedge apb_if.PCLK) begin
        if (~apb_if.PWRITE && apb_if.PSEL) begin
            // 检查地址是否在范围内
            if (word_addr < (1 << (ADDR_WIDTH - $clog2(DATA_WIDTH / 8)))) begin
                apb_if.PRDATA <= mem[word_addr];
            end
            else begin
                apb_if.PRDATA <= '0;  // 超出范围，返回默认值
            end
        end
    end

    always_comb begin
        if (~apb_if.PRESETn) data_o = '0;
        else data_o = mem[addr_i[$clog2(Depth) + 1:2]];
    end

    // PREADY 信号
    assign apb_if.PREADY  = 1'b1;  // RAM 访问速度快，无需等待

    // PSLVERR 信号
    assign apb_if.PSLVERR = 1'b0;  // 简单设计中，不产生错误信号

    `include "prim_memutil.svh"

endmodule
