module Radix4BoothMultiplier
    import tinyriscv_pkg::*;
#(
    parameter WIDTH = 32
) (
    input  logic             clk_i,
    input  logic             rst_ni,
    input  logic             valid_i,
    input  logic [WIDTH-1:0] multiplicand_i,
    input  logic [WIDTH-1:0] multiplier_i,
    input        [      2:0] op_i,
    output logic [WIDTH-1:0] data_o,
    output logic             ready_o,
    output logic             error_o          // 新增的输出信号，用于指示除数为零的错误情况
);

    typedef enum logic [1:0] {
        IDLE,
        CALC,
        DONE
    } state_t;

    state_t state, next_state;

    logic [WIDTH * 2 + 1:0] mulbuffer;
    logic [5:0] count;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end

    always_comb begin : booth_4_logic
        case (booth_multiplier[2:0])
            3'b000, 3'b111: booth_op = 0;
            3'b001, 3'b010: booth_op = booth_multiplicand;
            3'b011:         booth_op = booth_multiplicand << 1;
            3'b100:         booth_op = ~(booth_multiplicand << 1) + 1;
            3'b101, 3'b110: booth_op = ~booth_multiplicand + 1;
            default:        booth_op = 0;
        endcase
    end : booth_4_logic

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
        end
        else if (state == IDLE && start) begin
            count <= 0;
        end
        else if (state == CALC) begin
            // Pipeline stage 1: Booth operation calculation

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
