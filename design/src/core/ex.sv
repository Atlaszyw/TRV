// 执行模块
module ex
    import tinyriscv_pkg::*;
(
    input clk_i,
    input rst_ni,

    // from id
    input [    InstBus - 1:0] inst_i,                 // 指令内容
    input [InstAddrBus - 1:0] inst_addr_i,            // 指令地址
    input                     inst_addr_next_type_i,
    input [ RegAddrBus - 1:0] reg_waddr_i,            // 写通用寄存器地址
    input [ MemAddrBus - 1:0] csr_waddr_i,            // 写CSR寄存器地址
    input [     RegBus - 1:0] csr_rdata_i,            // CSR寄存器输入数据
    input                     int_assert_i,           // 中断发生标志
    input [InstAddrBus - 1:0] int_addr_i,             // 中断跳转地址
    input [     RegBus - 1:0] reg1_rdata_i,
    input [     RegBus - 1:0] reg2_rdata_i,
    input [ RegAddrBus - 1:0] reg1_raddr_i,
    input [ RegAddrBus - 1:0] reg2_raddr_i,

    // from bypass
    input [RegAddrBus - 1:0] ex_wb_waddr_i,
    input [    RegBus - 1:0] ex_wb_wdata_i,
    input                    ex_wb_wen_i,

    apb4_intf.master apb_mst,

    // to regs
    output logic [    RegBus - 1:0] reg_wdata_o,  // 写寄存器数据
    output logic                    reg_we_o,     // 是否要写通用寄存器
    output logic [RegAddrBus - 1:0] reg_waddr_o,  // 写通用寄存器地址

    // to csr logic
    output logic [    RegBus - 1:0] csr_wdata_o,  // 写CSR寄存器数据
    output logic                    csr_we_o,     // 是否要写CSR寄存器
    output logic [MemAddrBus - 1:0] csr_waddr_o,  // 写CSR寄存器地址

    // to ctrl
    output logic                     ready_o,      // 是否暂停标志
    output logic                     jump_flag_o,  // 是否跳转标志
    output logic [InstAddrBus - 1:0] jump_addr_o   // 跳转目的地址
);

    logic     [ MemAddrBus - 1:0] op1;
    logic     [ MemAddrBus - 1:0] op2;
    logic     [     RegBus - 1:0] reg1_rdata;
    logic     [     RegBus - 1:0] reg2_rdata;

    logic     [     RegBus - 1:0] store_data;

    logic                         csr_we;  // 是否写CSR寄存器
    logic     [ MemAddrBus - 1:0] mem_addr;  // 读内存地址
    logic                         mem_ready;
    logic                         sign;

    logic     [              1:0] mem_addr_index;
    logic                         compare;
    logic     [             31:0] sr_shift;
    logic     [             31:0] sri_shift;
    logic     [             31:0] sr_shift_mask;
    logic     [             31:0] sri_shift_mask;
    logic     [             31:0] op1_add_op2_res;

    opcode_e                      opcode;
    logic     [              2:0] funct3;
    logic     [              6:0] funct7;
    logic     [              4:0] rd;
    logic     [              4:0] uimm;
    logic     [     RegBus - 1:0] reg_wdata;
    logic     [     RegBus - 1:0] lsu_rdata;
    logic                         reg_we;
    logic                         reg_we_with_int;
    logic                         jump_flag;
    logic     [InstAddrBus - 1:0] jump_addr;

    logic                         mem_we;
    logic                         mem_req;
    logic                         mem_hold;

    bytelen_e                     bytelen;

    logic     [     RegBus - 1:0] div_data;
    logic     [     RegBus - 1:0] mult_data;
    logic mult_valid, mult_ready;
    logic div_valid, div_ready;
    logic mult_hold, div_hold;

    always_comb begin
        opcode = opcode_e'(inst_i[6:0]);
        funct3 = inst_i[14:12];
        funct7 = inst_i[31:25];
        rd     = inst_i[11:7];
        uimm   = inst_i[19:15];
    end

    always_comb begin : forward
        reg1_rdata = (ex_wb_wen_i && ex_wb_waddr_i == reg1_raddr_i) ? ex_wb_wdata_i : reg1_rdata_i;
        reg2_rdata = (ex_wb_wen_i && ex_wb_waddr_i == reg2_raddr_i) ? ex_wb_wdata_i : reg2_rdata_i;
    end : forward

    always_comb begin
        sr_shift       = op1 >> op2[4:0];
        sri_shift      = op1 >> inst_i[24:20];
        sr_shift_mask  = 32'hffffffff >> op2[4:0];
        sri_shift_mask = 32'hffffffff >> inst_i[24:20];
    end

    always_comb begin : add_logic
        op1_add_op2_res = op1 + op2;
    end : add_logic

    always_comb begin
        mem_addr_index  = op1_add_op2_res[1:0] & 2'b11;

        // 响应中断时不写通用寄存器
        reg_we_with_int = (int_assert_i) ? '0 : |reg_waddr_i ? reg_we : '0;
    end

    always_comb begin
        ready_o     = ~(div_hold | mult_hold | mem_hold);
        jump_flag_o = jump_flag || ((int_assert_i) ? 1'b1 : 1'b0);
        jump_addr_o = (int_assert_i) ? int_addr_i : jump_addr;
    end

    always_comb begin
        // 响应中断时不写CSR寄存器
        csr_we_o    = (int_assert_i) ? '0 : csr_we;
        csr_waddr_o = csr_waddr_i;
    end

    always_comb begin
        compare = '0;
        case (opcode)
            INST_TYPE_I: begin
                case (funct3)
                    INST_SLTI:  compare = $signed(reg1_rdata) >= $signed({{20{inst_i[31]}}, inst_i[31:20]});
                    INST_SLTIU: compare = reg1_rdata >= {{20{inst_i[31]}}, inst_i[31:20]};
                    default:    ;
                endcase
            end
            INST_TYPE_R_M: begin
                case (funct3)
                    INST_SLT:  compare = $signed(reg1_rdata) >= $signed(reg2_rdata);
                    INST_SLTU: compare = reg1_rdata >= reg2_rdata;
                    default:   ;
                endcase
            end
            INST_TYPE_B: begin
                case (funct3)
                    INST_BEQ, INST_BNE:   compare = reg1_rdata == reg2_rdata;
                    INST_BLT, INST_BGE:   compare = $signed(reg1_rdata) >= $signed(reg2_rdata);
                    INST_BLTU, INST_BGEU: compare = reg1_rdata >= reg2_rdata;
                    default:              ;
                endcase
            end
            default: ;
        endcase
    end

    // 处理乘除法指令
    always_comb begin
        div_valid  = '0;
        div_hold   = '0;
        mult_hold  = '0;
        mult_valid = '0;
        if ((opcode == INST_TYPE_R_M) && (funct7 == 7'b0000001)) begin
            case (funct3)
                INST_MUL, INST_MULHU, INST_MULH, INST_MULHSU: begin
                    mult_valid = (int_assert_i) ? '0 : '1;
                    mult_hold  = mult_valid ^ mult_ready;
                end
                INST_DIV, INST_DIVU, INST_REM, INST_REMU: begin
                    div_valid = (int_assert_i) ? '0 : '1;
                    div_hold  = div_valid ^ div_ready;
                end
            endcase
        end
    end

    always_comb begin
        mem_hold = mem_req & ~mem_ready;
    end

    // 单周期代码
    always_comb begin
        op1 = '0;
        op2 = '0;
        case (opcode)
            INST_TYPE_I: begin
                op1 = reg1_rdata;
                op2 = {{20{inst_i[31]}}, inst_i[31:20]};
            end
            INST_TYPE_R_M: begin
                op1 = reg1_rdata;
                op2 = reg2_rdata;
            end

            INST_TYPE_L: begin
                op1 = reg1_rdata;
                op2 = {{20{inst_i[31]}}, inst_i[31:20]};
            end
            INST_TYPE_S: begin
                op1 = reg1_rdata;
                op2 = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
            end
            INST_TYPE_B: begin
                op1 = inst_addr_i;
                op2 = {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
            end
            INST_JAL: begin
                op1 = inst_addr_i;
                op2 = {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
            end
            INST_JALR: begin
                op1 = reg1_rdata;
                op2 = {{20{inst_i[31]}}, inst_i[31:20]};
            end
            INST_LUI: begin
                op1 = {inst_i[31:12], 12'b0};
            end
            INST_AUIPC: begin
                op1 = inst_addr_i;
                op2 = {inst_i[31:12], 12'b0};
            end
            INST_FENCE: begin

            end
            INST_CSR: begin
                case (funct3)
                    INST_CSRRW, INST_CSRRS, INST_CSRRC: op1 = reg1_rdata;
                    default:                            ;
                endcase
            end
            default: ;
        endcase
    end

    // 单周期代码
    always_comb begin
        reg_we      = '0;
        reg_wdata   = '0;
        csr_wdata_o = '0;
        sign        = '0;

        jump_flag   = '0;
        jump_addr   = '0;
        mem_addr    = '0;
        mem_we      = '0;
        mem_req     = '0;
        store_data  = '0;
        csr_we      = '0;
        bytelen     = B;
        case (opcode)
            INST_TYPE_I: begin
                reg_we = '1;
                case (funct3)
                    INST_ADDI:  reg_wdata = op1_add_op2_res;
                    INST_SLTI:  reg_wdata = {32{(~compare)}} & 32'h1;
                    INST_SLTIU: reg_wdata = {32{(~compare)}} & 32'h1;
                    INST_XORI:  reg_wdata = op1 ^ op2;
                    INST_ORI:   reg_wdata = op1 | op2;
                    INST_ANDI:  reg_wdata = op1 & op2;
                    INST_SLLI:  reg_wdata = op1 << inst_i[24:20];
                    INST_SRI: begin
                        if (inst_i[30] == 1'b1) reg_wdata = (sri_shift & sri_shift_mask) | ({32{op1[31]}} & (~sri_shift_mask));
                        else reg_wdata = op1 >> inst_i[24:20];
                    end
                    default:    reg_wdata = '0;
                endcase
            end
            INST_TYPE_R_M: begin
                // I
                if ((funct7 == 7'b0000000) || (funct7 == 7'b0100000)) begin
                    reg_we = '1;
                    case (funct3)
                        INST_ADD_SUB: begin
                            if (inst_i[30] == 1'b0) reg_wdata = op1_add_op2_res;
                            else reg_wdata = op1 - op2;
                        end
                        INST_SLL:  reg_wdata = op1 << op2[4:0];
                        INST_SLT:  reg_wdata = {32{(~compare)}} & 32'h1;
                        INST_SLTU: reg_wdata = {32{(~compare)}} & 32'h1;
                        INST_XOR:  reg_wdata = op1 ^ op2;
                        INST_SR: begin
                            if (inst_i[30] == 1'b1) reg_wdata = (sr_shift & sr_shift_mask) | ({32{op1[31]}} & (~sr_shift_mask));
                            else reg_wdata = op1 >> op2[4:0];
                        end
                        INST_OR:   reg_wdata = op1 | op2;
                        INST_AND:  reg_wdata = op1 & op2;
                        default: begin
                            reg_wdata = '0;
                        end
                    endcase
                end
                // M
                else if (funct7 == 7'b0000001) begin
                    case (funct3)
                        INST_MUL, INST_MULHU, INST_MULH, INST_MULHSU: begin
                            reg_we    = mult_ready & mult_valid;
                            reg_wdata = mult_data;
                        end
                        INST_DIV, INST_DIVU, INST_REM, INST_REMU: begin
                            reg_we    = div_ready & div_valid;
                            reg_wdata = div_data;
                        end
                    endcase
                end
            end
            INST_TYPE_L: begin
                mem_req   = '1;
                reg_we    = mem_req & mem_ready;
                mem_addr  = op1_add_op2_res;
                reg_wdata = lsu_rdata;
                case (funct3)
                    INST_LB: begin
                        bytelen = B;
                        sign    = '1;
                    end
                    INST_LH: begin
                        bytelen = H;
                        sign    = '1;
                    end
                    INST_LW: begin
                        bytelen = W;
                        sign    = '0;
                    end
                    INST_LBU: begin
                        bytelen = B;
                        sign    = '0;
                    end
                    INST_LHU: begin
                        bytelen = H;
                        sign    = '0;
                    end
                    default: ;
                endcase
            end
            INST_TYPE_S: begin
                mem_req    = '1;
                mem_we     = '1;
                mem_addr   = op1_add_op2_res;
                store_data = reg2_rdata;
                case (funct3)
                    INST_SB: bytelen = B;
                    INST_SH: bytelen = H;
                    INST_SW: bytelen = W;
                    default: ;
                endcase
            end
            INST_TYPE_B: begin
                case (funct3)
                    INST_BEQ: begin
                        jump_flag = compare;
                        jump_addr = {32{compare}} & op1_add_op2_res;
                    end
                    INST_BNE: begin
                        jump_flag = ~compare;
                        jump_addr = {32{(~compare)}} & op1_add_op2_res;
                    end
                    INST_BLT: begin
                        jump_flag = ~compare;
                        jump_addr = {32{(~compare)}} & op1_add_op2_res;
                    end
                    INST_BGE: begin
                        jump_flag = compare;
                        jump_addr = {32{(compare)}} & op1_add_op2_res;
                    end
                    INST_BLTU: begin
                        jump_flag = ~compare;
                        jump_addr = {32{(~compare)}} & op1_add_op2_res;
                    end
                    INST_BGEU: begin
                        jump_flag = compare;
                        jump_addr = {32{(compare)}} & op1_add_op2_res;
                    end
                    default: ;
                endcase
            end
            INST_JAL: begin
                jump_flag = '1;
                reg_we    = '1;
                jump_addr = op1_add_op2_res;
                reg_wdata = inst_addr_next_type_i ? inst_addr_i + 32'd2 : inst_addr_i + 32'd4;
            end
            INST_JALR: begin
                jump_flag = '1;
                reg_we    = '1;
                jump_addr = op1_add_op2_res;
                reg_wdata = inst_addr_next_type_i ? inst_addr_i + 32'd2 : inst_addr_i + 32'd4;
            end
            INST_LUI: begin
                reg_we    = '1;
                reg_wdata = op1_add_op2_res;
            end
            INST_AUIPC: begin
                reg_we    = '1;
                reg_wdata = op1_add_op2_res;
            end
            INST_FENCE: begin
                jump_flag = '1;
                jump_addr = inst_addr_next_type_i ? inst_addr_i + 32'd2 : inst_addr_i + 32'd4;
            end
            INST_CSR: begin
                reg_we = '1;
                csr_we = '1;
                case (funct3)
                    INST_CSRRW: begin
                        csr_wdata_o = op1;
                        reg_wdata   = csr_rdata_i;
                    end
                    INST_CSRRS: begin
                        csr_wdata_o = op1 | csr_rdata_i;
                        reg_wdata   = csr_rdata_i;
                    end
                    INST_CSRRC: begin
                        csr_wdata_o = csr_rdata_i & (~op1);
                        reg_wdata   = csr_rdata_i;
                    end
                    INST_CSRRWI: begin
                        csr_wdata_o = {27'h0, uimm};
                        reg_wdata   = csr_rdata_i;
                    end
                    INST_CSRRSI: begin
                        csr_wdata_o = {27'h0, uimm} | csr_rdata_i;
                        reg_wdata   = csr_rdata_i;
                    end
                    INST_CSRRCI: begin
                        csr_wdata_o = (~{27'h0, uimm}) & csr_rdata_i;
                        reg_wdata   = csr_rdata_i;
                    end
                    default: ;
                endcase
            end
            default: ;
        endcase
    end



    div i_div (
        .clk_i,
        .rst_ni,
        .op_i      (funct3),
        .valid_i   (div_valid),
        .dividend_i(op1),
        .divisor_i (op2),
        .result_o  (div_data),
        .ready_o   (div_ready)
    );

    mult i_mult (
        .clk_i,
        .rst_ni,
        .op_i          (funct3),
        .valid_i       (mult_valid),
        .multiplicand_i(op1),
        .multiplier_i  (op2),
        .result_o      (mult_data),
        .ready_o       (mult_ready)
    );

    lsu i_lsu (
        // CPU 内部接口
        .req_valid(mem_req),
        .req_ready(mem_ready),
        .addr     (mem_addr),
        .wdata    (store_data),
        .rdata    (lsu_rdata),
        .bytelen  (bytelen),
        .ls       (mem_we),
        .sign     (sign),
        // APB 接口
        .apb_mst
    );

    prim_endff #(32, '0) u_reg_data (
        .clk_i,
        .rst_ni,
        .en  (reg_we_with_int),
        .din (reg_wdata),
        .qout(reg_wdata_o)
    );

    prim_endff #(1, '0) u_reg_we (
        .clk_i,
        .rst_ni,
        .en  ('1),
        .din (reg_we_with_int),
        .qout(reg_we_o)
    );

    prim_endff #(RegAddrBus, '0) u_reg_waddr (
        .clk_i,
        .rst_ni,
        .en  (reg_we_with_int),
        .din (reg_waddr_i),
        .qout(reg_waddr_o)
    );
endmodule
