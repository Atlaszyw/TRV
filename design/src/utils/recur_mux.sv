module recur_mux #(
    parameter int unsigned WIDTH       = 8,
    parameter int unsigned NUM_INPUTS  = 8,
    parameter int unsigned HI          = NUM_INPUTS - 1,
    parameter int unsigned LO          = 0,
    parameter int unsigned SELECT_BITS = $clog2(NUM_INPUTS)
) (
    input  [      WIDTH-1:0] data_i[0:NUM_INPUTS-1],
    input  [SELECT_BITS-1:0] sel_i,
    output [      WIDTH-1:0] data_o
);


    generate
        if (HI == LO) begin : g_leaf
            // Leaf node: only one input, directly assign to output
            assign data_o = data_i[HI];
        end
        else begin : g_nonleaf
            logic [WIDTH-1:0] data_lo, data_hi;

            // Non-leaf node: split inputs and recursively instantiate sub-muxes
            localparam int MID = (HI + LO) >> 1;

            recur_mux #(
                .WIDTH     (WIDTH),
                .NUM_INPUTS(NUM_INPUTS),
                .HI        (MID),
                .LO        (LO)
            ) mux_lo (
                .data_i(data_i),
                .sel_i (sel_i),
                .data_o(data_lo)
            );

            recur_mux #(
                .WIDTH     (WIDTH),
                .NUM_INPUTS(NUM_INPUTS),
                .HI        (HI),
                .LO        (MID + 1)
            ) mux_hi (
                .data_i(data_i),
                .sel_i (sel_i),
                .data_o(data_hi)
            );

            // Select between lower and upper halves based on sel_i
            assign data_o = (32'(sel_i) <= MID) ? data_lo : data_hi;
        end
    endgenerate

endmodule
