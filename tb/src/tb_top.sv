/** @file       tb_top.svh
* @details
* @author       ColinLv
* @email        colinlv@pb.com
* @version      1.0
* @date         2022-2-12
* @copyright    Copyright (c) 2021-2022, PB Tech. Co., Ltd.
**********************************************************************************
* @attention
*
* @par History
* <table>
* <tr><th>Date        <th>Version  <th>Author    <th>Description
* <tr><td>2022-2-12  <td>1.0      <td>ColinLv  <td>Initial
* </table>
*
*/
module tb_top ();
    import SimSrcGen_pkg::*;

    //-----------------------------------------------------//
    // Signal
    //-----------------------------------------------------//
    logic clk_i;
    logic rst_ni;

    wire over;
    wire succ;
    wire halted_ind;
    wire uart_debug_pin;
    wire uart_tx_pin;
    wire uart_rx_pin;
    wire [1:0] gpio;
    wire jtag_TCK;
    wire jtag_TMS;
    wire jtag_TDI;
    wire jtag_TDO;

    wire spi_miso;
    wire spi_mosi;
    wire spi_ss;
    wire spi_clk;

    reg gpiodriver;
    initial begin
        GenClk(clk_i, 20, 20);
    end

    initial begin
        GenRst(clk_i, rst_ni, 5, 3);
    end

    initial begin
        #0 gpiodriver = '0;
        #5000;
        #1000 gpiodriver = ~gpiodriver;
        #1000 gpiodriver = ~gpiodriver;
        #1000 gpiodriver = ~gpiodriver;
        #1000 gpiodriver = ~gpiodriver;
        #1000 gpiodriver = ~gpiodriver;
        #1000 gpiodriver = ~gpiodriver;
        #1000 gpiodriver = ~gpiodriver;
        #1000 gpiodriver = ~gpiodriver;
        #1000 gpiodriver = ~gpiodriver;
        #1000 gpiodriver = ~gpiodriver;
        #1000 gpiodriver = ~gpiodriver;
        #1000 gpiodriver = ~gpiodriver;
        $finish();
    end
    assign gpio[1] = gpiodriver;
    assign uart_debug_pin = '1;
    tinyriscv_soc_top i_tinyriscv_soc_top (

        .clk_i (clk_i),
        .rst_ni(rst_ni),

        .over(over),  // 测试是否完成信号
        .succ(succ),  // 测试是否成功信号

        .halted_ind(halted_ind),  // jtag是否已经halt住CPU信号

        .uart_debug_pin(uart_debug_pin),  // 串口下载使能引脚

        .uart_tx_pin(uart_tx_pin),  // UART发送引脚
        .uart_rx_pin(uart_rx_pin),  // UART接收引脚
        .gpio       (gpio),         // GPIO引脚

        .jtag_TCK(jtag_TCK),  // JTAG TCK引脚
        .jtag_TMS(jtag_TMS),  // JTAG TMS引脚
        .jtag_TDI(jtag_TDI),  // JTAG TDI引脚
        .jtag_TDO(jtag_TDO),  // JTAG TDO引脚

        .spi_miso(spi_miso),  // SPI MISO引脚
        .spi_mosi(spi_mosi),  // SPI MOSI引脚
        .spi_ss  (spi_ss),    // SPI SS引脚
        .spi_clk (spi_clk)    // SPI CLK引脚

    );

endmodule
