module pwm
    import tinyriscv_pkg::*;
#(
    parameter int unsigned channel = 4
) (
    input clk_i,
    input rst_ni,

    input [31:0] data_i,
    input [31:0] addr_i,
    input        we_i,

    output logic [31:0] data_o,

    output logic [channel - 1:0] pwm_o
);

    logic [31:0] reg_A[channel];
    logic [31:0] reg_B[channel];
    logic [channel - 1:0] reg_en;
    logic [7:0] addr_inner;
    assign addr_inner = addr_i[16 +: 8];

    genvar i;
    generate
        for (i = 0; i < channel; i = i + 1) begin
            always_ff @(posedge clk_i) begin : regAfile
                if (~rst_ni) reg_A[i] <= '0;
                else if (we_i && addr_inner[4 +: 4] == 4'h0 && addr_inner[0 +: 4] == i) reg_A[i] <= data_i;
            end : regAfile
            always_ff @(posedge clk_i) begin : regBfile
                if (~rst_ni) reg_B[i] <= '0;
                else if (we_i && addr_inner[4 +: 4] == 4'h1 && addr_inner[0 +: 4] == i) reg_B[i] <= data_i;
            end : regBfile
        end
    endgenerate

    always_ff @(posedge clk_i) begin : reg_en_ctl
        if (~rst_ni) reg_en <= '0;
        else if (we_i && addr_inner[0 +: 4] == 4'h4) reg_en <= data_i;
    end : reg_en_ctl

    logic [31:0] cnt[channel];
    generate
        for (i = 0; i < channel; i = i + 1) begin
            always_ff @(posedge clk_i) begin : cnt_ctl
                if (~reg_en[i]) cnt[i] <= reg_A[i];
                else if (reg_en[i]) begin
                    if (|cnt[i]) cnt[i] <= cnt[i] - 1'b1;
                    else cnt[i] <= reg_A[i];
                end
            end : cnt_ctl
            always_ff @(posedge clk_i) begin : channel_ctl
                if (~reg_en[i]) pwm_o[i] <= '0;
                else if (reg_en[i]) begin
                    if (cnt[i] >= reg_B[i]) pwm_o[i] <= '0;
                    else pwm_o[i] <= '1;
                end
            end : channel_ctl
        end
    endgenerate
endmodule
