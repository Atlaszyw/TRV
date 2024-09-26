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
    input [RegBus - 1:0] rs1_rdata_i,  // 通用寄存器1输入数据
    input [RegBus - 1:0] rs2_rdata_i,  // 通用寄存器2输入数据

    // from csr logic
    input [RegBus - 1:0] csr_rdata_i,  // CSR寄存器输入数据

    // from ex
    input        ex_jump_flag_i,         // 跳转标志
    input        inst_addr_next_type_i,
    output logic inst_addr_next_type_o,

    input [Hold_Flag_Bus - 1:0] hold_flag_i,
    input                       ready_ex_i,
    input                       valid_if_id_i,

    output logic ready_if_id_o,

    // to regs
    output logic [RegAddrBus - 1:0] rs1_raddr_o,  // 读通用寄存器1地址
    output logic [RegAddrBus - 1:0] rs2_raddr_o,  // 读通用寄存器2地址
    output logic                    r1_en_o,
    output logic                    r2_en_o,

    // to csr logic
    output logic [MemAddrBus - 1:0] csr_raddr_o,  // 读CSR寄存器地址

    // to ex

    output logic [     RegBus - 1:0] rs1_rdata_o,
    output logic [     RegBus - 1:0] rs2_rdata_o,
    output logic [ RegAddrBus - 1:0] rs1_raddr_pass_o,  // 读通用寄存器1地址
    output logic [ RegAddrBus - 1:0] rs2_raddr_pass_o,  // 读通用寄存器2地址
    output logic [    InstBus - 1:0] inst_o,            // 指令内容
    output logic [InstAddrBus - 1:0] inst_addr_o,       // 指令地址
    output logic [ RegAddrBus - 1:0] reg_waddr_o,       // 写通用寄存器地址
    output logic [     RegBus - 1:0] csr_rdata_o,       // CSR寄存器数据
    output logic [ MemAddrBus - 1:0] csr_waddr_o        // 写CSR寄存器地址
);

    opcode_e opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [4:0] rd;
    logic [4:0] rs1;
    logic [4:0] rs2;

    always_comb begin
        opcode = opcode_e'(inst_i[6:0]);
        funct3 = inst_i[14:12];
        funct7 = inst_i[31:25];
        rd     = inst_i[11:7];
        rs1    = inst_i[19:15];
        rs2    = inst_i[24:20];
    end


    logic [MemAddrBus - 1:0] csr_waddr;
    logic [RegAddrBus - 1:0] reg_waddr;

    logic en;
    logic clear;

    always_comb begin : ctrl_logic
        clear         = hold_flag_i == Pipe_Clear || ready_ex_i & (1'b1 & ~valid_if_id_i);
        en            = 1'b1 & ready_ex_i & valid_if_id_i;
        ready_if_id_o = 1'b1 & ready_ex_i;
    end : ctrl_logic

    always_comb begin
        csr_raddr_o = '0;
        csr_waddr   = '0;

        r1_en_o     = '0;
        r2_en_o     = '0;

        reg_waddr   = rd;
        rs1_raddr_o = rs1;
        rs2_raddr_o = rs2;

        case (opcode)
            INST_TYPE_I: begin
                case (funct3)
                    INST_ADDI, INST_SLTI, INST_SLTIU, INST_XORI, INST_ORI, INST_ANDI, INST_SLLI, INST_SRI: begin
                        r1_en_o = '1;
                    end
                endcase
            end
            INST_TYPE_R_M: begin
                if ((funct7 == 7'b0000000) || (funct7 == 7'b0100000)) begin
                    case (funct3)
                        INST_ADD_SUB, INST_SLL, INST_SLT, INST_SLTU, INST_XOR, INST_SR, INST_OR, INST_AND: begin
                            r1_en_o = '1;
                            r2_en_o = '1;
                        end
                    endcase
                end
                else if (funct7 == 7'b0000001) begin
                    case (funct3)
                        INST_MUL, INST_MULHU, INST_MULH, INST_MULHSU, INST_DIV, INST_DIVU, INST_REM, INST_REMU: begin
                            r1_en_o = '1;
                            r2_en_o = '1;
                        end
                    endcase
                end
            end
            INST_TYPE_L: begin
                case (funct3)
                    INST_LB, INST_LH, INST_LW, INST_LBU, INST_LHU: begin
                        r1_en_o = '1;
                    end
                    default: ;
                endcase
            end
            INST_TYPE_S: begin
                case (funct3)
                    INST_SB, INST_SW, INST_SH: begin
                        r1_en_o = '1;
                        r2_en_o = '1;
                    end
                    default: ;
                endcase
            end
            INST_TYPE_B: begin
                case (funct3)
                    INST_BEQ, INST_BNE, INST_BLT, INST_BGE, INST_BLTU, INST_BGEU: begin
                        r1_en_o = '1;
                        r2_en_o = '1;
                    end
                    default: ;
                endcase
            end
            INST_JAL: begin
                ;
            end
            INST_JALR: begin
                r1_en_o = '1;
            end
            INST_LUI: begin
                ;
            end
            INST_AUIPC: begin
                ;
            end
            INST_FENCE: begin
                ;
            end
            INST_CSR: begin
                csr_raddr_o = {20'h0, inst_i[31:20]};
                csr_waddr   = {20'h0, inst_i[31:20]};
                case (funct3)
                    INST_CSRRW, INST_CSRRS, INST_CSRRC: begin
                        r1_en_o = '1;
                    end
                    INST_CSRRWI, INST_CSRRSI, INST_CSRRCI: begin
                        ;
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


    prim_endff #(5, 0) reg_waddr_ff (
        .clk_i,
        .rst_ni(~clear & rst_ni),
        .en    (en),
        .din   (reg_waddr),
        .qout  (reg_waddr_o)
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

    prim_endff #(32, 0) rs1_rdata_ff (
        .clk_i,
        .rst_ni(~clear & rst_ni),
        .en    (en),
        .din   (rs1_rdata_i),
        .qout  (rs1_rdata_o)
    );

    prim_endff #(32, 0) rs2_rdata_ff (
        .clk_i,
        .rst_ni(~clear & rst_ni),
        .en    (en),
        .din   (rs2_rdata_i),
        .qout  (rs2_rdata_o)
    );

    prim_endff #(RegAddrBus, 0) rs1_raddr_ff (
        .clk_i,
        .rst_ni(~clear & rst_ni),
        .en    (en),
        .din   (rs1_raddr_o),
        .qout  (rs1_raddr_pass_o)
    );

    prim_endff #(RegAddrBus, 0) rs2_raddr_ff (
        .clk_i,
        .rst_ni(~clear & rst_ni),
        .en    (en),
        .din   (rs2_raddr_o),
        .qout  (rs2_raddr_pass_o)
    );

endmodule
