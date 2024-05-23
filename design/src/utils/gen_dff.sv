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

// 带默认值和控制信号的流水线触发器
module gen_pipe_dff #(
    parameter int unsigned DW = 32
) (

    input clk_i,
    input rst_ni,
    input hold_en,

    input        [DW-1:0] def_val,
    input        [DW-1:0] din,
    output logic [DW-1:0] qout

);

    logic [DW-1:0] qout_r;

    always_ff @(posedge clk_i) begin
        if (!rst_ni | hold_en) begin
            qout_r <= def_val;
        end
        else begin
            qout_r <= din;
        end
    end

    assign qout = qout_r;

endmodule

// 复位后输出为0的触发器
module gen_rst_0_dff #(
    parameter int unsigned DW = 32
) (

    input clk_i,
    input rst_ni,

    input        [DW-1:0] din,
    output logic [DW-1:0] qout

);

    logic [DW-1:0] qout_r;

    always_ff @(posedge clk_i) begin
        if (!rst_ni) begin
            qout_r <= {DW{1'b0}};
        end
        else begin
            qout_r <= din;
        end
    end

    assign qout = qout_r;

endmodule

// 复位后输出为1的触发器
module gen_rst_1_dff #(
    parameter int unsigned DW = 32
) (

    input clk_i,
    input rst_ni,

    input        [DW-1:0] din,
    output logic [DW-1:0] qout

);

    logic [DW-1:0] qout_r;

    always_ff @(posedge clk_i) begin
        if (!rst_ni) begin
            qout_r <= {DW{1'b1}};
        end
        else begin
            qout_r <= din;
        end
    end

    assign qout = qout_r;

endmodule

// 复位后输出为默认值的触发器
module gen_rst_def_dff #(
    parameter int unsigned DW = 32
) (

    input          clk_i,
    input          rst_ni,
    input [DW-1:0] def_val,

    input        [DW-1:0] din,
    output logic [DW-1:0] qout

);

    logic [DW-1:0] qout_r;

    always_ff @(posedge clk_i) begin
        if (!rst_ni) begin
            qout_r <= def_val;
        end
        else begin
            qout_r <= din;
        end
    end

    assign qout = qout_r;

endmodule
