module i2c
    import tinyriscv_pkg::*;
#(
    parameter int unsigned       CLK_FREQ = 32'd50_000_000,
    parameter int unsigned       SCL_FREQ = 32'd100_000,
    parameter logic        [6:0] ADDR_75  = 7'b1001000
) (
    input clk_i,
    input rst_ni,

    input [31:0] data_i,
    input [31:0] addr_i,
    input        we_i,
    input        req_i,

    output logic [31:0] data_o,
    output logic        ready_o,

    output logic scl_o,
    output logic sda_o,
    output logic sda_t_o,
    input        sda_i
);

    typedef enum logic [4:0] {
        IDLE,
        START,
        WADDR,
        RDACK,
        RDNACK,
        STOP,
        DATAOUT
    } i2c_state_e;
    i2c_state_e i2c_s_q, i2c_s_d;
    // 内部时钟，计数满时内部时钟翻转一次，scl sda状态的切换基于此时钟进行工作
    localparam int unsigned CNT_MAX = CLK_FREQ / (SCL_FREQ * 4) - 1;
    logic [$clog2(CNT_MAX) - 1:0] cnt;
    logic [2:0] clk_s_cnt;
    logic [2:0] clk_s_rst;
    logic [7:0] waddr;
    logic [3:0] bit_cnt;
    logic phase_cnt_done;
    logic clk_s;
    logic cnt_done;
    logic [7:0] tempreture_buffer;


    logic [RegBus - 1:0] reg_addr, reg_read_data, reg_write_data, reg_status;

    // -----------------------------------reg----------------------------------


    always_ff @(posedge clk_i) begin : reg_addr_ctl
        if (~rst_ni) reg_addr <= {1'b0, ADDR_75};
        else if (req_i && we_i && addr_i[16 +: 4] == 4'h1) reg_addr <= data_i;
    end : reg_addr_ctl

    assign waddr = {reg_addr[6:0], 1'b1};

    always_ff @(posedge clk_i) begin : reg_write_ctl
        if (~rst_ni) reg_write_data <= '0;
        else if (req_i && we_i && addr_i[16 +: 4] == 4'h2) reg_write_data <= data_i;
    end : reg_write_ctl

    always_ff @(posedge clk_i) begin : reg_read_ctl
        if (~rst_ni) reg_read_data <= '0;
        else if (i2c_s_q == STOP && i2c_s_d == DATAOUT) reg_read_data <= tempreture_buffer;
    end : reg_read_ctl

    always_comb begin : ready_o_ctrl
        ready_o = '1;

        if (i2c_s_q == IDLE && i2c_s_d == START || i2c_s_q != IDLE && i2c_s_q != DATAOUT) ready_o = '0;
    end : ready_o_ctrl

    always_comb begin : read_reg_out
        data_o = '0;
        if (req_i && ~we_i)
            case (addr_i[16 +: 4])
                4'h1: data_o = reg_addr;
                4'h2: data_o = reg_read_data;
                4'h3: data_o = reg_write_data;
            endcase
    end : read_reg_out

    // ------------------------------fsm------------------------------------
    always_ff @(posedge clk_i) begin : i2c_d2q
        if (~rst_ni) i2c_s_q <= IDLE;
        else i2c_s_q <= i2c_s_d;
    end : i2c_d2q

    always_comb begin : i2c_ns
        i2c_s_d = i2c_s_q;
        case (i2c_s_q)
            IDLE:    if (req_i && ~we_i && addr_i[16 +: 4] == 4'h2) i2c_s_d = START;
            START:   if (~|clk_s_cnt && cnt_done) i2c_s_d = WADDR;
            WADDR:   if (~|bit_cnt && ~|clk_s_cnt && cnt_done) i2c_s_d = RDACK;
            RDACK:   if (~|bit_cnt && ~|clk_s_cnt && cnt_done) i2c_s_d = RDNACK;
            RDNACK:  if (~|bit_cnt && ~|clk_s_cnt && cnt_done) i2c_s_d = STOP;
            STOP:    if (~|clk_s_cnt && cnt_done) i2c_s_d = DATAOUT;
            DATAOUT: i2c_s_d = IDLE;
        endcase
    end : i2c_ns

    // --------------------------------cnt-------------------------------------
    always_ff @(posedge clk_i) begin : cnt_ctrl
        if (~rst_ni) cnt <= CNT_MAX;
        else if (i2c_s_q != IDLE) begin
            if (|cnt) cnt <= cnt - 1;
            else cnt <= CNT_MAX;
        end
    end : cnt_ctrl
    assign cnt_done       = ~|cnt;
    assign phase_cnt_done = cnt_done & ~|clk_s_cnt;

    always_comb begin : clk_s_rst_ctrl
        case (i2c_s_d)
            IDLE:    clk_s_rst = 3'd3;
            START:   clk_s_rst = 3'd1;
            WADDR:   clk_s_rst = 3'd3;
            RDACK:   clk_s_rst = 3'd3;
            RDNACK:  clk_s_rst = 3'd3;
            STOP:    clk_s_rst = 3'd1;
            default: clk_s_rst = 3'd3;
        endcase
    end : clk_s_rst_ctrl

    always_ff @(posedge clk_i) begin : clk_s_cnt_ctrl
        if (~rst_ni) clk_s_cnt <= 3'd1;
        else if (i2c_s_d != i2c_s_q)  // 状态切换
            clk_s_cnt <= clk_s_rst;
        else if (cnt_done) begin
            if (|clk_s_cnt) clk_s_cnt <= clk_s_cnt - 1'b1;
            else clk_s_cnt <= clk_s_rst;
        end
    end : clk_s_cnt_ctrl


    always_ff @(posedge clk_i) begin : sda_scl_ctrl
        if (~rst_ni) begin
            sda_o   <= '1;
            sda_t_o <= '0;
            scl_o   <= '1;
        end
        else
            case (i2c_s_q)
                IDLE: begin
                    sda_o   <= '1;
                    sda_t_o <= '0;
                    scl_o   <= '1;
                end
                START: begin
                    sda_o   <= '0;
                    sda_t_o <= '1;
                    scl_o   <= clk_s_cnt;
                end
                WADDR: begin
                    scl_o <= ^clk_s_cnt;  // 1 2计数时输出高电平
                    if (bit_cnt) begin
                        sda_o   <= waddr[bit_cnt - 1];
                        sda_t_o <= '1;
                    end
                    else begin
                        sda_o   <= '1;
                        sda_t_o <= '0;
                    end
                end
                RDACK: begin
                    scl_o <= ^clk_s_cnt;  // 1 2计数时输出高电平
                    if (bit_cnt) begin
                        sda_o   <= '1;
                        sda_t_o <= '0;
                    end
                    else begin
                        sda_o   <= '0;
                        sda_t_o <= '1;
                    end
                end
                RDNACK: begin
                    scl_o <= ^clk_s_cnt;  // 1 2计数时输出高电平
                    if (bit_cnt) begin
                        sda_o   <= '1;
                        sda_t_o <= '0;
                    end
                    else begin
                        sda_o   <= '1;
                        sda_t_o <= '1;
                    end
                end
                STOP: begin
                    scl_o   <= ~^clk_s_cnt;
                    sda_o   <= '0;
                    sda_t_o <= '1;
                end
                // default:
            endcase
    end : sda_scl_ctrl


    always_ff @(posedge clk_i) begin : bit_cnt_ctrl
        if (~rst_ni) bit_cnt <= 4'd8;
        else
            case (i2c_s_q)
                START: begin
                    if (i2c_s_d == WADDR) bit_cnt <= 4'd8;
                    else bit_cnt <= bit_cnt;
                end
                WADDR: begin
                    if (i2c_s_d == RDACK) bit_cnt <= 4'd8;
                    else if (phase_cnt_done) bit_cnt <= bit_cnt - 1;
                    else bit_cnt <= bit_cnt;
                end
                RDACK: begin
                    if (i2c_s_d == RDNACK) bit_cnt <= 4'd8;
                    else if (phase_cnt_done) bit_cnt <= bit_cnt - 1;
                    else bit_cnt <= bit_cnt;
                end
                RDNACK: begin
                    if (phase_cnt_done) bit_cnt <= bit_cnt - 1;
                    else bit_cnt <= bit_cnt;
                end
                default: bit_cnt <= bit_cnt;
            endcase
    end : bit_cnt_ctrl

    always_ff @(posedge clk_i) begin : temp_buffer_ctrl
        if (~rst_ni) tempreture_buffer <= '0;
        else if (i2c_s_q == RDACK) begin
            if (bit_cnt < 8 && bit_cnt > 0 && ^clk_s_cnt) tempreture_buffer[bit_cnt] <= sda_i;
        end
        else if (i2c_s_q == RDNACK) begin
            if (bit_cnt == 8 && ^clk_s_cnt) tempreture_buffer[0] <= sda_i;
        end
    end : temp_buffer_ctrl

endmodule
