/*
 Copyright 2019 Blue Liang, liangkangnan@163.com

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

// 除法模块
// 试商法实现32位整数除法
// 每次除法运算至少需要33个时钟周期才能完成
module div
    import tinyriscv_pkg::*;
(

    input clk_i,
    input rst_ni,

    // from ex
    input [    RegBus - 1:0] dividend_i,  // 被除数
    input [    RegBus - 1:0] divisor_i,   // 除数
    input                    start_i,     // 开始信号，运算期间这个信号需要一直保持有效
    input [             2:0] op_i,        // 具体是哪一条指令
    input [RegAddrBus - 1:0] reg_waddr_i, // 运算结束后需要写的寄存器

    // to ex
    output logic [    RegBus - 1:0] result_o,    // 除法结果，高32位是余数，低32位是商
    output logic                    ready_o,     // 运算结束信号
    output logic                    busy_o,      // 正在运算信号
    output logic [RegAddrBus - 1:0] reg_waddr_o  // 运算结束后需要写的寄存器

);

    // 状态定义
    localparam STATE_IDLE = 4'b0001;
    localparam STATE_START = 4'b0010;
    localparam STATE_CALC = 4'b0100;
    localparam STATE_END = 4'b1000;

    logic [RegBus - 1:0] dividend_r;
    logic [RegBus - 1:0] divisor_r;
    logic [2:0] op_r;
    logic [3:0] state;
    logic [31:0] count;
    logic [RegBus - 1:0] div_result;
    logic [RegBus - 1:0] div_remain;
    logic [RegBus - 1:0] minuend;
    logic invert_result;

    wire op_div = (op_r == INST_DIV);
    wire op_divu = (op_r == INST_DIVU);
    wire op_rem = (op_r == INST_REM);
    wire op_remu = (op_r == INST_REMU);

    wire [31:0] dividend_invert = (-dividend_r);
    wire [31:0] divisor_invert = (-divisor_r);
    wire minuend_ge_divisor = minuend >= divisor_r;
    wire [31:0] minuend_sub_res = minuend - divisor_r;
    wire [31:0] div_result_tmp = minuend_ge_divisor ? ({div_result[30:0], 1'b1}) : ({div_result[30:0], 1'b0});
    wire [31:0] minuend_tmp = minuend_ge_divisor ? minuend_sub_res[30:0] : minuend[30:0];

    // 状态机实现
    always_ff @(posedge clk_i) begin
        if (rst_ni == RstEnable) begin
            state         <= STATE_IDLE;
            ready_o       <= ~DivResultReady;
            result_o      <= '0;
            div_result    <= '0;
            div_remain    <= '0;
            op_r          <= 3'h0;
            reg_waddr_o   <= '0;
            dividend_r    <= '0;
            divisor_r     <= '0;
            minuend       <= '0;
            invert_result <= 1'b0;
            busy_o        <= False;
            count         <= '0;
        end
        else begin
            case (state)
                STATE_IDLE: begin
                    if (start_i == DivStart) begin
                        op_r        <= op_i;
                        dividend_r  <= dividend_i;
                        divisor_r   <= divisor_i;
                        reg_waddr_o <= reg_waddr_i;
                        state       <= STATE_START;
                        busy_o      <= True;
                    end
                    else begin
                        op_r        <= 3'h0;
                        reg_waddr_o <= '0;
                        dividend_r  <= '0;
                        divisor_r   <= '0;
                        ready_o     <= ~DivResultReady;
                        result_o    <= '0;
                        busy_o      <= False;
                    end
                end

                STATE_START: begin
                    if (start_i == DivStart) begin
                        // 除数为0
                        if (divisor_r == '0) begin
                            if (op_div | op_divu) begin
                                result_o <= 32'hffffffff;
                            end
                            else begin
                                result_o <= dividend_r;
                            end
                            ready_o <= DivResultReady;
                            state   <= STATE_IDLE;
                            busy_o  <= False;
                            // 除数不为0
                        end
                        else begin
                            busy_o     <= True;
                            count      <= 32'h40000000;
                            state      <= STATE_CALC;
                            div_result <= '0;
                            div_remain <= '0;

                            // DIV和REM这两条指令是有符号数运算指令
                            if (op_div | op_rem) begin
                                // 被除数求补码
                                if (dividend_r[31] == 1'b1) begin
                                    dividend_r <= dividend_invert;
                                    minuend    <= dividend_invert[31];
                                end
                                else begin
                                    minuend <= dividend_r[31];
                                end
                                // 除数求补码
                                if (divisor_r[31] == 1'b1) begin
                                    divisor_r <= divisor_invert;
                                end
                            end
                            else begin
                                minuend <= dividend_r[31];
                            end

                            // 运算结束后是否要对结果取补码
                            if ((op_div && (dividend_r[31] ^ divisor_r[31] == 1'b1)) ||
                                (op_rem && (dividend_r[31] == 1'b1))) begin
                                invert_result <= 1'b1;
                            end
                            else begin
                                invert_result <= 1'b0;
                            end
                        end
                    end
                    else begin
                        state    <= STATE_IDLE;
                        result_o <= '0;
                        ready_o  <= ~DivResultReady;
                        busy_o   <= False;
                    end
                end

                STATE_CALC: begin
                    if (start_i == DivStart) begin
                        dividend_r <= {dividend_r[30:0], 1'b0};
                        div_result <= div_result_tmp;
                        count      <= {1'b0, count[31:1]};
                        if (|count) begin
                            minuend <= {minuend_tmp[30:0], dividend_r[30]};
                        end
                        else begin
                            state <= STATE_END;
                            if (minuend_ge_divisor) begin
                                div_remain <= minuend_sub_res;
                            end
                            else begin
                                div_remain <= minuend;
                            end
                        end
                    end
                    else begin
                        state    <= STATE_IDLE;
                        result_o <= '0;
                        ready_o  <= ~DivResultReady;
                        busy_o   <= False;
                    end
                end

                STATE_END: begin
                    if (start_i == DivStart) begin
                        ready_o <= DivResultReady;
                        state   <= STATE_IDLE;
                        busy_o  <= False;
                        if (op_div | op_divu) begin
                            if (invert_result) begin
                                result_o <= (-div_result);
                            end
                            else begin
                                result_o <= div_result;
                            end
                        end
                        else begin
                            if (invert_result) begin
                                result_o <= (-div_remain);
                            end
                            else begin
                                result_o <= div_remain;
                            end
                        end
                    end
                    else begin
                        state    <= STATE_IDLE;
                        result_o <= '0;
                        ready_o  <= ~DivResultReady;
                        busy_o   <= False;
                    end
                end

            endcase
        end
    end

endmodule
