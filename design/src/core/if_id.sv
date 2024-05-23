/*
 Copyright 2019 Blue Liang, liangkangnan@163.com

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

// 将指令向译码模块传递
module if_id
    import tinyriscv_pkg::*;
(

    input clk_i,
    input rst_ni,

    input [    InstBus - 1:0] inst_i,           // 指令内容
    input [InstAddrBus - 1:0] inst_addr_i,      // 指令地址
    input [InstAddrBus - 1:0] inst_addr_next_i, // 下一指令地址

    input [Hold_Flag_Bus - 1:0] hold_flag_i,  // 流水线暂停标志

    input        [INT_BUS - 1:0] int_flag_i,  // 外设中断输入信号
    output logic [INT_BUS - 1:0] int_flag_o,

    output logic [    InstBus - 1:0] inst_o,           // 指令内容
    output logic [InstAddrBus - 1:0] inst_addr_o,      // 指令地址
    output logic [InstAddrBus - 1:0] inst_addr_next_o  // 下一指令地址
);

    logic en;
    logic clear;
    assign clear = hold_flag_i == Pipe_Clear;
    assign en    = (hold_flag_i == Pipe_Flow);

    logic [InstBus - 1:0] inst;
    gen_en_dff #(32, INST_NOP) inst_ff (
        .clk_i,
        .rst_ni(~clear & rst_ni),
        .en,
        .din   (inst_i),
        .qout  (inst)
    );
    assign inst_o = inst;

    logic [InstAddrBus - 1:0] inst_addr;
    gen_en_dff #(32, 0) inst_addr_ff (
        .clk_i,
        .rst_ni(~clear & rst_ni),
        .en,
        .din   (inst_addr_i),
        .qout  (inst_addr)
    );
    assign inst_addr_o = inst_addr;

    logic [InstAddrBus - 1:0] inst_addr_next;
    gen_en_dff #(32, 0) inst_addr_next_ff (
        .clk_i,
        .rst_ni(~clear & rst_ni),
        .en,
        .din   (inst_addr_next_i),
        .qout  (inst_addr_next)
    );
    assign inst_addr_next_o = inst_addr_next;

    logic [INT_BUS - 1:0] int_flag;
    gen_en_dff #(8, 0) int_ff (
        .clk_i,
        .rst_ni(~clear & rst_ni),
        .en,
        .din   (int_flag_i),
        .qout  (int_flag)
    );
    assign int_flag_o = int_flag;

endmodule
