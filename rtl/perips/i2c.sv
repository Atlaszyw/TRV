module i2c
    import tinyriscv_pkg::*;
#(
    parameter int unsigned CLK_FREQ = 32'd50_000_000,
    parameter int unsigned SCL_FREQ = 32'd50_000
) (
    input clk_i,
    input rst_ni,

    input [31:0] data_i,
    input [31:0] addr_i,
    input        we_i,

    output logic [31:0] data_o,

    output scl_o,
    output sda_o,
    output sda_t_o,
    input  sda_i
);

    enum logic [4:0] {
        IDLE,
        ADDR_CFGD,
        WRITE_CFGD,
        READ_CFGD,
        WRITE_ADDR,
        REWRITE_ADDR,
        WRITE_BYTE,
        READ_BYTE,
        READ_LAST_BYTE
    }
        CS, NS;


    logic [RegBus - 1:0] reg_addr, reg_read_data, reg_write_data, reg_conf;

    always_ff @(posedge clk_i or negedge rst_ni) begin : reg_addr_ctl
        if (~rst_ni) reg_addr <= '0;
        else if (we_i && addr_i[16 +: 4] == 4'h1) reg_addr <= data_i;
    end
    always_ff @(posedge clk_i or negedge rst_ni) begin : regAfile
        if (~rst_ni) reg_addr <= '0;
        else if (we_i && addr_i[16 +: 4] == 4'h2) reg_write_data <= data_i;
    end
    always_ff @(posedge clk_i or negedge rst_ni) begin : regAfile
        if (~rst_ni) reg_addr <= '0;
        else if (we_i && addr_i[16 +: 4] == 4'h3) reg_read_data <= data_i;
    end
    always_ff @(posedge clk_i or negedge rst_ni) begin : regAfile
        if (~rst_ni) reg_addr <= '0;
        else if (we_i && addr_i[16 +: 4] == 4'h4) reg_conf <= data_i;
    end

    // 内部时钟，计数满时内部时钟翻转一次，scl sda状态的切换基于此时钟进行工作
    localparam int unsigned CNT_MAX = CLK_FREQ / (SCL_FREQ * 8);
    logic [$clog2(CNT_MAX) - 1:0] cnt;
    logic clk_s;

    always_ff @(posedge clk_i or negedge rst_ni) begin : cnt_ctl
        if (~rst_ni | ~|cnt) cnt <= CNT_MAX;
        else if (|cnt) cnt <= cnt - 1'b1;
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin : clk_s_ctl
        if (~rst_ni) clk_s <= '0;
        else if (~|cnt) clk_s <= ~clk_s;
    end


endmodule
