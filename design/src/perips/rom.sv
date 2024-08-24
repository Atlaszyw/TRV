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
  parameter int unsigned Depth       = 1024,
  parameter int unsigned Width       = 32,
  parameter string       MemInitFile = ""
) (

  input clk_i,
  input rst_ni,

  input                    we_i,    // write enable
  input [MemAddrBus - 1:0] addr_i,  // addr
  input [     Width - 1:0] data_i,

  output logic [Width - 1:0] data_o  // read data

);

  (* ram_style="block" *) logic [Width - 1:0] mem[Depth];

  always @(posedge clk_i) begin
    if (we_i == WriteEnable) mem[addr_i[$clog2(Depth) + 1:2]] <= data_i;
  end

  always_comb begin
    if (~rst_ni) data_o = '0;
    else data_o = mem[addr_i[$clog2(Depth) + 1:2]];
  end

  `include "prim_memutil.svh"

endmodule
