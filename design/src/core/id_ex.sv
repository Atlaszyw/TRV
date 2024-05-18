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

// 将译码结果向执行模块传递
module id_ex
    import tinyriscv_pkg::*;
(

    input clk_i,
    input rst_ni,

    input [    InstBus - 1:0] inst_i,        // 指令内容
    input [InstAddrBus - 1:0] inst_addr_i,   // 指令地址
    input                     reg_we_i,      // 写通用寄存器标志
    input [ RegAddrBus - 1:0] reg_waddr_i,   // 写通用寄存器地址
    input [     RegBus - 1:0] reg1_rdata_i,  // 通用寄存器1读数据
    input [     RegBus - 1:0] reg2_rdata_i,  // 通用寄存器2读数据
    input                     csr_we_i,      // 写CSR寄存器标志
    input [ MemAddrBus - 1:0] csr_waddr_i,   // 写CSR寄存器地址
    input [     RegBus - 1:0] csr_rdata_i,   // CSR寄存器读数据
    input [ MemAddrBus - 1:0] op1_i,
    input [ MemAddrBus - 1:0] op2_i,
    input [ MemAddrBus - 1:0] op1_jump_i,
    input [ MemAddrBus - 1:0] op2_jump_i,

    input [Hold_Flag_Bus - 1:0] hold_flag_i,  // 流水线暂停标志

    output logic [ MemAddrBus - 1:0] op1_o,
    output logic [ MemAddrBus - 1:0] op2_o,
    output logic [ MemAddrBus - 1:0] op1_jump_o,
    output logic [ MemAddrBus - 1:0] op2_jump_o,
    output logic [    InstBus - 1:0] inst_o,        // 指令内容
    output logic [InstAddrBus - 1:0] inst_addr_o,   // 指令地址
    output logic                     reg_we_o,      // 写通用寄存器标志
    output logic [ RegAddrBus - 1:0] reg_waddr_o,   // 写通用寄存器地址
    output logic [     RegBus - 1:0] reg1_rdata_o,  // 通用寄存器1读数据
    output logic [     RegBus - 1:0] reg2_rdata_o,  // 通用寄存器2读数据
    output logic                     csr_we_o,      // 写CSR寄存器标志
    output logic [ MemAddrBus - 1:0] csr_waddr_o,   // 写CSR寄存器地址
    output logic [     RegBus - 1:0] csr_rdata_o    // CSR寄存器读数据

);

    wire hold_en = (hold_flag_i >= Hold_Id);

    wire [InstBus - 1:0] inst;
    gen_pipe_dff #(32) inst_ff (
        clk_i,
        rst_ni,
        hold_en,
         INST_NOP,
        inst_i,
        inst
    );
    assign inst_o = inst;

    wire [InstAddrBus - 1:0] inst_addr;
    gen_pipe_dff #(32) inst_addr_ff (
        clk_i,
        rst_ni,
        hold_en,
        '0,
        inst_addr_i,
        inst_addr
    );
    assign inst_addr_o = inst_addr;

    wire reg_we;
    gen_pipe_dff #(1) reg_we_ff (
        clk_i,
        rst_ni,
        hold_en,
        ~WriteEnable,
        reg_we_i,
        reg_we
    );
    assign reg_we_o = reg_we;

    wire [RegAddrBus - 1:0] reg_waddr;
    gen_pipe_dff #(5) reg_waddr_ff (
        clk_i,
        rst_ni,
        hold_en,
        '0,
        reg_waddr_i,
        reg_waddr
    );
    assign reg_waddr_o = reg_waddr;

    wire [RegBus - 1:0] reg1_rdata;
    gen_pipe_dff #(32) reg1_rdata_ff (
        clk_i,
        rst_ni,
        hold_en,
        '0,
        reg1_rdata_i,
        reg1_rdata
    );
    assign reg1_rdata_o = reg1_rdata;

    wire [RegBus - 1:0] reg2_rdata;
    gen_pipe_dff #(32) reg2_rdata_ff (
        clk_i,
        rst_ni,
        hold_en,
        '0,
        reg2_rdata_i,
        reg2_rdata
    );
    assign reg2_rdata_o = reg2_rdata;

    wire csr_we;
    gen_pipe_dff #(1) csr_we_ff (
        clk_i,
        rst_ni,
        hold_en,
        ~WriteEnable,
        csr_we_i,
        csr_we
    );
    assign csr_we_o = csr_we;

    wire [MemAddrBus - 1:0] csr_waddr;
    gen_pipe_dff #(32) csr_waddr_ff (
        clk_i,
        rst_ni,
        hold_en,
        '0,
        csr_waddr_i,
        csr_waddr
    );
    assign csr_waddr_o = csr_waddr;

    wire [RegBus - 1:0] csr_rdata;
    gen_pipe_dff #(32) csr_rdata_ff (
        clk_i,
        rst_ni,
        hold_en,
        '0,
        csr_rdata_i,
        csr_rdata
    );
    assign csr_rdata_o = csr_rdata;

    wire [MemAddrBus - 1:0] op1;
    gen_pipe_dff #(32) op1_ff (
        clk_i,
        rst_ni,
        hold_en,
        '0,
        op1_i,
        op1
    );
    assign op1_o = op1;

    wire [MemAddrBus - 1:0] op2;
    gen_pipe_dff #(32) op2_ff (
        clk_i,
        rst_ni,
        hold_en,
        '0,
        op2_i,
        op2
    );
    assign op2_o = op2;

    wire [MemAddrBus - 1:0] op1_jump;
    gen_pipe_dff #(32) op1_jump_ff (
        clk_i,
        rst_ni,
        hold_en,
        '0,
        op1_jump_i,
        op1_jump
    );
    assign op1_jump_o = op1_jump;

    wire [MemAddrBus - 1:0] op2_jump;
    gen_pipe_dff #(32) op2_jump_ff (
        clk_i,
        rst_ni,
        hold_en,
        '0,
        op2_jump_i,
        op2_jump
    );
    assign op2_jump_o = op2_jump;

endmodule
