module xilinx_clk_rst_gen (  // Clock in ports
                             // Clock out ports
    output clk_out1,
    // Status and control signals
    input  reset,
    output locked,
    input  clk_in1
);
    // Input buffering
    //------------------------------------
    wire clk_in1_xilinx_clk_rst_gen;
    assign clk_in1_xilinx_clk_rst_gen = clk_in1;

    // Clocking PRIMITIVE
    //------------------------------------

    // Instantiation of the MMCM PRIMITIVE
    //    * Unused inputs are tied off
    //    * Unused outputs are labeled unused

    wire        clk_out1_xilinx_clk_rst_gen;
    wire        clk_out2_xilinx_clk_rst_gen;
    wire        clk_out3_xilinx_clk_rst_gen;
    wire        clk_out4_xilinx_clk_rst_gen;
    wire        clk_out5_xilinx_clk_rst_gen;
    wire        clk_out6_xilinx_clk_rst_gen;
    wire        clk_out7_xilinx_clk_rst_gen;

    wire [15:0] do_unused;
    wire        drdy_unused;
    wire        psdone_unused;
    wire        locked_int;
    wire        clkfbout_xilinx_clk_rst_gen;
    wire        clkfbout_buf_xilinx_clk_rst_gen;
    wire        clkfboutb_unused;
    wire        clkout1_unused;
    wire        clkout2_unused;
    wire        clkout3_unused;
    wire        clkout4_unused;
    wire        clkout5_unused;
    wire        clkout6_unused;
    wire        clkfbstopped_unused;
    wire        clkinstopped_unused;
    wire        reset_high;

    PLLE2_ADV #(
        .BANDWIDTH         ("OPTIMIZED"),
        .COMPENSATION      ("ZHOLD"),
        .STARTUP_WAIT      ("FALSE"),
        .DIVCLK_DIVIDE     (2),
        .CLKFBOUT_MULT     (2),
        .CLKFBOUT_PHASE    (0.000),
        .CLKOUT0_DIVIDE    (1),
        .CLKOUT0_PHASE     (0.000),
        .CLKOUT0_DUTY_CYCLE(0.500),
        .CLKIN1_PERIOD     (20.000)
    ) plle2_adv_inst
    // Output clocks
    (
        .CLKFBOUT(clkfbout_xilinx_clk_rst_gen),
        .CLKOUT0 (clk_out1_xilinx_clk_rst_gen),
        .CLKOUT1 (clkout1_unused),
        .CLKOUT2 (clkout2_unused),
        .CLKOUT3 (clkout3_unused),
        .CLKOUT4 (clkout4_unused),
        .CLKOUT5 (clkout5_unused),
        // Input clock control
        .CLKFBIN (clkfbout_buf_xilinx_clk_rst_gen),
        .CLKIN1  (clk_in1_xilinx_clk_rst_gen),
        .CLKIN2  (1'b0),
        // Tied to always select the primary input clock
        .CLKINSEL(1'b1),
        // Ports for dynamic reconfiguration
        .DADDR   (7'h0),
        .DCLK    (1'b0),
        .DEN     (1'b0),
        .DI      (16'h0),
        .DO      (do_unused),
        .DRDY    (drdy_unused),
        .DWE     (1'b0),
        // Other control and status signals
        .LOCKED  (locked_int),
        .PWRDWN  (1'b0),
        .RST     (reset_high)
    );
    assign reset_high = reset;

    assign locked     = locked_int;
    // Clock Monitor clock assigning
    //--------------------------------------
    // Output buffering
    //-----------------------------------

    BUFG clkf_buf (
        .O(clkfbout_buf_xilinx_clk_rst_gen),
        .I(clkfbout_xilinx_clk_rst_gen)
    );

    BUFG clkout1_buf (
        .O(clk_out1),
        .I(clk_out1_xilinx_clk_rst_gen)
    );
endmodule
