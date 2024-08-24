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
// 译码模块
// 纯组合逻辑电路
module id
    import tinyriscv_pkg::*;
(

    input                     clk_i,
    input                     rst_ni,
    // from if_id
    input [    InstBus - 1:0] inst_i,      // 指令内容
    input [InstAddrBus - 1:0] inst_addr_i, // 指令地址

    // from regs
    input [RegBus - 1:0] reg1_rdata_i,  // 通用寄存器1输入数据
    input [RegBus - 1:0] reg2_rdata_i,  // 通用寄存器2输入数据

    // from csr logic
    input [RegBus - 1:0] csr_rdata_i,  // CSR寄存器输入数据

    // from ex
    input        ex_jump_flag_i,         // 跳转标志
    input        inst_addr_next_type_i,
    output logic inst_addr_next_type_o,

    input [Hold_Flag_Bus - 1:0] hold_flag_i,
    input                       ready_ex_i,
    input                       valid_if_id_i,

    output logic ready_id_ex_o,

    // to regs
    output logic [RegAddrBus - 1:0] reg1_raddr_o,  // 读通用寄存器1地址
    output logic [RegAddrBus - 1:0] reg2_raddr_o,  // 读通用寄存器2地址

    // to csr logic
    output logic [MemAddrBus - 1:0] csr_raddr_o,  // 读CSR寄存器地址

    // to ex
    output logic [MemAddrBus - 1:0] op1_o,
    output logic [MemAddrBus - 1:0] op2_o,

    output logic [     RegBus - 1:0] reg1_rdata_o,
    output logic [     RegBus - 1:0] reg2_rdata_o,
    output logic [    InstBus - 1:0] inst_o,        // 指令内容
    output logic [InstAddrBus - 1:0] inst_addr_o,   // 指令地址
    output logic                     reg_we_o,      // 写通用寄存器标志
    output logic [ RegAddrBus - 1:0] reg_waddr_o,   // 写通用寄存器地址
    output logic                     csr_we_o,      // 写CSR寄存器标志
    output logic [     RegBus - 1:0] csr_rdata_o,   // CSR寄存器数据
    output logic [ MemAddrBus - 1:0] csr_waddr_o,   // 写CSR寄存器地址
    output logic [     RegBus - 1:0] store_data_o

);

    wire [6:0] opcode = inst_i[6:0];
    wire [2:0] funct3 = inst_i[14:12];
    wire [6:0] funct7 = inst_i[31:25];
    wire [4:0] rd = inst_i[11:7];
    wire [4:0] rs1 = inst_i[19:15];
    wire [4:0] rs2 = inst_i[24:20];

    logic csr_we;
    logic reg_we;
    logic [MemAddrBus - 1:0] csr_waddr;
    logic [RegAddrBus - 1:0] reg_waddr;
    logic [RegBus - 1:0] op1;
    logic [RegBus - 1:0] op2;
    logic [RegBus - 1:0] store_data;

    logic en;
    logic clear;

    always_comb begin : ctrl_logic
        clear         = hold_flag_i == Pipe_Clear || ready_ex_i & ~valid_if_id_i;
        en            = ready_ex_i & valid_if_id_i;
        ready_id_ex_o = ready_ex_i;
    end : ctrl_logic

    always_comb begin
        csr_raddr_o  = '0;
        csr_waddr    = '0;
        csr_we       = ~WriteEnable;

        op1          = '0;
        op2          = '0;

        reg_we       = ~WriteEnable;
        reg_waddr    = '0;
        reg1_raddr_o = '0;
        reg2_raddr_o = '0;

        store_data   = '0;

        case (opcode)
            INST_TYPE_I: begin
                case (funct3)
                    INST_ADDI, INST_SLTI, INST_SLTIU, INST_XORI, INST_ORI, INST_ANDI, INST_SLLI, INST_SRI: begin
                        reg_we       = WriteEnable;
                        reg_waddr    = rd;
                        reg1_raddr_o = rs1;
                        op1          = reg1_rdata_i;
                        op2          = {{20{inst_i[31]}}, inst_i[31:20]};
                    end
                endcase
            end
            INST_TYPE_R_M: begin
                if ((funct7 == 7'b0000000) || (funct7 == 7'b0100000)) begin
                    case (funct3)
                        INST_ADD_SUB, INST_SLL, INST_SLT, INST_SLTU, INST_XOR, INST_SR, INST_OR, INST_AND: begin
                            reg_we       = WriteEnable;
                            reg_waddr    = rd;
                            reg1_raddr_o = rs1;
                            reg2_raddr_o = rs2;
                            op1          = reg1_rdata_i;
                            op2          = reg2_rdata_i;
                        end
                    endcase
                end
                else if (funct7 == 7'b0000001) begin
                    case (funct3)
                        INST_MUL, INST_MULHU, INST_MULH, INST_MULHSU, INST_DIV, INST_DIVU, INST_REM, INST_REMU: begin
                            reg_we       = WriteEnable;
                            reg_waddr    = rd;
                            reg1_raddr_o = rs1;
                            reg2_raddr_o = rs2;
                            op1          = reg1_rdata_i;
                            op2          = reg2_rdata_i;
                        end
                    endcase
                end
            end
            INST_TYPE_L: begin
                case (funct3)
                    INST_LB, INST_LH, INST_LW, INST_LBU, INST_LHU: begin
                        reg1_raddr_o = rs1;
                        reg_we       = WriteEnable;
                        reg_waddr    = rd;
                        op1          = reg1_rdata_i;
                        op2          = {{20{inst_i[31]}}, inst_i[31:20]};
                    end
                    default: ;
                endcase
            end
            INST_TYPE_S: begin
                case (funct3)
                    INST_SB, INST_SW, INST_SH: begin
                        reg1_raddr_o = rs1;
                        reg2_raddr_o = rs2;
                        op1          = reg1_rdata_i;
                        op2          = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
                        store_data   = reg2_rdata_i;
                    end
                    default: ;
                endcase
            end
            INST_TYPE_B: begin
                case (funct3)
                    INST_BEQ, INST_BNE, INST_BLT, INST_BGE, INST_BLTU, INST_BGEU: begin
                        reg1_raddr_o = rs1;
                        reg2_raddr_o = rs2;
                        op1          = inst_addr_i;
                        op2          = {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
                    end
                    default: ;
                endcase
            end
            INST_JAL: begin
                reg_we    = WriteEnable;
                reg_waddr = rd;
                op1       = inst_addr_i;
                op2       = {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
            end
            INST_JALR: begin
                reg_we       = WriteEnable;
                reg1_raddr_o = rs1;
                reg_waddr    = rd;
                op1          = reg1_rdata_i;
                op2          = {{20{inst_i[31]}}, inst_i[31:20]};
            end
            INST_LUI: begin
                reg_we    = WriteEnable;
                reg_waddr = rd;
                op1       = {inst_i[31:12], 12'b0};
            end
            INST_AUIPC: begin
                reg_we    = WriteEnable;
                reg_waddr = rd;
                op1       = inst_addr_i;
                op2       = {inst_i[31:12], 12'b0};
            end
            INST_FENCE: begin
                // Pass
            end
            INST_CSR: begin
                csr_raddr_o = {20'h0, inst_i[31:20]};
                csr_waddr   = {20'h0, inst_i[31:20]};
                case (funct3)
                    INST_CSRRW, INST_CSRRS, INST_CSRRC: begin
                        reg1_raddr_o = rs1;
                        op1          = reg1_rdata_i;
                        reg_we       = WriteEnable;
                        reg_waddr    = rd;
                        csr_we       = WriteEnable;
                    end
                    INST_CSRRWI, INST_CSRRSI, INST_CSRRCI: begin
                        reg_we    = WriteEnable;
                        reg_waddr = rd;
                        csr_we    = WriteEnable;
                    end
                    default: ;
                endcase
            end
            default: ;
        endcase
    end


    prim_endff #(32, INST_NOP) inst_ff (
        .clk_i,
        .rst_ni(~clear & rst_ni),
        .en    (en),
        .din   (inst_i),
        .qout  (inst_o)
    );

    prim_endff #(32, 0) inst_addr_ff (
        .clk_i,
        .rst_ni(~clear & rst_ni),
        .en    (en),
        .din   (inst_addr_i),
        .qout  (inst_addr_o)
    );

    prim_endff #(1, 0) inst_addr_next_type_ff (
        .clk_i,
        .rst_ni(~clear & rst_ni),
        .en    (en),
        .din   (inst_addr_next_type_i),
        .qout  (inst_addr_next_type_o)
    );

    prim_endff #(1, 0) reg_we_ff (
        .clk_i,
        .rst_ni(~clear & rst_ni),
        .en    (en),
        .din   (reg_we),
        .qout  (reg_we_o)
    );

    prim_endff #(5, 0) reg_waddr_ff (
        .clk_i,
        .rst_ni(~clear & rst_ni),
        .en    (en),
        .din   (reg_waddr),
        .qout  (reg_waddr_o)
    );

    prim_endff #(1, 0) csr_we_ff (
        .clk_i,
        .rst_ni(~clear & rst_ni),
        .en    (en),
        .din   (csr_we),
        .qout  (csr_we_o)
    );

    prim_endff #(32, 0) csr_waddr_ff (
        .clk_i,
        .rst_ni(~clear & rst_ni),
        .en    (en),
        .din   (csr_waddr),
        .qout  (csr_waddr_o)
    );

    prim_endff #(32, 0) csr_rdata_ff (
        .clk_i,
        .rst_ni(~clear & rst_ni),
        .en    (en),
        .din   (csr_rdata_i),
        .qout  (csr_rdata_o)
    );

    prim_endff #(32, 0) op1_ff (
        .clk_i,
        .rst_ni(~clear & rst_ni),
        .en    (en),
        .din   (op1),
        .qout  (op1_o)
    );

    prim_endff #(32, 0) op2_ff (
        .clk_i,
        .rst_ni(~clear & rst_ni),
        .en    (en),
        .din   (op2),
        .qout  (op2_o)
    );

    prim_endff #(32, 0) reg1_rdata_ff (
        .clk_i,
        .rst_ni(~clear & rst_ni),
        .en    (en),
        .din   (reg1_rdata_i),
        .qout  (reg1_rdata_o)
    );

    prim_endff #(32, 0) reg2_rdata_ff (
        .clk_i,
        .rst_ni(~clear & rst_ni),
        .en    (en),
        .din   (reg2_rdata_i),
        .qout  (reg2_rdata_o)
    );

    prim_endff #(RegBus, 0) store_data_ff (
        .clk_i,
        .rst_ni(~clear & rst_ni),
        .en    (en),
        .din   (store_data),
        .qout  (store_data_o)
    );


endmodule
