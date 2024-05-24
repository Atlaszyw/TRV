module tb;

    // Clock and reset signals
    reg clk_i;
    reg rst_ni;

    // Control and data signals
    reg we_i;
    reg req_i;
    reg [31:0] addr_i;
    reg [31:0] data_i;
    wire [31:0] data_o;
    wire ready_o;
    wire tx_pin;
    reg rx_pin;

    // Instantiate the UART module
    uart uut (
        .clk_i  (clk_i),
        .rst_ni (rst_ni),
        .we_i   (we_i),
        .req_i  (req_i),
        .addr_i (addr_i),
        .data_i (data_i),
        .data_o (data_o),
        .ready_o(ready_o),
        .tx_pin (tx_pin),
        .rx_pin (rx_pin)
    );

    // Clock generation
    initial begin
        clk_i = 0;
        forever #10 clk_i = ~clk_i;  // 50MHz clock
    end

    // Test sequence
    initial begin
        // Initialize signals
        rst_ni = 0;
        we_i   = 0;
        req_i  = 0;
        addr_i = 0;
        data_i = 0;
        rx_pin = 1;

        // Release reset
        #100;
        rst_ni = 1;

        // Enable TX and RX
        #50;
        req_i  = 1;
        we_i   = 1;
        addr_i = 32'h00;
        data_i = 32'b11;  // Enable both TX and RX
        #20;
        req_i = 0;
        we_i  = 0;

        // Transmit data
        #50;
        req_i  = 1;
        we_i   = 1;
        addr_i = 32'h0C;
        data_i = 8'hA5;  // Transmit 0xA5
        #20;
        req_i = 0;
        we_i  = 0;

        // Wait for transmission to complete
        #500;

        // Simulate receiving data
        rx_pin = 0;  // Start bit
        #8680;  // Baud rate delay (1 bit period at 115200 bps)
        rx_pin = 1;  // Bit 0
        #8680;
        rx_pin = 0;  // Bit 1
        #8680;
        rx_pin = 1;  // Bit 2
        #8680;
        rx_pin = 0;  // Bit 3
        #8680;
        rx_pin = 1;  // Bit 4
        #8680;
        rx_pin = 0;  // Bit 5
        #8680;
        rx_pin = 1;  // Bit 6
        #8680;
        rx_pin = 0;  // Bit 7
        #8680;
        rx_pin = 1;  // Stop bit
        #8680;

        // Wait for RX completion
        #100;

        // Read received data
        req_i  = 1;
        we_i   = 0;
        addr_i = 32'h10;  // Address of RX data register
        // Check received data
        #20;
        if (data_o == 8'hAA) begin
            $display("Test Passed: Received data matches transmitted data.");
        end
        else begin
            $display("Test Failed: Received data does not match transmitted data.");
        end
        #20;
        req_i = 0;
        // End simulation
        // Enable TX and RX
        #50;
        req_i  = 1;
        we_i   = 1;
        addr_i = 32'h14;

        #20;
        req_i = 0;
        we_i  = 0;

    end

endmodule
