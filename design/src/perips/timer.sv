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
// 32 bits count up timer module
module timer
    import tinyriscv_pkg::*;
(

    input clk_i,
    input rst_ni,

    input [31:0] data_i,
    input [31:0] addr_i,
    input        we_i,

    output logic [31:0] data_o,
    output logic        int_sig_o

);

    localparam REG_CTRL = 4'h0;
    localparam REG_COUNT = 4'h4;
    localparam REG_VALUE = 4'h8;

    // [0]: timer enable
    // [1]: timer int enable
    // [2]: timer int pending, write 1 to clear it
    // addr offset: 0x00
    logic [31:0] timer_ctrl;

    // timer current count, read only
    // addr offset: 0x04
    logic [31:0] timer_count;

    // timer expired value
    // addr offset: 0x08
    logic [31:0] timer_value;

    logic addr_dummy;
    assign addr_dummy = |addr_i[31:4];

    assign int_sig_o  = ((timer_ctrl[2] == 1'b1) && (timer_ctrl[1] == 1'b1)) ? '1 : '0;

    // counter
    always_ff @(posedge clk_i) begin
        if (~rst_ni) begin
            timer_count <= '0;
        end
        else begin
            if (timer_ctrl[0] == 1'b1) begin
                timer_count <= timer_count + 1'b1;
                if (timer_count >= timer_value) begin
                    timer_count <= '0;
                end
            end
            else begin
                timer_count <= '0;
            end
        end
    end

    // write regs
    always_ff @(posedge clk_i) begin
        if (~rst_ni) begin
            timer_ctrl  <= '0;
            timer_value <= '0;
        end
        else begin
            if (we_i) begin
                case (addr_i[3:0])
                    REG_CTRL: begin
                        timer_ctrl <= {data_i[31:3], (timer_ctrl[2] & (~data_i[2])), data_i[1:0]};
                    end
                    REG_VALUE: begin
                        timer_value <= data_i;
                    end
                endcase
            end
            else begin
                if ((timer_ctrl[0] == 1'b1) && (timer_count >= timer_value)) begin
                    timer_ctrl[0] <= 1'b0;
                    timer_ctrl[2] <= 1'b1;
                end
            end
        end
    end

    // read regs
    always_comb begin
        if (~rst_ni) begin
            data_o = '0;
        end
        else begin
            case (addr_i[3:0])
                REG_VALUE: begin
                    data_o = timer_value;
                end
                REG_CTRL: begin
                    data_o = timer_ctrl;
                end
                REG_COUNT: begin
                    data_o = timer_count;
                end
                default: begin
                    data_o = '0;
                end
            endcase
        end
    end

endmodule
