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
    parameter int unsigned GPIO_NUM = 11
) (

    input clk_i,
    input rst_ni,

    // input uart_debug_pin,  // 串口下载使能引脚

    // output logic                  uart_tx_pin,  // UART发送引脚
    // input                         uart_rx_pin,  // UART接收引脚
    // inout [GPIO_NUM - 1:0] gpio_out,  // GPIO引脚

    // input        jtag_TCK,  // JTAG TCK引脚
    // input        jtag_TMS,  // JTAG TMS引脚
    // input        jtag_TDI,  // JTAG TDI引脚
    // output logic jtag_TDO,  // JTAG TDO引脚

    output logic tx,
    input        rx,
    output logic succ  // 测试是否成功信号
);
    logic                      rst_nid;
    logic                      over;
    // tinyriscv
    logic [     INT_BUS - 1:0] int_flag;

    // gpio
    logic [    GPIO_NUM - 1:0] io_in;
    logic [GPIO_NUM * 2 - 1:0] gpio_ctrl;
    logic [    GPIO_NUM - 1:0] gpio_data;

    logic [              31:0] instr_addr;
    logic [              31:0] instr_data;

    assign int_flag = 8'b0;

    debounce #(
        .DEBOUNCE_INTERVAL(10)
    ) u_debounce_rst (
        .clk_i,  // Clock input
        .button_in (rst_ni),  // Raw button input
        .button_out(rst_nid)  // Debounced button output
    );

    apb4_intf apb_slv[4] (
        clk_i,
        rst_nid
    );
    apb4_intf apb_mst (
        clk_i,
        rst_nid
    );

    // tinyriscv处理器核模块例化
    tinyriscv u_tinyriscv (
        .clk_i (clk_i),
        .rst_ni(rst_nid),

        .apb_mst,

        .pc_addr_o (instr_addr),
        .pc_data_i (instr_data),
        .pc_ready_i('1),

        .int_i(int_flag),
        .succ (succ),
        .over (over)
    );

    apb4_mux #(
        .NUM_SLAVES(4)
    ) mux_apb4 (
        // 主设备接口
        .master_if(apb_mst),
        .slave_if (apb_slv)
    );
    // rom模块例化
    apb4_rom u_L1 (
        apb_slv[0],
        instr_addr,
        instr_data
    );

//    gpio_apb4 #(
//        .GPIO_NUM(2)
//    ) u_gpio (
//        .apb_slv(apb_slv[3]),
//        .io_pin_i,
//        .reg_ctrl,
//        .io_pin_o
//    );


    uart uart (
        .apb_slave(apb_slv[2]),  // APB 接口从端口

        .tx,  // UART 发送引脚
        .rx  // UART 接收引脚
    );

    // ram模块例化
    apb4_ram u_ram (apb_slv[1]);

endmodule
