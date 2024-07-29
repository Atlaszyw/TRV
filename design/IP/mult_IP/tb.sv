module tb;
    reg clk;
    reg reset;
    reg start;
    reg signed [33:0] multiplicand;
    reg signed [33:0] multiplier;
    wire signed [67:0] result;
    wire ready;

    // Instantiate the booth_radix4_multiplier_34bit module
    booth_radix4_multiplier_34bit uut (
        .clk_i                 (clk),
        .rst_ni                (~reset),
        .valid_i               (start),
        .op_i                  (3'b000),
        .multiplicand_i        (multiplicand),
        .multiplier_i          (multiplier),
        .result_o              (result),
        .ready_o               (ready)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Initialize inputs
        clk          = 0;
        reset        = 0;
        start        = 0;
        multiplicand = 0;
        multiplier   = 0;

        // Reset the design
        #10 reset = 1;
        #10 reset = 0;

        // Test case 1
        multiplicand = 32'd10;
        multiplier   = 32'd10;
        start        = 1;

        // Wait for the result
        wait (ready);
        $display("Test Case 1 %d * %d = %d", multiplicand, multiplier, result);

        // Test case 2
        multiplicand = -34'd654321;
        multiplier   = 34'd123;
        start        = 1;
        #10 start = 0;

        // Wait for the result
        wait (ready);
        $display("Test Case 2: %d * %d = %d", multiplicand, multiplier, result);

        // Test case 3
        multiplicand = 34'd0;
        multiplier   = 34'd123456;
        start        = 1;
        #10 start = 0;

        // Wait for the result
        wait (ready);
        $display("Test Case 3: %d * %d = %d", multiplicand, multiplier, result);

        // Test case 4
        multiplicand = -34'd1;
        multiplier   = -34'd1;
        start        = 1;
        #10 start = 0;

        // Wait for the result
        wait (ready);
        $display("Test Case 4: %d * %d = %d", multiplicand, multiplier, result);

        // Test case 5
        multiplicand = 34'd100000;
        multiplier   = -34'd1000;
        start        = 1;
        #10 start = 0;

        // Wait for the result
        wait (ready);
        $display("Test Case 5: %d * %d = %d", multiplicand, multiplier, result);

        $stop;
    end
endmodule
