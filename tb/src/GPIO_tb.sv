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
  localparam bolt = 1000000000 / 115200;
  //-----------------------------------------------------//
  // Signal
  //-----------------------------------------------------//
  logic clk_i;
  logic rst_ni;

  logic uart_debug_pin;
  logic uart_tx_pin;
  logic uart_rx_pin;
  wire [15:0] gpio;

  wire [2:0] pwm_o;
  wire scl_o;
  wire sda_io;

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
  assign gpio[1]        = gpiodriver;
  assign uart_debug_pin = '0;
  tinyriscv_soc_top i_tinyriscv_soc_top (

    .clk_i (clk_i),
    .rst_ni(rst_ni),

    .uart_debug_pin(uart_debug_pin),  // 串口下载使能引脚

    .uart_tx_pin(uart_tx_pin),  // UART发送引脚
    .uart_rx_pin(uart_rx_pin),  // UART接收引脚
    .gpio_out   (gpio),         // GPIO引脚

    .pwm_o (pwm_o),
    .scl_o (scl_o),
    .sda_io(sda_io)
  );
endmodule
