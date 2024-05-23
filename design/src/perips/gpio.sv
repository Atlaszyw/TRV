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


// GPIO模块
module gpio
    import tinyriscv_pkg::*;
#(
    parameter  int unsigned GPIO_NUM  = 16,
    localparam int unsigned GPIO_NUM_ = GPIO_NUM > MemBus ? MemBus : GPIO_NUM
) (

    input clk_i,
    input rst_ni,

    input                 we_i,
    input [InstBus - 1:0] addr_i,
    input [ MemBus - 1:0] data_i,

    output logic [MemBus - 1:0] data_o,

    input        [    GPIO_NUM_ - 1:0] io_pin_i,
    output logic [GPIO_NUM_ * 2 - 1:0] reg_ctrl,
    output logic [    GPIO_NUM_ - 1:0] io_pin_o

);


    // GPIO控制寄存器
    localparam GPIO_CTRL = 4'h0;
    // GPIO数据寄存器
    localparam GPIO_DATA = 4'h4;

    // 每2位控制1个IO的模式，最多支持16个IO
    // 0: 高阻，1：输出，2：输入
    logic [GPIO_NUM_ * 2 - 1:0] gpio_ctrl;
    // 输入输出数据
    logic [MemBus - 1:0] gpio_data;


    assign reg_ctrl = gpio_ctrl;
    assign io_pin_o = gpio_data;

    genvar i;
    generate
        for (i = 0; i < GPIO_NUM_; i = i + 1) begin
            always_ff @(posedge clk_i) begin
                if (rst_ni == 1'b0) gpio_data[i] <= '0;
                else if (we_i && addr_i[3:0] == GPIO_DATA && gpio_ctrl[2 * i+:2] == 2'b01) gpio_data[i] <= data_i[i];
                else if (gpio_ctrl[2 * i+:2] == 2'b10) gpio_data[i] <= io_pin_i[i];
            end
        end

        for (i = GPIO_NUM_; i < MemBus; i = i + 1) assign gpio_data[i] = '0;
    endgenerate

    // 写寄存器
    always_ff @(posedge clk_i) begin
        if (rst_ni == 1'b0) begin
            gpio_ctrl <= 32'h0;
        end
        else begin
            if (we_i == 1'b1 && addr_i[3:0] == GPIO_CTRL) gpio_ctrl <= data_i;
        end
    end

    // 读寄存器
    always_comb begin
        if (~rst_ni) data_o = '0;
        else
            case (addr_i[3:0])
                GPIO_CTRL: data_o = gpio_ctrl;
                GPIO_DATA: data_o = gpio_data;
                default:   data_o = '0;
            endcase
    end

endmodule
