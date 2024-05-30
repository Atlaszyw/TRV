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

// tinyriscv soc顶层模块
module tinyriscv_soc_top
    import tinyriscv_pkg::*;
#(
    parameter int unsigned GPIO_NUM = 16
) (

    input clk_i,
    input rst_ni,

    input uart_debug_pin,  // 串口下载使能引脚

    output logic                  uart_tx_pin,  // UART发送引脚
    input                         uart_rx_pin,  // UART接收引脚
    inout        [GPIO_NUM - 1:0] gpio_out,     // GPIO引脚

    // input        jtag_TCK,  // JTAG TCK引脚
    // input        jtag_TMS,  // JTAG TMS引脚
    // input        jtag_TDI,  // JTAG TDI引脚
    // output logic jtag_TDO,  // JTAG TDO引脚

    // input        spi_miso,  // SPI MISO引脚
    // output logic spi_mosi,  // SPI MOSI引脚
    // output logic spi_ss,    // SPI SS引脚
    // output logic spi_clk,   // SPI CLK引脚

    // output logic over,  // 测试是否完成信号
    // output logic succ,  // 测试是否成功信号

    output logic [2:0] pwm_o,

    output logic scl_o,
    inout        sda_io
);

    logic                      jtag_TCK;  // JTAG TCK引脚
    logic                      jtag_TMS;  // JTAG TMS引脚
    logic                      jtag_TDI;  // JTAG TDI引脚
    logic                      jtag_TDO;  // JTAG TDO引脚

    logic                      spi_miso;  // SPI MISO引脚
    logic                      spi_mosi;  // SPI MOSI引脚
    logic                      spi_ss;  // SPI SS引脚
    logic                      spi_clk;  // SPI CLK引脚

    logic                      over;  // 测试是否完成信号
    logic                      succ;  // 测试是否成功信号

    logic                      halted_ind;  // jtag是否已经halt住CPU信号

    // master 0 interface
    logic [  MemAddrBus - 1:0] m0_addr;
    logic [      MemBus - 1:0] m0_data_i;
    logic [      MemBus - 1:0] m0_data_o;
    logic                      m0_req;
    logic                      m0_we;
    logic                      m0_ready;

    // master 1 interface
    logic [  MemAddrBus - 1:0] m1_addr;
    logic [      MemBus - 1:0] m1_data_i;
    logic [      MemBus - 1:0] m1_data;
    logic                      m1_we;
    logic                      m1_ready;

    // master 2 interface
    logic [  MemAddrBus - 1:0] m2_addr;
    logic [      MemBus - 1:0] m2_data_i;
    logic [      MemBus - 1:0] m2_data_o;
    logic                      m2_req;
    logic                      m2_we;

    // master 3 interface
    logic [  MemAddrBus - 1:0] m3_addr;
    logic [      MemBus - 1:0] m3_data_i;
    logic [      MemBus - 1:0] m3_data_o;
    logic                      m3_req;
    logic                      m3_we;

    // slave 0 interface
    logic [  MemAddrBus - 1:0] s0_addr;
    logic [      MemBus - 1:0] s0_data_o;
    logic [      MemBus - 1:0] s0_data_i;
    logic                      s0_we;

    // slave 1 interface
    logic [  MemAddrBus - 1:0] s1_addr;
    logic [      MemBus - 1:0] s1_data_o;
    logic [      MemBus - 1:0] s1_data_i;
    logic                      s1_we;

    // slave 2 interface
    logic [  MemAddrBus - 1:0] s2_addr;
    logic [      MemBus - 1:0] s2_data_o;
    logic [      MemBus - 1:0] s2_data_i;
    logic                      s2_we;

    // slave 3 interface
    logic [  MemAddrBus - 1:0] s3_addr;
    logic [      MemBus - 1:0] s3_data_o;
    logic [      MemBus - 1:0] s3_data_i;
    logic                      s3_we;
    logic                      s3_ready;
    logic                      s3_req;

    // slave 4 interface
    logic [  MemAddrBus - 1:0] s4_addr;
    logic [      MemBus - 1:0] s4_data_o;
    logic [      MemBus - 1:0] s4_data_i;
    logic                      s4_we;

    // slave 5 interface
    logic [  MemAddrBus - 1:0] s5_addr;
    logic [      MemBus - 1:0] s5_data_o;
    logic [      MemBus - 1:0] s5_data_i;
    logic                      s5_we;

    logic [  MemAddrBus - 1:0] s6_addr;
    logic [      MemBus - 1:0] s6_data_o;
    logic [      MemBus - 1:0] s6_data_i;
    logic                      s6_we;
    logic                      s6_req;

    logic [  MemAddrBus - 1:0] s7_addr;
    logic [      MemBus - 1:0] s7_data_o;
    logic [      MemBus - 1:0] s7_data_i;
    logic                      s7_we;
    logic                      s7_ready;
    logic                      s7_req;

    // rib
    logic                      hold_flag_rib;

    // jtag
    logic                      jtag_halt_req_o;
    logic                      jtag_reset_req_o;
    logic [  RegAddrBus - 1:0] jtag_reg_addr_o;
    logic [      RegBus - 1:0] jtag_reg_data_o;
    logic                      jtag_reg_we_o;
    logic [      RegBus - 1:0] jtag_reg_data_i;

    // tinyriscv
    logic [     INT_BUS - 1:0] int_flag;

    // timer0
    logic                      timer0_int;

    // gpio
    logic [    GPIO_NUM - 1:0] io_in;
    logic [GPIO_NUM * 2 - 1:0] gpio_ctrl;
    logic [    GPIO_NUM - 1:0] gpio_data;

    assign int_flag   = {7'h0, timer0_int};

    // 低电平点亮LED
    // 低电平表示已经halt住CPU
    assign halted_ind = ~jtag_halt_req_o;

    logic sda_i, sda_o, sda_t;
    assign sda_io = sda_t ? sda_o : 'z;
    assign sda_i  = sda_io;

    // always_ff @(posedge clk_i) begin
    //     if (rst_ni == RstEnable) begin
    //         over <= 1'b1;
    //         succ <= 1'b1;
    //     end
    //     else begin
    //         over <= ~u_tinyriscv.u_regs.regs[26];  // when = 1, run over
    //         succ <= ~u_tinyriscv.u_regs.regs[27];  // when = 1, run succ, otherwise fail
    //     end
    // end

    // tinyriscv处理器核模块例化
    tinyriscv u_tinyriscv (
        .clk_i         (clk_i),
        .rst_ni        (rst_ni & ~uart_debug_pin),
        .rib_ex_addr_o (m0_addr),
        .rib_ex_data_i (m0_data_o),
        .rib_ex_data_o (m0_data_i),
        .rib_ex_req_o  (m0_req),
        .rib_ex_we_o   (m0_we),
        .rib_ex_ready_i(m0_ready),

        .rib_pc_addr_o (m1_addr),
        .rib_pc_data_i (m1_data),
        .rib_pc_ready_i(m1_ready),

        .jtag_reg_addr_i(jtag_reg_addr_o),
        .jtag_reg_data_i(jtag_reg_data_o),
        .jtag_reg_we_i  (jtag_reg_we_o),
        .jtag_reg_data_o(jtag_reg_data_i),

        .rib_hold_flag_i  (hold_flag_rib),
        .jtag_halt_flag_i (jtag_halt_req_o),
        .jtag_reset_flag_i(jtag_reset_req_o),

        .int_i(int_flag)
    );

    // 串口下载模块例化
    uart_debug u_uart_debug (
        .clk_i      (clk_i),
        .rst_ni     (rst_ni),
        .debug_en_i (uart_debug_pin),
        .req_o      (m3_req),
        .mem_we_o   (m3_we),
        .mem_addr_o (m3_addr),
        .mem_wdata_o(m3_data_i),
        .mem_rdata_i(m3_data_o)
    );

    // rom模块例化
    rom u_rom (
        .clk_i (clk_i),
        .rst_ni(rst_ni),
        .we_i  (s0_we),
        .addr_i(s0_addr),
        .data_i(s0_data_o),
        .data_o(s0_data_i)
    );

    // ram模块例化
    ram u_ram (
        .clk_i (clk_i),
        .rst_ni(rst_ni),
        .we_i  (s1_we),
        .addr_i(s1_addr),
        .data_i(s1_data_o),
        .data_o(s1_data_i)
    );

    // timer模块例化
    timer timer_0 (
        .clk_i    (clk_i),
        .rst_ni   (rst_ni),
        .data_i   (s2_data_o),
        .addr_i   (s2_addr),
        .we_i     (s2_we),
        .data_o   (s2_data_i),
        .int_sig_o(timer0_int)
    );

    // uart模块例化
    uart uart_0 (
        .clk_i  (clk_i),
        .rst_ni (rst_ni),
        .we_i   (s3_we),
        .addr_i (s3_addr),
        .data_i (s3_data_o),
        .req_i  (s3_req),
        .ready_o(s3_ready),
        .data_o (s3_data_i),
        .tx_pin (uart_tx_pin),
        .rx_pin (uart_rx_pin)
    );

    i2c i_i2c (
        .clk_i  (clk_i),
        .rst_ni (rst_ni),
        .we_i   (s7_we),
        .req_i  (s7_req),
        .addr_i (s7_addr),
        .data_i (s7_data_o),
        .data_o (s7_data_i),
        .ready_o(s7_ready),
        .scl_o  (scl_o),
        .sda_i  (sda_i),
        .sda_o  (sda_o),
        .sda_t_o(sda_t)

    );


    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin
            // io_i
            assign gpio_out[i] = (gpio_ctrl[2*i +: 2] == 2'b01) ? gpio_data[i] : 1'bz;
            assign io_in[i]    = gpio_out[i];
        end
    endgenerate

    // gpio模块例化
    gpio gpio_0 (
        .clk_i   (clk_i),
        .rst_ni  (rst_ni),
        .we_i    (s4_we),
        .addr_i  (s4_addr),
        .data_i  (s4_data_o),
        .data_o  (s4_data_i),
        .io_pin_i(io_in),
        .reg_ctrl(gpio_ctrl),
        .io_pin_o(gpio_data)
    );

    // spi模块例化
    spi spi_0 (
        .clk_i,
        .rst_ni,
        .data_i  (s5_data_o),
        .addr_i  (s5_addr),
        .we_i    (s5_we),
        .data_o  (s5_data_i),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_ss  (spi_ss),
        .spi_clk (spi_clk)
    );

    pwm #(
        .channel(3)
    ) u_pwm (
        .clk_i,
        .rst_ni,

        .data_i(s6_data_o),
        .addr_i(s6_addr),
        .we_i  (s6_we),
        .data_o(s6_data_i),

        .pwm_o
    );

    // rib模块例化
    rib u_rib (
        // master 0 interface
        .m0_addr_i (m0_addr),
        .m0_data_i (m0_data_i),
        .m0_data_o (m0_data_o),
        .m0_req_i  (m0_req),
        .m0_we_i   (m0_we),
        .m0_ready_o(m0_ready),

        // master 1 interface
        .m1_addr_i (m1_addr),
        .m1_data_i ('0),
        .m1_data_o (m1_data),
        .m1_req_i  (RIB_REQ),
        .m1_we_i   (~WriteEnable),
        .m1_ready_o(m1_ready),

        // master 2 interface
        .m2_addr_i(m2_addr),
        .m2_data_i(m2_data_i),
        .m2_data_o(m2_data_o),
        .m2_req_i (m2_req),
        .m2_we_i  (m2_we),

        // master 3 interface
        .m3_addr_i(m3_addr),
        .m3_data_i(m3_data_i),
        .m3_data_o(m3_data_o),
        .m3_req_i (m3_req),
        .m3_we_i  (m3_we),

        // slave 0 interface
        .s0_addr_o(s0_addr),
        .s0_data_o(s0_data_o),
        .s0_data_i(s0_data_i),
        .s0_we_o  (s0_we),

        // slave 1 interface
        .s1_addr_o(s1_addr),
        .s1_data_o(s1_data_o),
        .s1_data_i(s1_data_i),
        .s1_we_o  (s1_we),

        // slave 2 interface
        .s2_addr_o(s2_addr),
        .s2_data_o(s2_data_o),
        .s2_data_i(s2_data_i),
        .s2_we_o  (s2_we),

        // slave 3 interface
        .s3_addr_o (s3_addr),
        .s3_data_o (s3_data_o),
        .s3_data_i (s3_data_i),
        .s3_we_o   (s3_we),
        .s3_req_o  (s3_req),
        .s3_ready_i(s3_ready),

        // slave 4 interface
        .s4_addr_o(s4_addr),
        .s4_data_o(s4_data_o),
        .s4_data_i(s4_data_i),
        .s4_we_o  (s4_we),

        // slave 5 interface
        .s5_addr_o(s5_addr),
        .s5_data_o(s5_data_o),
        .s5_data_i(s5_data_i),
        .s5_we_o  (s5_we),

        .s6_addr_o (s6_addr),
        .s6_data_o (s6_data_o),
        .s6_data_i (s6_data_i),
        .s6_we_o   (s6_we),
        .s6_req_o  (s6_req),
        .s6_ready_i('1),

        .s7_addr_o (s7_addr),
        .s7_data_o (s7_data_o),
        .s7_data_i (s7_data_i),
        .s7_we_o   (s7_we),
        .s7_req_o  (s7_req),
        .s7_ready_i(s7_ready),

        .hold_flag_o(hold_flag_rib)
    );



    // jtag模块例化
    jtag_top #(
        .DMI_ADDR_BITS(6),
        .DMI_DATA_BITS(32),
        .DMI_OP_BITS  (2)
    ) u_jtag_top (
        .clk_i       (clk_i),
        .jtag_rst_n  (rst_ni),
        .jtag_pin_TCK(jtag_TCK),
        .jtag_pin_TMS(jtag_TMS),
        .jtag_pin_TDI(jtag_TDI),
        .jtag_pin_TDO(jtag_TDO),
        .reg_we_o    (jtag_reg_we_o),
        .reg_addr_o  (jtag_reg_addr_o),
        .reg_wdata_o (jtag_reg_data_o),
        .reg_rdata_i (jtag_reg_data_i),
        .mem_we_o    (m2_we),
        .mem_addr_o  (m2_addr),
        .mem_wdata_o (m2_data_i),
        .mem_rdata_i (m2_data_o),
        .op_req_o    (m2_req),
        .halt_req_o  (jtag_halt_req_o),
        .reset_req_o (jtag_reset_req_o)
    );

endmodule
