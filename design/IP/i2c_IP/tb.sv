module tb;

    // Parameters
    parameter CLK_FREQ = 32'd50_000_000;
    parameter SCL_FREQ = 32'd400_000;
    parameter ADDR_75 = 7'b1001000;

    // Inputs
    reg clk_i;
    reg rst_ni;
    reg [31:0] data_i;
    reg [31:0] addr_i;
    reg we_i;
    reg req_i;

    // Outputs
    wire [31:0] data_o;
    wire ready_o;
    wire scl_o;
    wire sda_o;
    wire sda_t_o;
    wire sda_i;

    // Internal signals
    reg sda_i_reg;

    // Assignments
    assign sda_i = sda_i_reg;

    // Instantiate the I2C module
    i2c #(
        .CLK_FREQ(CLK_FREQ),
        .SCL_FREQ(SCL_FREQ),
        .ADDR_75 (ADDR_75)
    ) uut (
        .clk_i    (clk_i),
        .rst_ni   (rst_ni),
        .data_i   (data_i),
        .addr_i   (addr_i),
        .we_i     (we_i),
        .req_i    (req_i),
        .data_o   (data_o),
        .ready_o(ready_o),
        .scl_o    (scl_o),
        .sda_o    (sda_o),
        .sda_t_o  (sda_t_o),
        .sda_i    (sda_i)
    );

    // Generate clock
    initial begin
        clk_i = 0;
        forever #10 clk_i = ~clk_i;  // 50 MHz clock
    end

    // Stimulus
    initial begin
        // Initialize Inputs
        rst_ni    = 0;
        data_i    = 0;
        addr_i    = 0;
        we_i      = 0;
        req_i     = 0;
        sda_i_reg = 1;

        // Reset the system
        #100;
        rst_ni = 1;

        // Write address to reg_addr
        addr_i = 32'h00020000;  // Address for reg_addr
        we_i   = 0;
        req_i  = 1;
        #100;

        @(negedge sda_t_o) sda_i_reg = 0;
        #1280 sda_i_reg = 1;
        #1280 sda_i_reg = 0;
        #1280 sda_i_reg = 1;
        #1280 sda_i_reg = 0;
        #1280 sda_i_reg = 0;
        #1280 sda_i_reg = 1;
        #1280 sda_i_reg = 0;
        #1280 sda_i_reg = 1;
        #1280 sda_i_reg = 1;
        #1280 sda_i_reg = 0;
        #1280 sda_i_reg = 1;
        #1280 sda_i_reg = 0;
        #1280 sda_i_reg = 0;
        #1280 sda_i_reg = 1;
        #1280 sda_i_reg = 0;
        #1280 sda_i_reg = 1;
        #10000 $finish();
    end


endmodule
