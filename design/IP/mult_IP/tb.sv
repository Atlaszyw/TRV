`timescale 1ns / 1ps

module tb;

    // Inputs to the module
    reg clk;
    reg rst_n;
    reg is_signed;
    reg [31:0] multiplicand;
    reg [31:0] multiplier;

    // Outputs from the module
    wire [63:0] product;
    wire ready;

    // Instantiate the BoothMultiplierPipelined module
    BoothMultiplierPipelined uut (
        .clk         (clk),
        .rst_n       (rst_n),
        .is_signed   (is_signed),
        .multiplicand(multiplicand),
        .multiplier  (multiplier),
        .product     (product),
        .ready       (ready)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = !clk;  // Clock with a period of 10 ns
    end

    // Stimulus and response checking
    initial begin
        // Initialize Inputs
        rst_n        = 0;
        is_signed    = 0;
        multiplicand = 0;
        multiplier   = 0;

        // Reset the system
        #10;
        rst_n = 1;

        // Test Case 1: Unsigned Multiplication
        #10;
        is_signed    = 0;  // Unsigned operation
        multiplicand = 32'h0000FFFF;  // 65535
        multiplier   = 32'h00000002;  // 2
        #100;  // Wait for the operation to complete
        assert (product == 64'h000000000001FFFE)
        else $error("Test Case 1 Failed");

        // Test Case 2: Signed Multiplication
        #10;
        is_signed    = 1;  // Signed operation
        multiplicand = 32'hFFFF0001;  // -65535 in two's complement
        multiplier   = 32'h00000002;  // 2
        #100;  // Wait for the operation to complete
        assert (product == 64'hFFFFFFFFFFFF0002)
        else $error("Test Case 2 Failed");

        // Test Case 3: Multiplying by Zero
        #10;
        multiplicand = 32'hABCDEF01;  // Arbitrary number
        multiplier   = 0;  // Zero
        #100;  // Wait for the operation to complete
        assert (product == 0)
        else $error("Test Case 3 Failed");

        // Test Case 4: Maximum positive product
        #10;
        multiplicand = 32'h7FFFFFFF;  // Largest 32-bit positive integer
        multiplier   = 32'h00000002;  // 2
        #100;  // Wait for the operation to complete
        assert (product == 64'h00000000FFFFFFFE)
        else $error("Test Case 4 Failed");

        // Test Case 5: Overflow test (signed)
        #10;
        is_signed    = 1;  // Signed operation
        multiplicand = 32'h80000000;  // Smallest 32-bit integer
        multiplier   = 32'hFFFFFFFF;  // -1 in two's complement
        #100;  // Wait for the operation to complete
        assert (product == 64'h0000000080000000)
        else $error("Test Case 5 Failed");

        // Complete simulation
        #10;
        $finish;
    end

endmodule
