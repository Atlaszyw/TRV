module lm75_controller (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [6:0] i2c_addr,     // I2C address of the LM75
    output logic       scl,
    inout  logic       sda,
    output logic [8:0] temperature,  // 9-bit temperature output
    output logic       os            // Overtemperature shutdown signal
);

    typedef enum logic [2:0] {
        IDLE,
        START,
        ADDR,
        READ,
        STOP
    } state_t;

    state_t state, next_state;

    logic scl_en, sda_en;
    logic scl_out, sda_out;
    logic scl_in, sda_in;
    logic [ 7:0] bit_count;
    logic [15:0] temp_data;
    logic [15:0] clk_count;

    // I2C timing constants (assuming a clock period of 10 ns for 100 MHz clock)
    localparam tHD_STA = 100;  // Hold time START condition (100 ns)
    localparam tSU_STA = 100;  // Setup time START condition (100 ns)
    localparam tLOW = 2500;  // Clock low period (2500 ns)
    localparam tHIGH = 2500;  // Clock high period (2500 ns)
    localparam tSU_DAT = 100;  // Data setup time (100 ns)
    localparam tHD_DAT = 0;  // Data hold time (0 ns)
    localparam tSU_STO = 100;  // Setup time STOP condition (100 ns)
    localparam tBUF = 2500;  // Bus free time (2500 ns)

    // Assign I2C lines
    assign scl    = scl_en ? scl_out : 1'bz;
    assign sda    = sda_en ? sda_out : 1'bz;
    assign scl_in = scl;
    assign sda_in = sda;

    // Control signals for I2C timing
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            bit_count <= 0;
            temp_data <= 0;
            clk_count <= 0;
        end
        else begin
            state <= next_state;
            if (state == ADDR || state == READ) begin
                bit_count <= bit_count + 1;
            end
            else begin
                bit_count <= 0;
            end
            clk_count <= clk_count + 1;
        end
    end

    // State transition logic
    always_comb begin
        next_state = state;
        scl_en     = 1'b0;
        sda_en     = 1'b0;
        scl_out    = 1'b1;
        sda_out    = 1'b1;

        case (state)
            IDLE: begin
                if (start_condition) begin
                    next_state = START;
                    scl_en     = 1'b1;
                    sda_en     = 1'b1;
                    sda_out    = 1'b0;  // Start condition
                    clk_count  = 0;
                end
            end

            START: begin
                scl_en  = 1'b1;
                sda_en  = 1'b1;
                sda_out = 1'b0;  // Continue holding SDA low
                if (clk_count >= tHD_STA) begin
                    next_state = ADDR;
                    clk_count  = 0;
                end
            end

            ADDR: begin
                scl_en = 1'b1;
                if (bit_count < 7) begin
                    sda_en  = 1'b1;
                    sda_out = i2c_addr[6 - bit_count];  // Send address bits
                end
                else if (bit_count == 7) begin
                    sda_en  = 1'b1;
                    sda_out = 1'b1;  // Read operation
                end
                else if (clk_count >= tHIGH + tLOW) begin
                    next_state = READ;
                    sda_en     = 1'b0;  // Release SDA for ACK
                    clk_count  = 0;
                end
            end

            READ: begin
                scl_en = 1'b1;
                sda_en = 1'b0;  // SDA in input mode
                if (bit_count < 16) begin
                    if (clk_count >= tHIGH + tLOW) begin
                        temp_data[15 - bit_count] = sda_in;  // Read temperature bits
                        clk_count                 = 0;
                    end
                end
                else begin
                    next_state = STOP;
                    clk_count  = 0;
                end
            end

            STOP: begin
                scl_en  = 1'b1;
                sda_en  = 1'b1;
                sda_out = 1'b0;  // Stop condition
                if (clk_count >= tSU_STO) begin
                    next_state = IDLE;
                    clk_count  = 0;
                end
            end
        endcase
    end

    // Temperature output assignment
    assign temperature = temp_data[15:7];

    // OS signal handling
    assign os          = (temperature > TOS) ? 1'b1 : 1'b0;

endmodule
