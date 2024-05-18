`timescale 1ns / 1ps

module tb;
    parameter int unsigned CHANNEL = 4;

    // Inputs
    reg clk_i;
    reg rst_ni;
    reg [31:0] data_i;
    reg [31:0] addr_i;
    reg we_i;

    // Outputs
    wire [31:0] data_o;
    wire [CHANNEL - 1:0] pwm_o;

    // Instantiate the PWM module
    design #(
        .channel(CHANNEL)
    ) uut (
        .clk_i (clk_i),
        .rst_ni(rst_ni),
        .data_i(data_i),
        .addr_i(addr_i),
        .we_i  (we_i),
        .data_o(data_o),
        .pwm_o (pwm_o)
    );

    // Clock generation
    always #5 clk_i = ~clk_i;  // 100 MHz Clock

    // Initial Setup and Reset Process
    initial begin
        // Initialize Inputs
        clk_i  = 0;
        rst_ni = 0;
        data_i = 0;
        addr_i = 0;
        we_i   = 0;

        // Apply Reset
        #100;
        rst_ni = 1;
        #100;

        // Deassert Reset
        rst_ni = 1;
        #100;

        // Test write operations
        for (int i = 0; i < CHANNEL; i++) begin
            // Set reg_A[i]
            addr_i = (32'h0000_0000 + (i << 16));  // Address for reg_A[i]
            data_i = 32'h0000_0020 + i;  // Some test data
            @(posedge clk_i)
            we_i   = 1;
            @(posedge clk_i)
            we_i   = 0;
            // Set reg_B[i]
            addr_i = (32'h0010_0000 + (i << 16));  // Address for reg_B[i]
            data_i = 32'h0000_0005 + i;  // Some test data
            @(posedge clk_i)
            we_i   = 1;
            @(posedge clk_i)
            we_i   = 0;

            // Enable the PWM channel
            addr_i = 32'h0020_0000;  // Address to enable all channels
            data_i = (1 << i);  // Enable specific channel
            @(posedge clk_i)
            we_i   = 1;
            @(posedge clk_i)
            we_i   = 0;
            #5000;
        end

        // Test complete
        $display("Simulation finished");
        $finish;
    end
endmodule
