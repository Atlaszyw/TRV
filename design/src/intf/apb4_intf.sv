interface apb4_intf #(
    parameter int unsigned ADDR_WIDTH = 32,
                           DATA_WIDTH = 32
) (
    input logic PCLK,
    input logic PRESETn
);

    // APB4 interface signals with configurable widths
    logic                      PSEL;  // Peripheral select
    logic                      PENABLE;  // Enable
    logic                      PWRITE;  // Write enable (1 for write, 0 for read)
    logic [    ADDR_WIDTH-1:0] PADDR;  // Address bus (configurable width)
    logic [    DATA_WIDTH-1:0] PWDATA;  // Write data bus (configurable width)
    logic [    DATA_WIDTH-1:0] PRDATA;  // Read data bus (configurable width)
    logic [(DATA_WIDTH/8)-1:0] PSTRB;  // Byte strobe (1 bit for each byte)
    logic [               2:0] PPROT;  // Protection signal (privilege and security level)
    logic                      PREADY;  // Ready signal (high when transfer completes)
    logic                      PSLVERR;  // Slave error signal (high if an error occurred)

    // Master modport: controls write, read, and enables signals
    modport master(output PSEL, PENABLE, PWRITE, PADDR, PWDATA, PSTRB, PPROT, input PCLK, PRESETn, PREADY, PRDATA, PSLVERR);

    // Slave modport: responds to signals from master
    modport slave(input PCLK, PRESETn, PSEL, PENABLE, PWRITE, PADDR, PWDATA, PSTRB, PPROT, output PREADY, PRDATA, PSLVERR);

    // APB Master task for driving read/write transactions
    // task automatic apb_write(input logic [ADDR_WIDTH-1:0] addr, input logic [DATA_WIDTH-1:0] data,
    //                          input logic [(DATA_WIDTH/8)-1:0] strb);
    //     PSEL    = 1'b1;
    //     PWRITE  = 1'b1;
    //     PADDR   = addr;
    //     PWDATA  = data;
    //     PSTRB   = strb;
    //     PENABLE = 1'b0;

    //     @(posedge PCLK);
    //     PENABLE = 1'b1;

    //     @(posedge PCLK);
    //     while (!PREADY) @(posedge PCLK);

    //     PENABLE = 1'b0;
    //     PSEL    = 1'b0;
    // endtask

    // task automatic apb_read(input logic [ADDR_WIDTH-1:0] addr, output logic [DATA_WIDTH-1:0] data);
    //     PSEL    = 1'b1;
    //     PWRITE  = 1'b0;
    //     PADDR   = addr;
    //     PENABLE = 1'b0;

    //     @(posedge PCLK);
    //     PENABLE = 1'b1;

    //     @(posedge PCLK);
    //     while (!PREADY) @(posedge PCLK);

    //     data    = PRDATA;

    //     PENABLE = 1'b0;
    //     PSEL    = 1'b0;
    // endtask
endinterface
