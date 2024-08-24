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
// tinyriscv处理器核顶层模块
module tinyriscv
    import tinyriscv_pkg::*;
(

    input clk_i,
    input rst_ni,

    output logic [MemAddrBus - 1:0] rib_ex_addr_o,   // 读、写外设的地址
    input        [    MemBus - 1:0] rib_ex_data_i,   // 从外设读取的数据
    output logic [    MemBus - 1:0] rib_ex_data_o,   // 写入外设的数据
    output logic                    rib_ex_req_o,    // 访问外设请求
    input  logic                    rib_ex_ready_i,
    output logic                    rib_ex_we_o,     // 写外设标志

    output logic [MemAddrBus - 1:0] rib_pc_addr_o,  // 取指地址
    input        [    MemBus - 1:0] rib_pc_data_i,  // 取到的指令内容
    input                           rib_pc_ready_i,

    input        [RegAddrBus - 1:0] jtag_reg_addr_i,  // jtag模块读、写寄存器的地址
    input        [    RegBus - 1:0] jtag_reg_data_i,  // jtag模块写寄存器数据
    input                           jtag_reg_we_i,    // jtag模块写寄存器标志
    output logic [    RegBus - 1:0] jtag_reg_data_o,  // jtag模块读取到的寄存器数据

    input rib_hold_flag_i,   // 总线暂停标志
    input jtag_halt_flag_i,  // jtag暂停标志
    input jtag_reset_flag_i, // jtag复位PC标志

    input [INT_BUS - 1:0] int_i,  // 中断信号


    output succ,
    output over
);


    // pc_reg模块输出信号
    logic [  InstAddrBus - 1:0] pc_real;
    logic                       f_pc_next_type;
    logic                       fd_pc_next_type;
    logic                       de_pc_next_type;

    logic [      InstBus - 1:0] if_instr;
    logic                       instr_valid;
    logic                       rib_pc_req;

    // if_id模块输出信号
    logic [      InstBus - 1:0] fd_inst;
    logic [  InstAddrBus - 1:0] fd_inst_addr;
    logic [      INT_BUS - 1:0] if_int_flag_o;
    logic                       valid_if_id;

    // id模块输出信号
    logic                       ready_id_ex;
    logic [   RegAddrBus - 1:0] id_reg1_raddr;
    logic [   RegAddrBus - 1:0] id_reg2_raddr;
    logic [      InstBus - 1:0] de_inst;
    logic [  InstAddrBus - 1:0] de_inst_addr;
    logic [       RegBus - 1:0] de_reg1_rdata;
    logic [       RegBus - 1:0] de_reg2_rdata;
    logic                       de_reg_we;
    logic [   RegAddrBus - 1:0] de_reg_waddr;
    logic [   MemAddrBus - 1:0] csr_raddr;
    logic                       de_csr_we;
    logic [       RegBus - 1:0] de_csr_rdata;
    logic [   MemAddrBus - 1:0] de_csr_waddr;
    logic [   MemAddrBus - 1:0] de_op1;
    logic [   MemAddrBus - 1:0] de_op2;
    logic [       MemBus - 1:0] de_store_data;

    // ex模块输出信号
    logic [       MemBus - 1:0] ex_mem_wdata_o;
    logic [   MemAddrBus - 1:0] ex_mem_addr_o;
    logic                       ex_mem_we_o;
    logic                       ex_mem_req_o;
    logic                       ex_mem_ready_i;
    logic [       RegBus - 1:0] ex_reg_wdata_o;
    logic                       ex_reg_we_o;
    logic [   RegAddrBus - 1:0] ex_reg_waddr_o;
    logic                       ex_hold_flag_o;
    logic                       ex_jump_flag_o;
    logic [  InstAddrBus - 1:0] ex_jump_addr_o;
    logic                       ex_div_start_o;
    logic [       RegBus - 1:0] ex_div_dividend_o;
    logic [       RegBus - 1:0] ex_div_divisor_o;
    logic [                2:0] ex_div_op_o;
    logic [   RegAddrBus - 1:0] ex_div_reg_waddr_o;
    logic [       RegBus - 1:0] ex_csr_wdata_o;
    logic                       ex_csr_we;
    logic [   MemAddrBus - 1:0] ex_csr_waddr;
    logic                       ex_ready;

    // regs模块输出信号
    logic [       RegBus - 1:0] regs_rdata1;
    logic [       RegBus - 1:0] regs_rdata2;

    // csr_reg模块输出信号
    logic [       RegBus - 1:0] csr_data;
    logic [       RegBus - 1:0] csr_clint_data_o;
    logic                       csr_global_int_en_o;
    logic [       RegBus - 1:0] csr_clint_csr_mtvec;
    logic [       RegBus - 1:0] csr_clint_csr_mepc;
    logic [       RegBus - 1:0] csr_clint_csr_mstatus;

    // ctrl模块输出信号
    logic [Hold_Flag_Bus - 1:0] ctrl_hold_flag_o;
    logic                       ctrl_jump_flag_o;
    logic [  InstAddrBus - 1:0] ctrl_jump_addr_o;

    // div模块输出信号
    logic [       RegBus - 1:0] div_result_o;
    logic                       div_ready_o;
    logic                       div_busy_o;
    logic [   RegAddrBus - 1:0] div_reg_waddr_o;

    // clint模块输出信号
    logic                       clint_we_o;
    logic [   MemAddrBus - 1:0] clint_waddr_o;
    logic [   MemAddrBus - 1:0] clint_raddr_o;
    logic [       RegBus - 1:0] clint_data_o;
    logic [  InstAddrBus - 1:0] clint_int_addr_o;
    logic                       clint_int_assert_o;
    logic                       clint_hold_flag_o;


    assign rib_ex_addr_o  = ex_mem_addr_o;
    assign rib_ex_data_o  = ex_mem_wdata_o;
    assign rib_ex_req_o   = ex_mem_req_o;
    assign rib_ex_we_o    = ex_mem_we_o;
    assign ex_mem_ready_i = rib_ex_ready_i;

    instr_fetch instr_f (
        .clk_i,
        .rst_ni,

        .instr_ready_i(rib_pc_ready_i),
        .instr_req_i  (rib_pc_req),

        .jump_flag_i      (ctrl_jump_flag_o),
        .jump_addr_i      (ctrl_jump_addr_o),
        .jtag_reset_flag_i(jtag_reset_flag_i),
        .instr_i          (rib_pc_data_i),

        .instr_o      (if_instr),
        .instr_valid_o(instr_valid),

        .pc_o          (rib_pc_addr_o),  // PC指针
        .pc_real       (pc_real),
        .pc_next_type_o(f_pc_next_type)
    );

    // ctrl模块例化
    ctrl u_ctrl (
        .jump_flag_i      (ex_jump_flag_o),
        .jump_addr_i      (ex_jump_addr_o),
        .hold_flag_rib_i  (rib_hold_flag_i),
        .hold_flag_o      (ctrl_hold_flag_o),
        .hold_flag_clint_i(clint_hold_flag_o),
        .jump_flag_o      (ctrl_jump_flag_o),
        .jump_addr_o      (ctrl_jump_addr_o),
        .jtag_halt_flag_i (jtag_halt_flag_i)
    );

    // regs模块例化
    regs u_regs (
        .clk_i,
        .rst_ni,
        .we_i       (ex_reg_we_o),
        .waddr_i    (ex_reg_waddr_o),
        .wdata_i    (ex_reg_wdata_o),
        .raddr1_i   (id_reg1_raddr),
        .rdata1_o   (regs_rdata1),
        .raddr2_i   (id_reg2_raddr),
        .rdata2_o   (regs_rdata2),
        .jtag_we_i  (jtag_reg_we_i),
        .jtag_addr_i(jtag_reg_addr_i),
        .jtag_data_i(jtag_reg_data_i),
        .jtag_data_o(jtag_reg_data_o),

        .succ,
        .over
    );

    // csr_reg模块例化
    csr_reg u_csr_reg (
        .clk_i,
        .rst_ni,
        .we_i             (ex_csr_we),
        .raddr_i          (csr_raddr),
        .waddr_i          (ex_csr_waddr),
        .data_i           (ex_csr_wdata_o),
        .data_o           (csr_data),
        .global_int_en_o  (csr_global_int_en_o),
        .clint_we_i       (clint_we_o),
        .clint_raddr_i    (clint_raddr_o),
        .clint_waddr_i    (clint_waddr_o),
        .clint_data_i     (clint_data_o),
        .clint_data_o     (csr_clint_data_o),
        .clint_csr_mtvec  (csr_clint_csr_mtvec),
        .clint_csr_mepc   (csr_clint_csr_mepc),
        .clint_csr_mstatus(csr_clint_csr_mstatus)
    );

    // if_id模块例化
    if_id u_if_id (
        .clk_i (clk_i),
        .rst_ni(rst_ni),

        .ready_from_id_ex_i(ready_id_ex),

        .instr_req_o     (rib_pc_req),
        .instr_ready_i   (instr_valid),
        .valid_to_id_ex_o(valid_if_id),

        .inst_i               (if_instr),
        .inst_addr_i          (pc_real),
        .inst_addr_next_type_i(f_pc_next_type),
        .inst_addr_next_type_o(fd_pc_next_type),
        .int_flag_i           (int_i),
        .int_flag_o           (if_int_flag_o),
        .hold_flag_i          (ctrl_hold_flag_o),
        .inst_o               (fd_inst),
        .inst_addr_o          (fd_inst_addr)
    );

    // id模块例化
    id u_id (
        .clk_i,
        .rst_ni,
        .hold_flag_i  (ctrl_hold_flag_o),
        .ready_ex_i   (ex_ready),
        .valid_if_id_i(valid_if_id),
        .ready_id_ex_o(ready_id_ex),

        .inst_o      (de_inst),
        .inst_i      (fd_inst),
        .inst_addr_o (de_inst_addr),
        .inst_addr_i (fd_inst_addr),
        .reg1_rdata_o(de_reg1_rdata),
        .reg1_rdata_i(regs_rdata1),
        .reg2_rdata_o(de_reg2_rdata),
        .reg2_rdata_i(regs_rdata2),

        .ex_jump_flag_i(ex_jump_flag_o),

        .reg1_raddr_o(id_reg1_raddr),
        .reg2_raddr_o(id_reg2_raddr),
        .reg_we_o    (de_reg_we),
        .reg_waddr_o (de_reg_waddr),

        .inst_addr_next_type_i(fd_pc_next_type),
        .inst_addr_next_type_o(de_pc_next_type),

        .op1_o       (de_op1),
        .op2_o       (de_op2),
        .csr_rdata_i (csr_data),
        .csr_raddr_o (csr_raddr),
        .csr_we_o    (de_csr_we),
        .csr_rdata_o (de_csr_rdata),
        .csr_waddr_o (de_csr_waddr),
        .store_data_o(de_store_data)
    );

    // ex模块例化
    ex u_ex (
        .clk_i,
        .rst_ni,

        .ready_o(ex_ready),

        .inst_i               (de_inst),
        .inst_addr_i          (de_inst_addr),
        .inst_addr_next_type_i(de_pc_next_type),
        .reg_we_i             (de_reg_we),
        .reg_waddr_i          (de_reg_waddr),

        .op1_i(de_op1),
        .op2_i(de_op2),

        .reg1_rdata_i(de_reg1_rdata),
        .reg2_rdata_i(de_reg2_rdata),

        .mem_rdata_i(rib_ex_data_i),
        .mem_wdata_o(ex_mem_wdata_o),
        .mem_addr_o (ex_mem_addr_o),
        .mem_we_o   (ex_mem_we_o),
        .mem_req_o  (ex_mem_req_o),
        .mem_ready_i(ex_mem_ready_i),

        .reg_wdata_o(ex_reg_wdata_o),
        .reg_we_o   (ex_reg_we_o),
        .reg_waddr_o(ex_reg_waddr_o),

        .jump_flag_o (ex_jump_flag_o),
        .jump_addr_o (ex_jump_addr_o),
        .int_assert_i(clint_int_assert_o),
        .int_addr_i  (clint_int_addr_o),

        .csr_we_i    (de_csr_we),
        .csr_waddr_i (de_csr_waddr),
        .csr_rdata_i (de_csr_rdata),
        .csr_wdata_o (ex_csr_wdata_o),
        .csr_we_o    (ex_csr_we),
        .csr_waddr_o (ex_csr_waddr),
        .store_data_i(de_store_data)
    );

    // clint模块例化
    clint u_clint (
        .clk_i          (clk_i),
        .rst_ni         (rst_ni),
        .int_flag_i     (if_int_flag_o),
        .inst_i         (de_inst),
        .inst_addr_i    (de_inst_addr),
        .jump_flag_i    (ex_jump_flag_o),
        .jump_addr_i    (ex_jump_addr_o),
        .hold_flag_i    (ctrl_hold_flag_o),
        .div_started_i  (ex_div_start_o),
        .data_i         (csr_clint_data_o),
        .csr_mtvec      (csr_clint_csr_mtvec),
        .csr_mepc       (csr_clint_csr_mepc),
        .csr_mstatus    (csr_clint_csr_mstatus),
        .we_o           (clint_we_o),
        .waddr_o        (clint_waddr_o),
        .raddr_o        (clint_raddr_o),
        .data_o         (clint_data_o),
        .hold_flag_o    (clint_hold_flag_o),
        .global_int_en_i(csr_global_int_en_o),
        .int_addr_o     (clint_int_addr_o),
        .int_assert_o   (clint_int_assert_o)
    );

endmodule
