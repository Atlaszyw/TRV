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

// 将输入打DP拍后输出
module gen_ticks_sync #(
    parameter int unsigned DP = 2,
    parameter int unsigned DW = 32
) (

    input rst_ni,
    input clk_i,

    input        [DW-1:0] din,
    output logic [DW-1:0] dout

);

    wire [DW-1:0] sync_dat[DP-1:0];

    genvar i;

    generate
        for (i = 0; i < DP; i = i + 1) begin : dp_width
            if (i == 0) begin : dp_is_0
                gen_rst_0_dff #(DW) rst_0_dff (
                    clk_i,
                    rst_ni,
                    din,
                    sync_dat[0]
                );
            end
            else begin : dp_is_not_0
                gen_rst_0_dff #(DW) rst_0_dff (
                    clk_i,
                    rst_ni,
                    sync_dat[i-1],
                    sync_dat[i]
                );
            end
        end
    endgenerate

    assign dout = sync_dat[DP-1];

endmodule
