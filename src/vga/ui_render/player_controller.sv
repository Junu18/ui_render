// player_controller.sv
// 플레이어 이동 FSM (타일 기반 → 픽셀 위치 계산)

import color_pkg::*;

module player_controller #(
    parameter int TILE_SIZE      = 60,
    parameter int TILE_START_X   = 20,
    parameter int PLAYER_Y_BASE  = 124,
    parameter int STEP_PIXELS    = 2,
    parameter int FLAG_X         = 620,
    parameter int FLAG_TOP_Y     = 40,
    parameter int FLAG_SLIDE_Y   = PLAYER_Y_BASE
) (
    input  logic       clk,
    input  logic       reset_n,
    input  logic       move_start,      // 1-pulse to start moving
    input  logic [9:0] target_x,        // 목표 타일 인덱스 (0-base)
    output logic [9:0] player_x,
    output logic [9:0] player_y,
    output logic       turn_done        // 1-cycle pulse when movement ends
);

    typedef enum logic [1:0] {
        IDLE,
        WALKING,
        FLAG_SLIDING
    } state_t;

    state_t state_d, state_q;
    logic [9:0] x_d, x_q;
    logic [9:0] y_d, y_q;
    logic [9:0] target_pixel_d, target_pixel_q;
    logic       turn_pulse;
    logic [15:0] computed_target;

    // 타겟 픽셀 위치 (타일 인덱스를 픽셀로 변환)
    always_comb begin
        computed_target = TILE_START_X + (target_x * TILE_SIZE);
    end

    always_comb begin
        state_d        = state_q;
        x_d            = x_q;
        y_d            = y_q;
        target_pixel_d = target_pixel_q;
        turn_pulse     = 1'b0;

        case (state_q)
            IDLE: begin
                y_d = PLAYER_Y_BASE;
                if (move_start) begin
                    target_pixel_d = computed_target[9:0];

                    if (computed_target[9:0] == FLAG_X) begin
                        // 깃발 → 슬라이딩 애니메이션
                        state_d = FLAG_SLIDING;
                        x_d     = FLAG_X;
                        y_d     = FLAG_TOP_Y;
                    end else if (computed_target[9:0] == x_q) begin
                        // 이미 해당 위치 → 즉시 턴 종료
                        turn_pulse = 1'b1;
                    end else begin
                        state_d = WALKING;
                    end
                end
            end

            WALKING: begin
                if (x_q < target_pixel_q) begin
                    if ((x_q + STEP_PIXELS) >= target_pixel_q) begin
                        x_d    = target_pixel_q;
                        state_d = IDLE;
                        turn_pulse = 1'b1;
                    end else begin
                        x_d = x_q + STEP_PIXELS;
                    end
                end else if (x_q > target_pixel_q) begin
                    if (x_q <= target_pixel_q + STEP_PIXELS) begin
                        x_d    = target_pixel_q;
                        state_d = IDLE;
                        turn_pulse = 1'b1;
                    end else begin
                        x_d = x_q - STEP_PIXELS;
                    end
                end else begin
                    state_d = IDLE;
                    turn_pulse = 1'b1;
                end
            end

            FLAG_SLIDING: begin
                if (y_q + STEP_PIXELS >= FLAG_SLIDE_Y) begin
                    y_d        = FLAG_SLIDE_Y;
                    state_d    = IDLE;
                    turn_pulse = 1'b1;
                end else begin
                    y_d = y_q + STEP_PIXELS;
                end
            end

            default: begin
                state_d = IDLE;
            end
        endcase
    end

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state_q        <= IDLE;
            x_q            <= TILE_START_X[9:0];
            y_q            <= PLAYER_Y_BASE[9:0];
            target_pixel_q <= TILE_START_X[9:0];
            turn_done      <= 1'b0;
        end else begin
            state_q        <= state_d;
            x_q            <= x_d;
            y_q            <= y_d;
            target_pixel_q <= target_pixel_d;
            turn_done      <= turn_pulse;
        end
    end

    assign player_x = x_q;
    assign player_y = y_q;

endmodule
