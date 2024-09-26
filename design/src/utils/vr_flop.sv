module vr_flop #(
    parameter int unsigned WIDTH      = 32'd32,
    parameter int unsigned ADDR_WIDTH = 32'd32
) (
    input clk_i,
    input rst_ni,

    input                           m_valid_i,
    input        [     WIDTH - 1:0] m_data_i,
    input        [ADDR_WIDTH - 1:0] m_addr_i,
    output logic [     WIDTH - 1:0] m_data_o,
    output logic                    m_ready_o,
    input                           w_en_i,

    output logic                    s_valid_o,
    output logic [     WIDTH - 1:0] s_data_o,
    output       [ADDR_WIDTH - 1:0] s_addr_o,
    input        [     WIDTH - 1:0] s_data_i,
    input                           s_ready_i,
    output logic                    w_en_o

);
    logic full, w_en;
    logic [WIDTH - 1:0] data;
    logic [ADDR_WIDTH - 1:0] addr;

    logic m_handshake, s_handshake;

    typedef enum logic [1:0] {
        IDLE,
        WRITE,
        READ
    } state_e;

    state_e state;

    // always_ff @(posedge clk_i or negedge rst_ni) begin : state_ctrl
    //     if (~rst_ni) state_e <= IDLE;
    //     else if (~full)
    // end : state_ctrl

    assign m_handshake = m_valid_i & m_ready_o;
    assign s_handshake = s_valid_o & s_ready_i;
    assign s_data_o    = data;
    assign m_data_o    = data;

    assign m_ready_o   = w_en_i ? ~w_full : r_full;
    assign s_valid_o   = w_en_i ? w_full : ~r_full;

    assign w_en_o      = s_valid_o ? w_en : '0;
    assign s_addr_o    = s_valid_o ? addr : '0;

    always_ff @(posedge clk_i) begin : w_en_ctrl
        if (~rst_ni) w_en <= '0;
        else if (m_valid_i) w_en <= w_en_i;
        else w_en <= '0;
    end : w_en_ctrl

    always_ff @(posedge clk_i) begin : addr_ctrl
        if (~rst_ni) addr <= '0;
        else if (m_valid_i) addr <= m_addr_i;
        else addr <= '0;
    end : addr_ctrl

    always_ff @(posedge clk_i) begin : w_full_ctrl
        if (~rst_ni) w_full <= '0;
        else if (w_en_i) begin
            if (m_handshake & s_handshake) w_full <= w_full;
            else if (s_handshake & ~m_handshake) w_full <= '0;
            else if (m_handshake & ~s_handshake) w_full <= '1;
        end
        else w_full <= '0;
    end : w_full_ctrl

    always_ff @(posedge clk_i) begin : r_full_ctrl
        if (~rst_ni) r_full <= '0;
        else if (~w_en_i) begin
            if (m_handshake & s_handshake) r_full <= r_full;
            else if (s_handshake & ~m_handshake) r_full <= '1;
            else if (m_handshake & ~s_handshake) r_full <= '0;
        end
    end : r_full_ctrl


    always_ff @(posedge clk_i) begin : data_ctrl
        if (~rst_ni | ~w_en_i) data <= '0;
        else if (m_handshake & w_en_i) data <= m_data_i;
        else if (s_handshake & ~w_en_i) data <= s_data_i;
    end : data_ctrl


endmodule
