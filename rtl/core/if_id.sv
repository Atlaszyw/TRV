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

    input clk,
    input rst,

    input [    InstBus - 1:0] inst_i,      // 指令内容
    input [InstAddrBus - 1:0] inst_addr_i, // 指令地址

    input [Hold_Flag_Bus - 1:0] hold_flag_i,  // 流水线暂停标志

    input  wire [INT_BUS - 1:0] int_flag_i,  // 外设中断输入信号
    output logic [INT_BUS - 1:0] int_flag_o,

    output logic [    InstBus - 1:0] inst_o,      // 指令内容
    output logic [InstAddrBus - 1:0] inst_addr_o  // 指令地址

);

    wire hold_en = (hold_flag_i >= Hold_If);

    wire [InstBus - 1:0] inst;
    gen_pipe_dff #(32) inst_ff (
        clk,
        rst,
        hold_en,
        INST_NOP,
        inst_i,
        inst
    );
    assign inst_o = inst;

    wire [InstAddrBus - 1:0] inst_addr;
    gen_pipe_dff #(32) inst_addr_ff (
        clk,
        rst,
        hold_en,
        ZeroWord,
        inst_addr_i,
        inst_addr
    );
    assign inst_addr_o = inst_addr;

    wire [INT_BUS - 1:0] int_flag;
    gen_pipe_dff #(8) int_ff (
        clk,
        rst,
        hold_en,
        INT_NONE,
        int_flag_i,
        int_flag
    );
    assign int_flag_o = int_flag;

endmodule
