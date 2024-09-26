module apb4_mux #(
    parameter int unsigned NUM_SLAVES = 4,   // 可配置的从设备数量
    parameter int unsigned ADDR_WIDTH = 32,  // 地址总线宽度
    parameter int unsigned DATA_WIDTH = 32   // 数据总线宽度
) (
    // 主设备接口
    apb4_intf.slave  master_if,
    // 从设备接口数组
    apb4_intf.master slave_if [NUM_SLAVES]
);

    // 内部信号
    logic [        NUM_SLAVES-1:0] sel_decoded;
    logic [$clog2(NUM_SLAVES)-1:0] slave_sel;

    // 地址解码参数
    localparam int ADDR_BITS_USED = $clog2(NUM_SLAVES);

    // 地址解码逻辑
    always_comb begin
        slave_sel = master_if.PADDR[ADDR_WIDTH-1 -: ADDR_BITS_USED];
    end

    bin2onehot #(
        .ONEHOT_WIDTH(NUM_SLAVES)
    ) u_bin2onehot (
        .bin   (slave_sel),
        .onehot(sel_decoded)
    );

    // 将主设备信号连接到所有从设备
    for (genvar i = 0; i < NUM_SLAVES; i++) begin : slave_connect
        assign slave_if[i].PSEL    = sel_decoded[i] * master_if.PSEL;
        assign slave_if[i].PENABLE = master_if.PENABLE;
        assign slave_if[i].PWRITE  = master_if.PWRITE;
        assign slave_if[i].PADDR   = master_if.PADDR;
        assign slave_if[i].PWDATA  = master_if.PWDATA;
        assign slave_if[i].PSTRB   = master_if.PSTRB;
        assign slave_if[i].PPROT   = master_if.PPROT;
    end


    logic [DATA_WIDTH - 1:0] PRDATA_mux_t [NUM_SLAVES];
    logic                    PREADY_mux_t [NUM_SLAVES];
    logic                    PSLVERR_mux_t[NUM_SLAVES];
    logic [DATA_WIDTH - 1:0] PRDATA_mux;
    logic                    PREADY_mux;
    logic                    PSLVERR_mux;

    for (genvar i = 0; i < NUM_SLAVES; i++) begin
        assign PRDATA_mux_t[i]  = slave_if[i].PRDATA;
        assign PREADY_mux_t[i]  = slave_if[i].PREADY;
        assign PSLVERR_mux_t[i] = slave_if[i].PSLVERR;
    end

    recur_mux #(
        .WIDTH     (DATA_WIDTH),
        .NUM_INPUTS(NUM_SLAVES)
    ) mux_data (
        .data_i(PRDATA_mux_t),
        .sel_i (slave_sel),
        .data_o(PRDATA_mux)
    );

    recur_mux #(
        .WIDTH     (int'(1)),
        .NUM_INPUTS(NUM_SLAVES)
    ) mux_ready (
        .data_i(PREADY_mux_t),
        .sel_i (slave_sel),
        .data_o(PREADY_mux)
    );

    recur_mux #(
        .WIDTH     (int'(1)),
        .NUM_INPUTS(NUM_SLAVES)
    ) mux_slverr (
        .data_i(PSLVERR_mux_t),
        .sel_i (slave_sel),
        .data_o(PSLVERR_mux)
    );

    // 将从设备的响应信号连接回主设备
    assign master_if.PRDATA  = PRDATA_mux;
    assign master_if.PREADY  = PREADY_mux;
    assign master_if.PSLVERR = PSLVERR_mux;

endmodule
