
module eu_priority_index #(
    parameter int unsigned SOURCES    = 6,
    parameter int unsigned PRIORITIES = 8,
    parameter int unsigned HI         = 5,  //the default value, the max of array index is (SOURCE-1)
    parameter int unsigned LO         = 0,

    parameter int unsigned SOURCES_BITS  = $clog2(SOURCES + 1),
    parameter int unsigned PRIORITY_BITS = $clog2(PRIORITIES)
) (
    input  [PRIORITY_BITS-1:0] priority_i[SOURCES],
    input  [SOURCES_BITS -1:0] idx_i     [SOURCES],
    output [PRIORITY_BITS-1:0] priority_o,
    output [SOURCES_BITS -1:0] idx_o
);

    logic [PRIORITY_BITS-1:0] priority_hi, priority_lo;
    logic [SOURCES_BITS -1:0] idx_hi, idx_lo;  //the array index, equal to (ID-1)

    generate
        if (HI - LO > 1) begin : g_No_leaf
            eu_priority_index #(
                .SOURCES   (SOURCES),
                .PRIORITIES(PRIORITIES),
                .HI        (LO + (HI - LO) / 2),
                .LO        (LO)
            ) lo (
                .priority_i(priority_i),
                .idx_i     (idx_i),
                .priority_o(priority_lo),
                .idx_o     (idx_lo)
            );

            eu_priority_index #(
                .SOURCES   (SOURCES),
                .PRIORITIES(PRIORITIES),
                .HI        (HI),
                .LO        (HI - (HI - LO) / 2)
            ) hi (
                .priority_i(priority_i),
                .idx_i     (idx_i),
                .priority_o(priority_hi),
                .idx_o     (idx_hi)
            );
        end : g_No_leaf
        else  //the leaf node of tree, HI=LO+1 or HI=LO

        begin : g_leaf
            assign priority_lo = priority_i[LO];
            assign priority_hi = priority_i[HI];
            assign idx_lo      = idx_i[LO];
            assign idx_hi      = idx_i[HI];
        end : g_leaf
    endgenerate

    //the last time compare
    assign priority_o = priority_hi > priority_lo ? priority_hi : priority_lo;
    assign idx_o      = priority_hi > priority_lo ? idx_hi : idx_lo;

endmodule : eu_priority_index
