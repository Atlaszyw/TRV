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

// ram module
module ram
    import tinyriscv_pkg::*;
(

    input clk_i,
    input rst_ni,

    input                    we_i,    // write enable
    input [MemAddrBus - 1:0] addr_i,  // addr
    input [    MemBus - 1:0] data_i,

    output logic [MemBus - 1:0] data_o  // read data

);

    logic [MemBus - 1:0] _ram[MemNum];


    always_ff @(posedge clk_i) begin
        if (we_i == WriteEnable) begin
            _ram[addr_i[$clog2(MemNum) + 1:2]] <= data_i;
        end
    end

    always_comb begin
        if (rst_ni == RstEnable) begin
            data_o = '0;
        end
        else begin
            data_o = _ram[addr_i[$clog2(MemNum) + 1:2]];
        end
    end

endmodule
