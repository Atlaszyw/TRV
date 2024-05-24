module Radix8BoothMultiplier (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,
    input  logic [31:0] multiplicand,
    input  logic [31:0] multiplier,
    output logic [63:0] product,
    output logic        done
);

    typedef enum logic [1:0] {
        IDLE = 2'b00,
        CALC = 2'b01,
        DONE = 2'b10
    } state_t;

    state_t state, next_state;

    logic [35:0] booth_multiplicand;
    logic [35:0] booth_multiplier;
    logic [ 5:0] count;
    logic [63:0] partial_sum;
    logic [35:0] booth_op;
    logic [63:0] pipeline_reg1;
    logic [63:0] pipeline_reg2;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count              <= 0;
            booth_multiplicand <= 0;
            booth_multiplier   <= 0;
            partial_sum        <= 0;
            product            <= 0;
            done               <= 0;
            pipeline_reg1      <= 0;
            pipeline_reg2      <= 0;
        end
        else if (state == IDLE && start) begin
            count              <= 0;
            booth_multiplicand <= {multiplicand, 4'b0};
            booth_multiplier   <= {3'b0, multiplier, 1'b0};
            partial_sum        <= 0;
            product            <= 0;
            done               <= 0;
            pipeline_reg1      <= 0;
            pipeline_reg2      <= 0;
        end
        else if (state == CALC) begin
            // Pipeline stage 1: Booth operation calculation
            case (booth_multiplier[2:0])
                3'b000, 3'b111: booth_op = 0;
                3'b001, 3'b010: booth_op = booth_multiplicand;
                3'b011:         booth_op = booth_multiplicand << 1;
                3'b100:         booth_op = ~(booth_multiplicand << 1) + 1;
                3'b101, 3'b110: booth_op = ~booth_multiplicand + 1;
                default:        booth_op = 0;
            endcase
            pipeline_reg1    <= (booth_op << count);
            booth_multiplier <= booth_multiplier >> 3;

            // Pipeline stage 2: Partial sum update
            pipeline_reg2    <= pipeline_reg1;
            partial_sum      <= partial_sum + pipeline_reg2;

            count            <= count + 3;

            if (count >= 36) begin
                product <= partial_sum;
                done    <= 1;
            end
        end
    end

    always_comb begin
        case (state)
            IDLE:    next_state = (start) ? CALC : IDLE;
            CALC:    next_state = (count >= 36) ? DONE : CALC;
            DONE:    next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

endmodule
