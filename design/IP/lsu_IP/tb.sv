`timescale 1ns / 1ps

module lsu_tb;

    // Clock and reset signals
    logic clk_i;
    logic rst_ni;

    // Generate clock (period = 20ns)
    initial clk_i = 0;
    always #10 clk_i = ~clk_i;

    // Generate reset (active low)
    initial begin
        rst_ni = 1;  // Release reset
        #25;  // Hold reset low for 25ns
        rst_ni = 0;
        #25;  // Hold reset low for 25ns
        rst_ni = 1;  // Release reset
    end

    // DUT interface signals
    logic        req_valid;
    logic        req_ready;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic [ 1:0] bytelen;
    logic        ls;  // 0: load, 1: store

    // APB interface signals
    apb4_intf apb_if (
        clk_i,
        rst_ni
    );

    // Instantiate the lsu module (Device Under Test)
    lsu dut (
        .req_valid(req_valid),
        .req_ready(req_ready),
        .addr     (addr),
        .wdata    (wdata),
        .rdata    (rdata),
        .bytelen  (bytelen),
        .ls       (ls),
        .apb_mst  (apb_if)
    );

    // APB Slave behavior
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            apb_if.PREADY  <= 1'b0;
            apb_if.PRDATA  <= 32'hdead_beef;
            apb_if.PSLVERR <= 1'b0;
        end
        else begin
            if (apb_if.PREADY == 1'b1) begin
                apb_if.PREADY <= 1'b0;
            end
            else if (apb_if.PSEL && apb_if.PENABLE) begin
                apb_if.PREADY <= 1'b1;
                if (apb_if.PWRITE) begin
                    // Handle write operation (display written data)
                    $display("[%0t ns] APB WRITE: Address=0x%08h, Data=0x%08h, Strb=0b%04b", $time, apb_if.PADDR,
                             apb_if.PWDATA, apb_if.PSTRB);
                end
                else begin
                    // Handle read operation (provide dummy data)
                    apb_if.PRDATA <= 32'hA5A5A5A5;
                    $display("[%0t ns] APB READ: Address=0x%08h, Data=0x%08h", $time, apb_if.PADDR, apb_if.PRDATA);
                end
            end
            else apb_if.PREADY <= 1'b0;
        end
    end

    // Testbench stimulus
    initial begin
        // Initialize input signals
        req_valid = 1'b0;
        addr      = 32'h0;
        wdata     = 32'h0;
        bytelen   = 2'b10;  // Word length by default
        ls        = 1'b0;  // Load operation

        // Wait for reset de-assertion
        @(posedge rst_ni);
        @(posedge clk_i);
        #1;
        // Perform a load operation
        $display("[%0t ns] Starting Load Operation...", $time);
        addr      = 32'h0000_0004;
        ls        = 1'b0;  // Load
        bytelen   = 2'b10;  // Word
        req_valid = 1'b1;
        @(posedge clk_i);
        #1;

        // Wait until the request is accepted
        wait (req_ready);
        @(posedge clk_i);
        #1;
        req_valid = 1'b0;

        // Wait for the operation to complete
        @(posedge clk_i);
        #1;
        $display("[%0t ns] Load Completed: Data Read = 0x%08h", $time, rdata);

        // Perform a store operation
        $display("[%0t ns] Starting Store Operation...", $time);
        addr      = 32'h0000_0008;
        wdata     = 32'hDEADBEEF;
        ls        = 1'b1;  // Store
        bytelen   = 2'b10;  // Word
        req_valid = 1'b1;
        @(posedge clk_i);

        #1;
        // Wait until the request is accepted
        wait (req_ready);
        @(posedge clk_i);
        #1;
        req_valid = 1'b0;

        // Wait for the operation to complete
        @(posedge clk_i);
        $display("[%0t ns] Store Completed: Data Written = 0x%08h", $time, wdata);

        // Finish simulation
        #50;
        $finish;
    end

endmodule
