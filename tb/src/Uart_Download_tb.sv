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
    logic succ;
    //-----------------------------------------------------//
    // Signal
    //-----------------------------------------------------//
    logic [7:0] pack1[38] = '{
        8'hAA,
        8'hBB,
        8'hCC,
        8'hDD,
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
        8'd40,
        0,
        0,
        0,
        0,
        8'h42,
        8'h0f
    };

    logic [7:0] pack2[35] = '{
        8'h01,
        8'hb7,
        8'h07,
        8'h00,
        8'h30,
        8'h13,
        8'h07,
        8'h10,
        8'h00,
        8'h23,
        8'ha0,
        8'he7,
        8'h00,
        8'h93,
        8'h0f,
        8'h00,
        8'h08,
        8'h13,
        8'h0f,
        8'h00,
        8'h00,
        8'h2f,
        8'h2f,
        8'haf,
        8'h00,
        8'h2f,
        8'h2f,
        8'haf,
        8'h01,
        8'h2f,
        8'h2f,
        8'haf,
        8'h03,
        8'h7a,
        8'h3b
    };
    logic [7:0] pack3[35] = '{
        8'h02,
        8'h2f,
        8'h2f,
        8'hcf,
        8'h02,
        8'h2f,
        8'h2f,
        8'h0f,
        8'h00,
        8'h00,
        8'h00,
        8'h00,
        8'h00,
        8'h00,
        8'h00,
        8'h00,
        8'h00,
        8'h00,
        8'h00,
        8'h00,
        8'h00,
        8'h00,
        8'h00,
        8'h00,
        8'h00,
        8'h00,
        8'h00,
        8'h00,
        8'h00,
        8'h00,
        8'h00,
        8'h00,
        8'h00,
        8'he0,
        8'hd2
    };


    logic clk_i;
    logic rst_ni;

    logic uart_tx_pin;
    logic uart_rx_pin;

    initial begin
        GenClk(clk_i, 20, 20);
    end

    initial begin
        uart_debug_pin_r = '0;
        GenRst(clk_i, rst_ni, 5, 3);
        #100;
        uart_debug_pin_r = '1;

        uart_send_package(pack1, uart_rx_pin);
        uart_send_package(pack2, uart_rx_pin);
        uart_send_package(pack3, uart_rx_pin);

        #10000;

        uart_debug_pin_r = '0;
    end

    assign gpio[1]        = gpiodriver;
    assign uart_debug_pin = uart_debug_pin_r;
    tinyriscv_soc_top i_tinyriscv_soc_top (

        .clk_i,
        .rst_ni,


        .tx(uart_tx_pin),  // UART发送引脚
        .rx(uart_rx_pin),  // UART接收引脚
        .succ
    );

    task uart_send_package(input [7:0] data_pak[35], ref logic rx_pin);
        begin
            for (int i = 0; i < 35; i++) begin
                uart_send_byte(data_pak[i], rx_pin);
            end
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
