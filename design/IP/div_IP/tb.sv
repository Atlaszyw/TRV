module tb;

    // Parameters
    localparam WIDTH = 32;

    // Inputs
    reg clk;
    reg reset;
    reg start;
    reg [WIDTH-1:0] dividend;
    reg [WIDTH-1:0] divisor;
    reg is_signed;

    // Outputs
    wire [WIDTH-1:0] quotient;
    wire [WIDTH-1:0] remainder;
    wire done;
    wire error;

    // Instantiate the Unit Under Test (UUT)
    TrialDivisionDivider #(WIDTH) uut (
        .clk      (clk),
        .reset    (reset),
        .start    (start),
        .dividend (dividend),
        .divisor  (divisor),
        .is_signed(is_signed),
        .quotient (quotient),
        .remainder(remainder),
        .done     (done),
        .error    (error)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test procedure
    initial begin
        // Initialize Inputs
        reset     = 1;
        start     = 0;
        dividend  = 0;
        divisor   = 0;
        is_signed = 0;

        // Reset the UUT
        #10;
        reset = 0;
        #10;
        reset = 1;
        #10;
        // Test unsigned division
        start     = 1;
        dividend  = 32'h00000014;  // 20
        divisor   = 32'h00000005;  // 5
        is_signed = 0;
        #10;
        start = 0;

        // Wait for calculation to complete
        wait (done);
        #9;
        $display("Unsigned Division: 20 / 5 = %d, remainder = %d", quotient, remainder);

        // Test signed division
        start     = 1;
        dividend  = 32'hFFFFFFEC;  // -20
        divisor   = 32'hFFFFFFFB;  // -5
        is_signed = 1;
        #10;
        start = 0;

        // Wait for calculation to complete
        wait (done);
        #9;
        $display("Signed Division: -20 / -5 = %d, remainder = %d", quotient, remainder);

        // Test signed division with mixed signs
        start     = 1;
        dividend  = 32'hFFFFFFEC;  // -20
        divisor   = 32'h00000005;  // 5
        is_signed = 1;
        #10;
        start = 0;

        // Wait for calculation to complete
        wait (done);
        #9;
        $display("Signed Division: -20 / 5 = %d, remainder = %d", quotient, remainder);

        // Test division by zero
        start     = 1;
        dividend  = 32'h00000014;  // 20
        divisor   = 32'h00000000;  // 0
        is_signed = 0;
        #10;
        start = 0;

        // Wait for calculation to complete
        wait (done);
        #9;
        $display("Division by Zero: 20 / 0 = %d, remainder = %d", quotient, remainder);

        // Finish simulation
        $finish;
    end

endmodule
