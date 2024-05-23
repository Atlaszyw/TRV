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
// RIB总线模块
module rib
    import tinyriscv_pkg::*;
(
    // master 0 interface
    input        [MemAddrBus - 1:0] m0_addr_i,  // 主设备0读、写地址
    input        [    MemBus - 1:0] m0_data_i,  // 主设备0写数据
    output logic [    MemBus - 1:0] m0_data_o,  // 主设备0读取到的数据
    input                           m0_req_i,   // 主设备0访问请求标志
    input                           m0_we_i,    // 主设备0写标志
    output logic                    m0_ready_o,

    // master 2 interface
    input        [MemAddrBus - 1:0] m1_addr_i,  // 主设备2读、写地址
    input        [    MemBus - 1:0] m1_data_i,  // 主设备2写数据
    output logic [    MemBus - 1:0] m1_data_o,  // 主设备2读取到的数据
    input                           m1_req_i,   // 主设备2访问请求标志
    input                           m1_we_i,    // 主设备2写标志

    // master 2 interface
    input        [MemAddrBus - 1:0] m2_addr_i,  // 主设备2读、写地址
    input        [    MemBus - 1:0] m2_data_i,  // 主设备2写数据
    output logic [    MemBus - 1:0] m2_data_o,  // 主设备2读取到的数据
    input                           m2_req_i,   // 主设备2访问请求标志
    input                           m2_we_i,    // 主设备2写标志

    // master 3 interface
    input        [MemAddrBus - 1:0] m3_addr_i,  // 主设备2读、写地址
    input        [    MemBus - 1:0] m3_data_i,  // 主设备2写数据
    output logic [    MemBus - 1:0] m3_data_o,  // 主设备2读取到的数据
    input                           m3_req_i,   // 主设备2访问请求标志
    input                           m3_we_i,    // 主设备2写标志

    // slave 1 interface
    output logic [MemAddrBus - 1:0] s0_addr_o,  // 从设备1读、写地址
    output logic [    MemBus - 1:0] s0_data_o,  // 从设备1写数据
    input        [    MemBus - 1:0] s0_data_i,  // 从设备1读取到的数据
    output logic                    s0_we_o,    // 从设备1写标志


    // slave 1 interface
    output logic [MemAddrBus - 1:0] s1_addr_o,  // 从设备1读、写地址
    output logic [    MemBus - 1:0] s1_data_o,  // 从设备1写数据
    input        [    MemBus - 1:0] s1_data_i,  // 从设备1读取到的数据
    output logic                    s1_we_o,    // 从设备1写标志

    // slave 2 interface
    output logic [MemAddrBus - 1:0] s2_addr_o,  // 从设备2读、写地址
    output logic [    MemBus - 1:0] s2_data_o,  // 从设备2写数据
    input        [    MemBus - 1:0] s2_data_i,  // 从设备2读取到的数据
    output logic                    s2_we_o,    // 从设备2写标志

    // slave 3 interface
    output logic [MemAddrBus - 1:0] s3_addr_o,  // 从设备3读、写地址
    output logic [    MemBus - 1:0] s3_data_o,  // 从设备3写数据
    input        [    MemBus - 1:0] s3_data_i,  // 从设备3读取到的数据
    output logic                    s3_we_o,    // 从设备3写标志
    output logic                    s3_req_o,

    // slave 4 interface
    output logic [MemAddrBus - 1:0] s4_addr_o,  // 从设备4读、写地址
    output logic [    MemBus - 1:0] s4_data_o,  // 从设备4写数据
    input        [    MemBus - 1:0] s4_data_i,  // 从设备4读取到的数据
    output logic                    s4_we_o,    // 从设备4写标志

    // slave 5 interface
    output logic [MemAddrBus - 1:0] s5_addr_o,  // 从设备5读、写地址
    output logic [    MemBus - 1:0] s5_data_o,  // 从设备5写数据
    input        [    MemBus - 1:0] s5_data_i,  // 从设备5读取到的数据
    output logic                    s5_we_o,    // 从设备5写标志
    // slave 6 interface
    output logic [MemAddrBus - 1:0] s6_addr_o,  // 从设备6读、写地址
    output logic [    MemBus - 1:0] s6_data_o,  // 从设备6写数据
    input        [    MemBus - 1:0] s6_data_i,  // 从设备6读取到的数据
    output logic                    s6_we_o,    // 从设备6写标志
    output logic                    s6_req_o,   // 从设备6请求
    input  logic                    s6_ready_i,

    // slave 7 interface
    output logic [MemAddrBus - 1:0] s7_addr_o,  // 从设备7读、写地址
    output logic [    MemBus - 1:0] s7_data_o,  // 从设备7写数据
    input        [    MemBus - 1:0] s7_data_i,  // 从设备7读取到的数据
    output logic                    s7_we_o,    // 从设备7写标志
    output logic                    s7_req_o,   // 从设备6请求
    input  logic                    s7_ready_i,


    output logic hold_flag_o  // 暂停流水线标志

);

    logic [3:0] req;
    logic req_t;

    // 主设备请求信号
    assign req   = {m3_req_i, m0_req_i, m2_req_i, m1_req_i};
    assign req_t = |req;

    logic [MemAddrBus - 1:0] addr_t;
    logic [MemBus - 1:0] s_data_t;
    logic we_t;
    logic ready_t;
    logic [MemBus - 1:0] m_data_t;

    assign hold_flag_o = (m3_req_i | m2_req_i) ? HoldEnable : HoldDisable;

    always_comb begin
        m0_data_o = '0;
        m1_data_o = INST_NOP;
        m2_data_o = '0;
        m3_data_o = '0;

        casex (req)
            4'b1xxx: begin

                addr_t    = m3_addr_i;
                s_data_t  = m3_data_i;
                we_t      = m3_we_i;
                m3_data_o = m_data_t;
            end
            4'b01xx: begin

                addr_t     = m0_addr_i;
                s_data_t   = m0_data_i;
                we_t       = m0_we_i;
                m0_data_o  = m_data_t;
                m0_ready_o = ready_t;
            end
            4'b001x: begin

                addr_t    = m2_addr_i;
                s_data_t  = m2_data_i;
                we_t      = m2_we_i;
                m2_data_o = m_data_t;
            end
            default: begin
                addr_t    = m1_addr_i;
                s_data_t  = m1_data_i;
                we_t      = m1_we_i;
                m1_data_o = m_data_t;
            end
        endcase
    end
    // 根据仲裁结果，选择(访问)对应的从设备
    always_comb begin
        s0_addr_o = '0;
        s1_addr_o = '0;
        s2_addr_o = '0;
        s3_addr_o = '0;
        s4_addr_o = '0;
        s5_addr_o = '0;
        s6_addr_o = '0;
        s7_addr_o = '0;
        s0_data_o = '0;
        s1_data_o = '0;
        s2_data_o = '0;
        s3_data_o = '0;
        s4_data_o = '0;
        s5_data_o = '0;
        s6_data_o = '0;
        s7_data_o = '0;
        s0_we_o   = '0;
        s1_we_o   = '0;
        s2_we_o   = '0;
        s3_we_o   = '0;
        s4_we_o   = '0;
        s5_we_o   = '0;
        s6_we_o   = '0;
        s7_we_o   = '0;
        m_data_t  = '0;
        s3_req_o  = '0;
        s6_req_o  = '0;
        s7_req_o  = '0;
        ready_t   = '0;
        case (addr_t[28 +: 4])
            4'h0: begin
                s0_we_o   = we_t;
                s0_addr_o = addr_t;
                s0_data_o = s_data_t;
                m_data_t  = s0_data_i;
                ready_t   = '1;
            end
            4'h1: begin
                s1_we_o   = we_t;
                s1_addr_o = addr_t;
                s1_data_o = s_data_t;
                m_data_t  = s1_data_i;
                ready_t   = '1;
            end
            4'h2: begin
                s2_we_o   = we_t;
                s2_addr_o = addr_t;
                s2_data_o = s_data_t;
                m_data_t  = s2_data_i;
                ready_t   = '1;
            end
            4'h3: begin
                s3_we_o   = we_t;
                s3_addr_o = addr_t;
                s3_data_o = s_data_t;
                m_data_t  = s3_data_i;
                s3_req_o  = req_t;
                ready_t   = '1;
            end
            4'h4: begin
                s4_we_o   = we_t;
                s4_addr_o = addr_t;
                s4_data_o = s_data_t;
                m_data_t  = s4_data_i;
                ready_t   = '1;
            end
            4'h5: begin
                s5_we_o   = we_t;
                s5_addr_o = addr_t;
                s5_data_o = s_data_t;
                m_data_t  = s5_data_i;
                ready_t   = '1;
            end
            4'h6: begin
                s6_we_o   = we_t;
                s6_addr_o = addr_t;
                s6_data_o = s_data_t;
                m_data_t  = s6_data_i;
                s6_req_o  = req_t;
                ready_t   = s6_ready_i;
            end
            4'h7: begin
                s7_we_o   = we_t;
                s7_addr_o = addr_t;
                s7_data_o = s_data_t;
                m_data_t  = s7_data_i;
                s7_req_o  = req_t;
                ready_t   = s7_ready_i;
            end
        endcase

    end

endmodule
