`timescale 1ns/1ps

module tb;

    // Inputs
    reg sys_clk;
    reg rst_n;

    // Bidirectional
    wire scl;
    wire sda;

    // Outputs
    wire [16:0] data;

    // Instantiate the Unit Under Test (UUT)
    i2c_read_lm75 uut (
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .scl(scl),
        .sda(sda),
        .data(data)
    );

    // Clock generation
    always #10 sys_clk = ~sys_clk;  // 100 MHz clock

    // I2C SDA signal emulation
    reg sda_r;
    assign sda = sda_r ? 1'bz : 1'b0;

    initial begin
        // Initialize Inputs
        sys_clk = 0;
        rst_n = 0;
        sda_r = 1;  // SDA line idle high

        // Wait for global reset to finish
        #100;
        rst_n = 1;

        // Emulate the I2C device responses
        // Start condition
        @(negedge sda);  // wait for start condition
        @(negedge scl);  // wait for clock low
#80000;
        // // Device address + read bit (1001_0001)
        // // send_byte(8'b1001_0001);

        // // ACK bit
        // @(negedge scl);
        // sda_r = 0;  // acknowledge

        // // Data byte 1 (temperature MSB)
        // @(negedge scl);
        // send_byte(8'b0000_1101);  // example data: 0x0D

        // // ACK bit
        // @(negedge scl);
        // sda_r = 0;  // acknowledge

        // // Data byte 2 (temperature LSB)
        // @(negedge scl);
        // send_byte(8'b1001_1010);  // example data: 0x9A

        // // NACK bit
        // @(negedge scl);
        // sda_r = 1;  // not acknowledge

        // // Stop condition
        // @(posedge scl);
        // @(posedge sda);

        // // Allow some time for processing
        // #200;

        // // Finish simulation
        $stop;
    end

    // task send_byte
    //     (input logic [7:0] byte,
    //     integer i)
    //     begin
    //         for (i = 7; i >= 0; i = i - 1) begin
    //             @(negedge scl);
    //             sda_r = byte[i];
    //             @(posedge scl);
    //         end
    //         @(negedge scl);
    //         sda_r = 1;  // release SDA for ACK/NACK
    //         @(posedge scl);
    //     end
    // endtask

endmodule
