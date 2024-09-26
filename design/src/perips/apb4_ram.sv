module apb4_ram #(
    parameter int unsigned ADDR_WIDTH  = 12,  // 地址宽度（表示支持的地址空间，例如 4KB）
    parameter int unsigned DATA_WIDTH  = 32,  // 数据宽度（通常为 32 位或 64 位）
    parameter string       MemInitFile = ""
) (
    // APB4 接口
    apb4_intf.slave apb_if
);
    localparam int unsigned Depth = (1 << (ADDR_WIDTH - $clog2(DATA_WIDTH / 8))) - 1;
    localparam int unsigned Width = DATA_WIDTH;
    // 内部 RAM 存储器
    logic [                     DATA_WIDTH-1:0] mem       [Depth];

    // 内部信号
    logic [                     ADDR_WIDTH-1:0] addr_reg;
    logic [ADDR_WIDTH-1 : $clog2(DATA_WIDTH/8)] word_addr;

    assign word_addr = addr_reg[ADDR_WIDTH-1 : $clog2(DATA_WIDTH/8)];
    // 地址寄存
    always_ff @(posedge apb_if.PCLK) begin
        if (~apb_if.PRESETn) begin
            addr_reg <= '0;
        end
        else begin
            if (apb_if.PSEL && !apb_if.PENABLE) begin
                // 在设置阶段，捕获地址和操作类型
                addr_reg <= apb_if.PADDR[ADDR_WIDTH-1:0];
            end
        end
    end

    // 写操作
    always_ff @(posedge apb_if.PCLK) begin
        if (apb_if.PWRITE && apb_if.PENABLE && apb_if.PREADY) begin
            // 检查地址是否在范围内
            if (word_addr < (1 << (ADDR_WIDTH - $clog2(DATA_WIDTH / 8)))) begin
                // 使用 PSTRB 信号进行字节选通写入
                for (int i = 0; i < DATA_WIDTH / 8; i++) begin
                    if (apb_if.PSTRB[i]) begin
                        mem[word_addr][i*8 +: 8] <= apb_if.PWDATA[i*8 +: 8];
                    end
                end
            end
            // 如果地址超出范围，可以选择忽略或产生错误
        end
    end

    // 读操作
    logic [DATA_WIDTH-1:0] data_out;
    always_ff @(posedge apb_if.PCLK) begin
        if (~apb_if.PWRITE && apb_if.PSEL) begin
            // 检查地址是否在范围内
            if (word_addr < (1 << (ADDR_WIDTH - $clog2(DATA_WIDTH / 8)))) begin
                apb_if.PRDATA <= mem[word_addr];
            end
            else begin
                apb_if.PRDATA <= '0;  // 超出范围，返回默认值
            end
        end
    end

    // PREADY 信号
    assign apb_if.PREADY  = 1'b1;  // RAM 访问速度快，无需等待

    // PSLVERR 信号
    assign apb_if.PSLVERR = 1'b0;  // 简单设计中，不产生错误信号

    `include "prim_memutil.svh"

endmodule
