package tinyriscv_pkg;
    localparam int unsigned CpuResetAddr = 32'h0;

    localparam bit RstEnable = 1'b0;
    localparam bit WriteEnable = 1'b1;
    localparam bit ReadEnable = 1'b1;
    localparam bit True = 1'b1;
    localparam bit False = 1'b0;
    localparam bit ChipEnable = 1'b1;
    localparam bit JumpEnable = 1'b1;
    localparam bit DivResultReady = 1'b1;
    localparam bit DivStart = 1'b1;
    localparam bit DivStop = 1'b0;
    localparam bit HoldEnable = 1'b1;
    localparam bit HoldDisable = 1'b0;
    localparam bit Stop = 1'b1;
    localparam bit NoStop = 1'b0;
    localparam bit RIB_ACK = 1'b1;
    localparam bit RIB_NACK = 1'b0;
    localparam bit RIB_REQ = 1'b1;
    localparam bit RIB_NREQ = 1'b0;
    localparam bit INT_ASSERT = 1'b1;
    localparam bit INT_DEASSERT = 1'b0;

    localparam int unsigned INT_BUS = 8;
    localparam int unsigned INT_NONE = 8'h0;
    localparam int unsigned INT_RET = 8'hff;
    localparam int unsigned INT_TIMER0 = 8'b00000001;
    localparam int unsigned INT_TIMER0_ENTRY_ADDR = 32'h4;

    localparam int unsigned Hold_Flag_Bus = 3;
    localparam int unsigned Hold_None = 3'b000;
    localparam int unsigned Hold_Pc = 3'b001;
    localparam int unsigned Hold_If = 3'b010;
    localparam int unsigned Hold_Id = 3'b100;

    // I type inst
    localparam int unsigned INST_TYPE_I = 7'b0010011;
    localparam int unsigned INST_ADDI = 3'b000;
    localparam int unsigned INST_SLTI = 3'b010;
    localparam int unsigned INST_SLTIU = 3'b011;
    localparam int unsigned INST_XORI = 3'b100;
    localparam int unsigned INST_ORI = 3'b110;
    localparam int unsigned INST_ANDI = 3'b111;
    localparam int unsigned INST_SLLI = 3'b001;
    localparam int unsigned INST_SRI = 3'b101;

    // L type inst
    localparam int unsigned INST_TYPE_L = 7'b0000011;
    localparam int unsigned INST_LB = 3'b000;
    localparam int unsigned INST_LH = 3'b001;
    localparam int unsigned INST_LW = 3'b010;
    localparam int unsigned INST_LBU = 3'b100;
    localparam int unsigned INST_LHU = 3'b101;

    // S type inst
    localparam int unsigned INST_TYPE_S = 7'b0100011;
    localparam int unsigned INST_SB = 3'b000;
    localparam int unsigned INST_SH = 3'b001;
    localparam int unsigned INST_SW = 3'b010;

    // R and M type inst
    localparam int unsigned INST_TYPE_R_M = 7'b0110011;
    // R type inst
    localparam int unsigned INST_ADD_SUB = 3'b000;
    localparam int unsigned INST_SLL = 3'b001;
    localparam int unsigned INST_SLT = 3'b010;
    localparam int unsigned INST_SLTU = 3'b011;
    localparam int unsigned INST_XOR = 3'b100;
    localparam int unsigned INST_SR = 3'b101;
    localparam int unsigned INST_OR = 3'b110;
    localparam int unsigned INST_AND = 3'b111;
    // M type inst
    localparam int unsigned INST_MUL = 3'b000;
    localparam int unsigned INST_MULH = 3'b001;
    localparam int unsigned INST_MULHSU = 3'b010;
    localparam int unsigned INST_MULHU = 3'b011;
    localparam int unsigned INST_DIV = 3'b100;
    localparam int unsigned INST_DIVU = 3'b101;
    localparam int unsigned INST_REM = 3'b110;
    localparam int unsigned INST_REMU = 3'b111;

    // J type inst
    localparam int unsigned INST_JAL = 7'b1101111;
    localparam int unsigned INST_JALR = 7'b1100111;

    localparam int unsigned INST_LUI = 7'b0110111;
    localparam int unsigned INST_AUIPC = 7'b0010111;
    localparam int unsigned INST_NOP = 32'h00000001;
    localparam int unsigned INST_NOP_OP = 7'b0000001;
    localparam int unsigned INST_MRET = 32'h30200073;
    localparam int unsigned INST_RET = 32'h00008067;

    localparam int unsigned INST_FENCE = 7'b0001111;
    localparam int unsigned INST_ECALL = 32'h73;
    localparam int unsigned INST_EBREAK = 32'h00100073;

    // J type inst
    localparam int unsigned INST_TYPE_B = 7'b1100011;
    localparam int unsigned INST_BEQ = 3'b000;
    localparam int unsigned INST_BNE = 3'b001;
    localparam int unsigned INST_BLT = 3'b100;
    localparam int unsigned INST_BGE = 3'b101;
    localparam int unsigned INST_BLTU = 3'b110;
    localparam int unsigned INST_BGEU = 3'b111;

    // CSR inst
    localparam int unsigned INST_CSR = 7'b1110011;
    localparam int unsigned INST_CSRRW = 3'b001;
    localparam int unsigned INST_CSRRS = 3'b010;
    localparam int unsigned INST_CSRRC = 3'b011;
    localparam int unsigned INST_CSRRWI = 3'b101;
    localparam int unsigned INST_CSRRSI = 3'b110;
    localparam int unsigned INST_CSRRCI = 3'b111;

    // CSR logic addr
    localparam int unsigned CSR_CYCLE = 12'hc00;
    localparam int unsigned CSR_CYCLEH = 12'hc80;
    localparam int unsigned CSR_MTVEC = 12'h305;
    localparam int unsigned CSR_MCAUSE = 12'h342;
    localparam int unsigned CSR_MEPC = 12'h341;
    localparam int unsigned CSR_MIE = 12'h304;
    localparam int unsigned CSR_MSTATUS = 12'h300;
    localparam int unsigned CSR_MSCRATCH = 12'h340;

    localparam int unsigned RomNum = 256;  // rom depth(how many words)

    localparam int unsigned MemNum = 16;  // memory depth(how many words)
    localparam int unsigned MemBus = 32;
    localparam int unsigned MemAddrBus = 32;

    localparam int unsigned InstBus = 32;
    localparam int unsigned InstAddrBus = 32;

    // common regs
    localparam int unsigned RegAddrBus = 5;
    localparam int unsigned RegBus = 32;
    localparam int unsigned DoubleRegBus = 64;
    localparam int unsigned RegWidth = 32;
    localparam int unsigned RegNum = 32;  // logic num
    localparam int unsigned RegNumLog2 = 5;

endpackage
