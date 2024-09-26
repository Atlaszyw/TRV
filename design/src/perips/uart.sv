module uart #(
    parameter int unsigned ADDR_WIDTH = 32,
    parameter int unsigned DATA_WIDTH = 32,
    parameter              CLOCK_FREQ = 50_000_000  // 时钟频率，单位 Hz
) (
    apb4_intf.slave apb_slave,  // APB 接口从端口

    output logic tx,  // UART 发送引脚
    input  logic rx   // UART 接收引脚
);

    // UART 寄存器定义
    logic [7:0] THR;  // 发送保持寄存器（写）
    logic [7:0] RBR;  // 接收缓冲寄存器（读）
    logic [7:0] IER;  // 中断使能寄存器
    logic [7:0] IIR;  // 中断识别寄存器（读）
    logic [7:0] FCR;  // FIFO 控制寄存器（写）
    logic [7:0] LCR;  // 线路控制寄存器
    logic [7:0] MCR;  // 调制解调器控制寄存器
    logic [7:0] LSR;  // 线路状态寄存器
    logic [7:0] MSR;  // 调制解调器状态寄存器
    logic [7:0] SCR;  // 暂存寄存器
    logic [7:0] DLL;  // 除数锁存器低位
    logic [7:0] DLM;  // 除数锁存器高位

    // 内部信号
    logic DLAB;  // 除数锁存访问位（LCR[7]）

    // 分配 DLAB
    assign DLAB = LCR[7];



    // APB 接口读写处理
    always_ff @(posedge apb_slave.PCLK) begin
        if (~apb_slave.PRESETn) begin
            // 复位所有寄存器
            THR              <= 8'h00;
            IER              <= 8'h00;
            LCR              <= 8'h00;
            MCR              <= 8'h00;
            MSR              <= 8'h00;
            SCR              <= 8'h00;
            DLL              <= 8'h01;  // 默认除数值
            DLM              <= 8'h00;
            apb_slave.PRDATA <= '0;
        end
        else begin
            if (apb_slave.PSEL && apb_slave.PENABLE && apb_slave.PREADY) begin
                if (apb_slave.PWRITE) begin
                    // 写操作
                    case (apb_slave.PADDR[4:2])  // 假设地址是字对齐的
                        3'b000: begin
                            if (DLAB) DLL <= apb_slave.PWDATA[7:0];
                            else begin
                                THR <= apb_slave.PWDATA[7:0];
                            end
                        end
                        3'b001: begin
                            if (DLAB) DLM <= apb_slave.PWDATA[7:0];
                            else IER <= apb_slave.PWDATA[7:0];
                        end
                        3'b010:  FCR <= apb_slave.PWDATA[7:0];  // FIFO 控制寄存器
                        3'b011:  LCR <= apb_slave.PWDATA[7:0];  // 线路控制寄存器
                        3'b100:  MCR <= apb_slave.PWDATA[7:0];  // 调制解调器控制寄存器
                        3'b111:  SCR <= apb_slave.PWDATA[7:0];  // 暂存寄存器
                        default: ;
                    endcase
                end
                else begin
                    // 读操作
                    case (apb_slave.PADDR[4:2])
                        3'b000: begin
                            if (DLAB) apb_slave.PRDATA <= {24'b0, DLL};
                            else begin
                                apb_slave.PRDATA <= {24'b0, RBR};
                            end
                        end
                        3'b001: begin
                            if (DLAB) apb_slave.PRDATA <= {24'b0, DLM};
                            else apb_slave.PRDATA <= {24'b0, IER};
                        end
                        3'b010:  apb_slave.PRDATA <= {24'b0, IIR};  // 中断识别寄存器
                        3'b011:  apb_slave.PRDATA <= {24'b0, LCR};  // 线路控制寄存器
                        3'b100:  apb_slave.PRDATA <= {24'b0, MCR};  // 调制解调器控制寄存器
                        3'b101:  apb_slave.PRDATA <= {24'b0, LSR};  // 线路状态寄存器
                        3'b110:  apb_slave.PRDATA <= {24'b0, MSR};  // 调制解调器状态寄存器
                        3'b111:  apb_slave.PRDATA <= {24'b0, SCR};  // 暂存寄存器
                        default: apb_slave.PRDATA <= 32'h0;
                    endcase
                end
            end
        end
    end

    // APB 接口的 PREADY 和 PSLVERR 信号
    assign apb_slave.PREADY  = 1'b1;
    assign apb_slave.PSLVERR = 1'b0;

    // 波特率计算
    logic [15:0] divisor;
    assign divisor = {DLM, DLL};

    // 生成波特率时钟使能信号
    logic baud_tick;
    logic [31:0] baud_counter;

    always_ff @(posedge apb_slave.PCLK) begin
        if (~apb_slave.PRESETn) begin
            baud_counter <= 32'h0;
            baud_tick    <= 1'b0;
        end
        else begin
            if (baud_counter >= divisor << 4) begin
                baud_counter <= 32'h0;
                baud_tick    <= 1'b1;
            end
            else begin
                baud_counter <= baud_counter + 1;
                baud_tick    <= 1'b0;
            end
        end
    end

    // UART 发送器
    logic [10:0] tx_shift_reg;  // 最多11位：起始位，数据位，奇偶校验位，停止位
    logic [3:0] tx_bit_cnt;  // 位计数器
    logic tx_busy;

    logic [3:0] data_bits_num;
    logic parity_enable;
    logic even_parity;
    logic [1:0] stop_bits_num;

    always_comb begin
        case (LCR[1:0])
            2'b00: data_bits_num = 4'd5;
            2'b01: data_bits_num = 4'd6;
            2'b10: data_bits_num = 4'd7;
            2'b11: data_bits_num = 4'd8;
        endcase

        parity_enable = LCR[3];
        even_parity   = LCR[4];
        stop_bits_num = LCR[2] ? 2 : 1;
    end

    // 发送器逻辑
    always_ff @(posedge apb_slave.PCLK) begin
        if (~apb_slave.PRESETn) begin
            tx           <= 1'b1;  // 空闲状态为高电平
            tx_shift_reg <= {11{1'b1}};
            tx_bit_cnt   <= 4'h0;
            tx_busy      <= 1'b0;
        end
        else begin
            if (baud_tick) begin
                if (tx_busy) begin
                    tx           <= tx_shift_reg[0];
                    tx_shift_reg <= {1'b1, tx_shift_reg[10:1]};
                    tx_bit_cnt   <= tx_bit_cnt + 1;
                    if (tx_bit_cnt == (1 + data_bits_num + parity_enable + stop_bits_num - 1)) begin
                        tx_busy <= 1'b0;
                    end
                end
                else begin
                    tx <= 1'b1;  // 空闲状态
                end
            end

            if (!tx_busy && !LSR[5]) begin
                // 从 THR 加载数据到移位寄存器
                // 组装移位寄存器
                case (data_bits_num)
                    4'd5: tx_shift_reg <= {parity_enable ? even_parity ? ~(^THR[5-1:0]) : ^THR[5-1:0] : 1'b1, THR[5-1:0], 1'b0};
                    4'd6: tx_shift_reg <= {parity_enable ? even_parity ? ~(^THR[6-1:0]) : ^THR[6-1:0] : 1'b1, THR[6-1:0], 1'b0};
                    4'd7: tx_shift_reg <= {parity_enable ? even_parity ? ~(^THR[7-1:0]) : ^THR[7-1:0] : 1'b1, THR[7-1:0], 1'b0};
                    4'd8: tx_shift_reg <= {parity_enable ? even_parity ? ~(^THR[8-1:0]) : ^THR[8-1:0] : 1'b1, THR[8-1:0], 1'b0};
                endcase
                tx_bit_cnt <= 4'h0;
                tx_busy    <= 1'b1;
            end
        end
    end

    // UART 接收器
    logic [10:0] rx_shift_reg;
    logic [3:0] rx_bit_cnt;
    logic rx_busy;
    logic [15:0] rx_baud_counter;

    // 接收器逻辑
    always_ff @(posedge apb_slave.PCLK) begin
        if (~apb_slave.PRESETn) begin
            rx_shift_reg    <= {11{1'b0}};
            rx_bit_cnt      <= 4'h0;
            rx_busy         <= 1'b0;
            RBR             <= 8'h00;
            rx_baud_counter <= 16'h0;
        end
        else begin
            if (!rx_busy) begin
                if (!rx) begin  // 检测到起始位
                    rx_busy         <= 1'b1;
                    rx_baud_counter <= (divisor << 4) / 2;  // 在位的中间采样
                    rx_bit_cnt      <= 0;
                end
            end
            else begin
                if (rx_baud_counter == 0) begin
                    rx_baud_counter <= divisor << 4;
                    rx_shift_reg    <= {rx, rx_shift_reg[10:1]};
                    rx_bit_cnt      <= rx_bit_cnt + 1;
                    if (rx_bit_cnt == (4'd1 + 4'(data_bits_num) + 4'(parity_enable) + 4'(stop_bits_num) - 4'd1)) begin
                        rx_busy <= 1'b0;
                        // 检查奇偶校验、停止位等
                        case (data_bits_num)
                            4'd5: RBR <= rx_shift_reg[5:1];
                            4'd6: RBR <= rx_shift_reg[6:1];
                            4'd7: RBR <= rx_shift_reg[7:1];
                            4'd8: RBR <= rx_shift_reg[8:1];
                        endcase
                    end
                end
                else begin
                    rx_baud_counter <= rx_baud_counter - 1;
                end
            end
        end
    end

    // LSR reg读写控制
    always_ff @(posedge apb_slave.PCLK) begin : lsr_reg
        if (~apb_slave.PRESETn) LSR <= 8'h60;  // 发射保持寄存器空，发送器空
        else if (apb_slave.PSEL && apb_slave.PENABLE && apb_slave.PREADY)
            if (apb_slave.PADDR[4:2] == 3'b000) begin
                if (apb_slave.PWRITE) begin
                    // 写操作
                    if (~DLAB) LSR[5] <= 1'b0;  // THR 非空
                end
                else begin
                    // 读操作
                    if (~DLAB) LSR[0] <= 1'b0;  // 数据已读
                end
            end

        if (baud_tick) begin
            if (tx_busy) begin
                if (tx_bit_cnt == (1 + data_bits_num + parity_enable + stop_bits_num - 1)) LSR[6] <= 1'b1;  // 发送器空
            end
        end
        else if (!tx_busy && !LSR[5]) begin
            LSR[5] <= 1'b1;  // THR 空
            LSR[6] <= 1'b0;  // 发送器非空
        end

        if (rx_baud_counter == 0) begin
            if (rx_bit_cnt == (4'd1 + 4'(data_bits_num) + 4'(parity_enable) + 4'(stop_bits_num) - 1)) begin
                LSR[0] <= 1'b1;  // 数据准备好
            end
        end
    end : lsr_reg
endmodule
