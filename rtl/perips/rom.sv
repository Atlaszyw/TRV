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
module rom
    import tinyriscv_pkg::*;
#(
    parameter MemInitFile = "gpio.mif"
) (

    input clk_i,
    input rst_ni,

    input                    we_i,    // write enable
    input [MemAddrBus - 1:0] addr_i,  // addr
    input [    MemBus - 1:0] data_i,

    output logic [MemBus - 1:0] data_o  // read data

);

    (* ram_style="block" *) logic [MemBus - 1:0] _rom[RomNum];

    always @(posedge clk_i) begin
        if (we_i == WriteEnable) begin
            _rom[addr_i[31:2]] <= data_i;
        end
    end

    always_comb begin
        if (rst_ni == RstEnable) begin
            data_o = '0;
        end
        else begin
            data_o = _rom[addr_i[31:2]];
        end
    end

`ifdef FPGA
    initial begin
        if (MemInitFile != "") begin : gen_meminit
            $display("Initializing memory %m from file '%s'.", MemInitFile);
            $readmemh(MemInitFile, _rom);
        end
    end
`endif
endmodule
