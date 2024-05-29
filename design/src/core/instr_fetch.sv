module instr_fetch
    import tinyriscv_pkg::*;
(
    input clk_i,
    input rst_ni,

    input instr_ready_i,

    output logic instr_valid_o,  // to if-id
    input        instr_req_i,    // from if-id

    input                           jump_flag_i,
    input logic [InstAddrBus - 1:0] jump_addr_i,
    input                           jtag_reset_flag_i,

    input logic [InstBus - 1:0] instr_i,

    output logic [InstBus - 1:0] instr_o,

    output logic [InstAddrBus - 1:0] pc_o,      // PC指针
    output logic [InstAddrBus - 1:0] pc_real,
    output logic [InstAddrBus - 1:0] pc_next_o
);
    logic handshake;

    logic low_compressed, high_compressed;
    logic [31:0] cdecoder_i;
    logic [15:0] instr_buffer;

    typedef enum logic [2:0] {
        ALIGNED            = 3'b000,
        INIT_UNALIGNED     = 3'b010,
        UNALIGNED,
        UNALIGNED_CONTINUE
    } if_state_e;
    if_state_e if_s_q, if_s_d;

    assign instr_valid_o = instr_ready_i && ~(if_s_q == INIT_UNALIGNED && if_s_d == UNALIGNED_CONTINUE);
    assign handshake     = instr_req_i & instr_valid_o;

    always_ff @(posedge clk_i) begin : state_d2q
        if (~rst_ni) if_s_q <= ALIGNED;
        else if_s_q <= if_s_d;
    end : state_d2q

    always_comb begin : state_next
        if_s_d = if_s_q;

        if (jump_flag_i) begin
            if (jump_addr_i[1:0] == ALIGNED) if_s_d = ALIGNED;
            else if (jump_addr_i[1:0] == INIT_UNALIGNED) if_s_d = INIT_UNALIGNED;
        end
        else if (instr_ready_i)
            unique case (if_s_q)
                ALIGNED: begin
                    if (low_compressed && high_compressed) if_s_d = UNALIGNED;
                    else if (low_compressed && ~high_compressed) if_s_d = UNALIGNED_CONTINUE;
                    else if_s_d = ALIGNED;
                end
                INIT_UNALIGNED: begin
                    if (high_compressed) if_s_d = ALIGNED;
                    else if (~high_compressed) if_s_d = UNALIGNED_CONTINUE;
                end
                UNALIGNED: begin
                    if_s_d = ALIGNED;
                end
                UNALIGNED_CONTINUE: begin
                    if (high_compressed) if_s_d = UNALIGNED;
                    else if_s_d = UNALIGNED_CONTINUE;
                end
            endcase
    end : state_next

    always_comb begin : compressed_judge
        if (instr_ready_i) begin
            low_compressed  = ~&instr_i[1:0];
            high_compressed = ~&instr_i[17:16];
        end
        else begin
            high_compressed = '0;
            low_compressed  = '0;
        end

    end : compressed_judge

    always_comb begin : pc_next_ctrl
        if (cdecoder_i[1:0] != 2'b11) pc_next_o = pc_real + 2;
        else pc_next_o = pc_real + 4;
    end : pc_next_ctrl

    always_ff @(posedge clk_i) begin : pc_real_ctrl
        if (~rst_ni || jtag_reset_flag_i) pc_real <= '0;  // 复位
        else if (jump_flag_i) pc_real <= jump_addr_i;  // 跳转
        else if (handshake) pc_real <= pc_next_o;  // 地址加
        else pc_real <= pc_real;  // 暂停
    end : pc_real_ctrl

    always_ff @(posedge clk_i) begin : pc_o_ctrl
        if (~rst_ni) pc_o <= '0;
        else if (jump_flag_i) pc_o <= {jump_addr_i[31:2], 2'b00};
        else if (handshake) begin
            if (if_s_q == ALIGNED && if_s_d == UNALIGNED) pc_o <= pc_o;
            else if (if_s_q == UNALIGNED_CONTINUE && if_s_d == UNALIGNED) pc_o <= pc_o;
            else pc_o <= pc_o + 4;
        end
        else if (~handshake) begin
            if (if_s_q == INIT_UNALIGNED && if_s_d == UNALIGNED_CONTINUE && instr_ready_i) pc_o <= pc_o + 4;
        end
    end : pc_o_ctrl

    always_ff @(posedge clk_i) begin : instr_buffer_ctrl
        if (~rst_ni || jtag_reset_flag_i) instr_buffer <= 16'd1;
        else if (instr_ready_i && if_s_q == INIT_UNALIGNED && if_s_d == UNALIGNED_CONTINUE) instr_buffer <= instr_i[31:16];
        else if (instr_ready_i && if_s_q == UNALIGNED_CONTINUE && if_s_d == UNALIGNED_CONTINUE && handshake)
            instr_buffer <= instr_i[31:16];
        else if (instr_ready_i && if_s_q == ALIGNED && if_s_d == UNALIGNED_CONTINUE && handshake)
            instr_buffer <= instr_i[31:16];
    end : instr_buffer_ctrl

    always_comb begin : cdecoder_i_ctrl
        if (if_s_q == ALIGNED) cdecoder_i = instr_i;
        else if (if_s_q == INIT_UNALIGNED) cdecoder_i = {16'b0, instr_i[31:16]};
        else if (if_s_q == UNALIGNED_CONTINUE) cdecoder_i = {instr_i[15:0], instr_buffer};
        else if (if_s_q == UNALIGNED) cdecoder_i = {16'b0, instr_i[31:16]};
        else cdecoder_i = INST_NOP;
    end : cdecoder_i_ctrl

    compressed_decoder cdecoder (
        .clk_i,
        .rst_ni,
        .valid_i        (),
        .instr_i        (cdecoder_i),
        .instr_o        (instr_o),
        .illegal_instr_o()
    );
endmodule
