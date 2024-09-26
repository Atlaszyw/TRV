module gpio_apb4
    import tinyriscv_pkg::*;
#(
    parameter  int unsigned GPIO_NUM  = 16,
    localparam int unsigned GPIO_NUM_ = GPIO_NUM > MemBus ? MemBus : GPIO_NUM
) (

    apb4_intf.slave apb_slv,

    input        [    GPIO_NUM_ - 1:0] io_pin_i,
    output logic [GPIO_NUM_ * 2 - 1:0] reg_ctrl,
    output logic [    GPIO_NUM_ - 1:0] io_pin_o
);

    // GPIO控制寄存器
    localparam GPIO_CTRL = 4'h0;
    // GPIO数据寄存器
    localparam GPIO_DATA = 4'h4;

    // 每2位控制1个IO的模式，最多支持16个IO
    // 0: 高阻，1：输出，2：输入
    logic [GPIO_NUM_ * 2 - 1:0] gpio_ctrl;
    // 输入输出数据
    logic [MemBus - 1:0] gpio_data;

    assign reg_ctrl = gpio_ctrl;
    assign io_pin_o = gpio_data;
    assign PREADY   = 1'b1;  // GPIO模块在APB事务中始终准备好
    assign PSLVERR  = 1'b0;  // 默认没有错误

    genvar i;
    generate
        for (i = 0; i < GPIO_NUM_; i = i + 1) begin
            always_ff @(posedge apb_slv.PCLK) begin
                if (~apb_slv.PRESETn) gpio_data[i] <= '0;
                else if (apb_slv.PSEL && apb_slv.PENABLE && apb_slv.PWRITE && apb_slv.PADDR[3:0] == GPIO_DATA &&
                         gpio_ctrl[2 * i+:2] == 2'b01)
                    gpio_data[i] <= apb_slv.PWDATA[i];
                else if (gpio_ctrl[2 * i+:2] == 2'b10) gpio_data[i] <= io_pin_i[i];
            end
        end

        for (i = GPIO_NUM_; i < MemBus; i = i + 1)
        always_ff @(posedge apb_slv.PCLK) begin : others
            gpio_data[i] <= '0;
        end : others
    endgenerate

    // 写寄存器
    always_ff @(posedge apb_slv.PCLK) begin
        if (~apb_slv.PRESETn) begin
            gpio_ctrl <= 32'h0;
        end
        else if (apb_slv.PSEL && apb_slv.PENABLE && apb_slv.PWRITE && apb_slv.PADDR[3:0] == GPIO_CTRL) begin
            gpio_ctrl <= apb_slv.PWDATA;
        end
    end

    // 读寄存器
    always_ff @(posedge apb_slv.PCLK) begin
        if (~apb_slv.PRESETn) apb_slv.PRDATA <= '0;
        else begin
            case (apb_slv.PADDR[3:0])
                GPIO_CTRL: apb_slv.PRDATA <= gpio_ctrl;
                GPIO_DATA: apb_slv.PRDATA <= gpio_data;
                default:   apb_slv.PRDATA <= '0;
            endcase
        end
    end

endmodule
