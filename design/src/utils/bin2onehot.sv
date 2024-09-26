module bin2onehot #(
    parameter int unsigned ONEHOT_WIDTH = 16,
    // Do Not Change
    parameter int unsigned BIN_WIDTH    = ONEHOT_WIDTH == 1 ? 1 : $clog2(ONEHOT_WIDTH)
) (
    input  logic [   BIN_WIDTH-1:0] bin,
    output logic [ONEHOT_WIDTH-1:0] onehot
);

    for (genvar i = 0; i < ONEHOT_WIDTH; i++) begin : gen_il
        assign onehot[i] = (bin == BIN_WIDTH'(i));
    end

`ifndef SYNTHESIS
`ifndef COMMON_CELLS_ASSERTS_OFF
    always_comb begin
        if (32'(bin) >= ONEHOT_WIDTH) begin
            $fatal(1, "[bin2onehot] Input 'bin' (%0d) exceeds the maximum value (%0d).", bin, ONEHOT_WIDTH - 1);
        end
    end
`endif
`endif

endmodule
