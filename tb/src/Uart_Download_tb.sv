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
    logic [7:0] pack1[35] = '{
        0,
        1,
        2,
        3,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        8'h20,
        0,
        0,
        0,
        0,
        8'ha3,
        8'hce
    };
    logic [7:0] pack2[35] = '{
        1,
        1,
        2,
        3,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        8'h20,
        0,
        0,
        0,
        8'h32,
        8'h22,
        8'h1b
    };
    logic [7:0] pack3[35] = '{
        2,
        1,
        2,
        3,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        8'h20,
        0,
        0,
        0,
        8'h32,
        8'h22,
        8'h1b
    };
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

        uart_send_package(pack1, uart_rx_pin);
        uart_send_package(pack2, uart_rx_pin);
        uart_send_package(pack3, uart_rx_pin);

        // GenRst(clk_i, rst_ni, 5, 3);
    end

    // initial begin
    //     #0 gpiodriver = '0;
    //     #5000;
    //     #1000 gpiodriver = ~gpiodriver;
    //     #1000 gpiodriver = ~gpiodriver;
    //     #1000 gpiodriver = ~gpiodriver;
    //     #1000 gpiodriver = ~gpiodriver;
    //     #1000 gpiodriver = ~gpiodriver;
    //     #1000 gpiodriver = ~gpiodriver;
    //     #1000 gpiodriver = ~gpiodriver;
    //     #1000 gpiodriver = ~gpiodriver;
    //     #1000 gpiodriver = ~gpiodriver;
    //     #1000 gpiodriver = ~gpiodriver;
    //     #1000 gpiodriver = ~gpiodriver;
    //     #1000 gpiodriver = ~gpiodriver;
    //     $finish();
    // end
    assign gpio[1]        = gpiodriver;
    assign uart_debug_pin = '1;
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

    task uart_send_package(input [7:0] data_pak[35], ref logic rx_pin);
        begin
            uart_send_byte(data_pak[0], rx_pin);
            uart_send_byte(data_pak[1], rx_pin);
            uart_send_byte(data_pak[2], rx_pin);
            uart_send_byte(data_pak[3], rx_pin);
            uart_send_byte(data_pak[4], rx_pin);
            uart_send_byte(data_pak[5], rx_pin);
            uart_send_byte(data_pak[6], rx_pin);
            uart_send_byte(data_pak[7], rx_pin);
            uart_send_byte(data_pak[8], rx_pin);
            uart_send_byte(data_pak[9], rx_pin);
            uart_send_byte(data_pak[10], rx_pin);
            uart_send_byte(data_pak[11], rx_pin);
            uart_send_byte(data_pak[12], rx_pin);
            uart_send_byte(data_pak[13], rx_pin);
            uart_send_byte(data_pak[14], rx_pin);
            uart_send_byte(data_pak[15], rx_pin);
            uart_send_byte(data_pak[16], rx_pin);
            uart_send_byte(data_pak[17], rx_pin);
            uart_send_byte(data_pak[18], rx_pin);
            uart_send_byte(data_pak[19], rx_pin);
            uart_send_byte(data_pak[20], rx_pin);
            uart_send_byte(data_pak[21], rx_pin);
            uart_send_byte(data_pak[22], rx_pin);
            uart_send_byte(data_pak[23], rx_pin);
            uart_send_byte(data_pak[24], rx_pin);
            uart_send_byte(data_pak[25], rx_pin);
            uart_send_byte(data_pak[26], rx_pin);
            uart_send_byte(data_pak[27], rx_pin);
            uart_send_byte(data_pak[28], rx_pin);
            uart_send_byte(data_pak[29], rx_pin);
            uart_send_byte(data_pak[30], rx_pin);
            uart_send_byte(data_pak[31], rx_pin);
            uart_send_byte(data_pak[32], rx_pin);
            uart_send_byte(data_pak[33], rx_pin);
            uart_send_byte(data_pak[34], rx_pin);
        end
    endtask

    // Task to send a byte over UART
    task uart_send_byte(input [7:0] data, ref logic rx_pin);
        begin
            // Simulate receiving data
            rx_pin = '1;  // Start bit
            #bolt;  // Baud rate delay (1 bit period at 115200 bps)
            rx_pin = '0;  // Bit 0
            #bolt;
            rx_pin = data[0];  // Bit 1
            #bolt;
            rx_pin = data[1];  // Bit 2
            #bolt;
            rx_pin = data[2];  // Bit 3
            #bolt;
            rx_pin = data[3];  // Bit 4
            #bolt;
            rx_pin = data[4];  // Bit 5
            #bolt;
            rx_pin = data[5];  // Bit 6
            #bolt;
            rx_pin = data[6];  // Bit 7
            #bolt;
            rx_pin = data[7];  // Bit 8
            #bolt;
            rx_pin = '1;  // Stop bit
            #bolt;
        end
    endtask



endmodule
