// player_controller.sv
// 플레이어 이동 + 점프 제어 (2명, 턴제)
// 동작: 수평 이동 → 점프 (깃발 도착 시 FLAG_SLIDING)
// Game Logic 인터페이스: pos_x + pos_valid

module player_controller (
    input  logic       clk,
    input  logic       rst,

    // Player 1 (Game Logic 스타일)
    input  logic [9:0] player1_pos_x,      // 목표 x 좌표
    input  logic       player1_pos_valid,  // 위치 업데이트 (1 cycle pulse)
    output logic [9:0] player1_x,          // 현재 x 좌표
    output logic [9:0] player1_y,          // 현재 y 좌표
    output logic       player1_turn_done,  // 턴 완료 (1 cycle pulse)

    // Player 2
    input  logic [9:0] player2_pos_x,
    input  logic       player2_pos_valid,
    output logic [9:0] player2_x,
    output logic [9:0] player2_y,
    output logic       player2_turn_done
);

    // ========================================
    // 파라미터
    // ========================================
    localparam START_X = 20;             // 시작 위치
    localparam FLAG_X = 620;             // 깃발 위치
    localparam BASE_Y = 124;             // 플레이어 기본 y 위치 (잔디 위)

    localparam MOVE_FRAMES = 24;         // 수평 이동 프레임 수
    localparam JUMP_FRAMES = 16;         // 점프 프레임 수
    localparam FLAG_SLIDE_FRAMES = 20;   // 깃발 슬라이딩 프레임 수
    localparam FLAG_TOP_Y = 90;          // 깃발 꼭대기 y 위치

    // ========================================
    // 상태 정의
    // ========================================
    typedef enum logic [2:0] {
        IDLE         = 3'b000,
        MOVING       = 3'b001,
        JUMPING      = 3'b010,
        FLAG_SLIDING = 3'b011
    } state_t;

    state_t state, next_state;

    // ========================================
    // 내부 신호
    // ========================================
    logic current_player;                // 0=Player1, 1=Player2
    logic [9:0] start_x, target_x;       // 이동 시작/목표 x 좌표
    logic [9:0] current_x;               // 현재 x 좌표 (이동 중)
    logic [9:0] current_y;               // 현재 y 좌표 (점프/슬라이딩 중)
    logic [4:0] counter;                 // 애니메이션 카운터

    // 각 플레이어의 현재 위치 저장
    logic [9:0] player1_x_reg, player1_y_reg;
    logic [9:0] player2_x_reg, player2_y_reg;

    // Edge detection for pos_valid
    logic player1_pos_valid_prev, player2_pos_valid_prev;
    logic player1_pos_pulse, player2_pos_pulse;

    // 점프 높이 LUT (삼각형 커브)
    logic [5:0] jump_lut [0:15];
    initial begin
        jump_lut[0]  = 0;
        jump_lut[1]  = 4;
        jump_lut[2]  = 8;
        jump_lut[3]  = 12;
        jump_lut[4]  = 16;
        jump_lut[5]  = 20;
        jump_lut[6]  = 24;
        jump_lut[7]  = 28;
        jump_lut[8]  = 30;   // 최고점
        jump_lut[9]  = 28;
        jump_lut[10] = 24;
        jump_lut[11] = 20;
        jump_lut[12] = 16;
        jump_lut[13] = 12;
        jump_lut[14] = 8;
        jump_lut[15] = 4;
    end

    // ========================================
    // Edge detection (Rising edge만 감지)
    // ========================================
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            player1_pos_valid_prev <= 1'b0;
            player2_pos_valid_prev <= 1'b0;
        end else begin
            player1_pos_valid_prev <= player1_pos_valid;
            player2_pos_valid_prev <= player2_pos_valid;
        end
    end

    assign player1_pos_pulse = player1_pos_valid && !player1_pos_valid_prev;
    assign player2_pos_pulse = player2_pos_valid && !player2_pos_valid_prev;

    // ========================================
    // 상태 머신
    // ========================================
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            counter <= 5'd0;
            current_player <= 1'b0;
            start_x <= START_X;
            target_x <= START_X;
            player1_x_reg <= START_X;
            player1_y_reg <= BASE_Y;
            player2_x_reg <= START_X;
            player2_y_reg <= BASE_Y;
        end else begin
            state <= next_state;

            case (state)
                IDLE: begin
                    counter <= 5'd0;

                    // Player 1 이동 시작? (pos_valid rising edge)
                    if (player1_pos_pulse) begin
                        current_player <= 1'b0;
                        start_x <= player1_x_reg;
                        target_x <= player1_pos_x;     // pos_x를 target_x로 사용
                    end
                    // Player 2 이동 시작?
                    else if (player2_pos_pulse) begin
                        current_player <= 1'b1;
                        start_x <= player2_x_reg;
                        target_x <= player2_pos_x;
                    end
                end

                MOVING: begin
                    counter <= counter + 1;
                    if (counter == MOVE_FRAMES - 1) begin
                        // 이동 완료, 위치 업데이트
                        if (current_player == 1'b0)
                            player1_x_reg <= target_x;
                        else
                            player2_x_reg <= target_x;
                        counter <= 5'd0;
                    end
                end

                JUMPING: begin
                    counter <= counter + 1;
                    if (counter == JUMP_FRAMES - 1) begin
                        counter <= 5'd0;
                    end
                end

                FLAG_SLIDING: begin
                    counter <= counter + 1;
                    if (counter == FLAG_SLIDE_FRAMES - 1) begin
                        // 슬라이딩 완료, y 좌표 복귀
                        if (current_player == 1'b0)
                            player1_y_reg <= BASE_Y;
                        else
                            player2_y_reg <= BASE_Y;
                        counter <= 5'd0;
                    end
                end
            endcase
        end
    end

    // 다음 상태 로직
    always_comb begin
        case (state)
            IDLE: begin
                if (player1_pos_pulse || player2_pos_pulse)
                    next_state = MOVING;
                else
                    next_state = IDLE;
            end

            MOVING: begin
                if (counter == MOVE_FRAMES - 1)
                    next_state = JUMPING;
                else
                    next_state = MOVING;
            end

            JUMPING: begin
                if (counter == JUMP_FRAMES - 1) begin
                    // 깃발 도착 (x=620)이면 FLAG_SLIDING, 아니면 IDLE
                    if (target_x == FLAG_X)
                        next_state = FLAG_SLIDING;
                    else
                        next_state = IDLE;
                end else begin
                    next_state = JUMPING;
                end
            end

            FLAG_SLIDING: begin
                if (counter == FLAG_SLIDE_FRAMES - 1)
                    next_state = IDLE;
                else
                    next_state = FLAG_SLIDING;
            end

            default: next_state = IDLE;
        endcase
    end

    // ========================================
    // X 좌표 계산 (수평 이동)
    // ========================================
    always_comb begin
        if (state == MOVING) begin
            // 선형 보간 (start_x → target_x)
            current_x = start_x + ((target_x - start_x) * counter) / MOVE_FRAMES;
        end else begin
            // 이동 중이 아니면 현재 플레이어의 저장된 위치
            if (current_player == 1'b0)
                current_x = player1_x_reg;
            else
                current_x = player2_x_reg;
        end
    end

    // ========================================
    // Y 좌표 계산 (점프 + 깃발 슬라이딩)
    // ========================================
    logic [9:0] jump_offset;
    logic [9:0] slide_y;

    always_comb begin
        // 점프 오프셋
        if (state == JUMPING) begin
            jump_offset = jump_lut[counter[3:0]];
        end else begin
            jump_offset = 0;
        end

        // 깃발 슬라이딩 y 좌표 (선형 감소)
        if (state == FLAG_SLIDING) begin
            slide_y = FLAG_TOP_Y + ((BASE_Y - FLAG_TOP_Y) * counter) / FLAG_SLIDE_FRAMES;
        end else begin
            slide_y = BASE_Y;
        end

        // 최종 y 좌표
        if (state == FLAG_SLIDING) begin
            current_y = slide_y;
        end else begin
            current_y = BASE_Y - jump_offset;
        end
    end

    // ========================================
    // turn_done 신호 생성 (1 cycle pulse)
    // ========================================
    logic player1_turn_done_reg, player2_turn_done_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            player1_turn_done_reg <= 1'b0;
            player2_turn_done_reg <= 1'b0;
        end else begin
            // JUMPING → IDLE 또는 FLAG_SLIDING → IDLE 전환 시
            if ((state == JUMPING && next_state == IDLE && target_x != FLAG_X) ||
                (state == FLAG_SLIDING && next_state == IDLE)) begin
                if (current_player == 1'b0)
                    player1_turn_done_reg <= 1'b1;
                else
                    player2_turn_done_reg <= 1'b1;
            end else begin
                player1_turn_done_reg <= 1'b0;
                player2_turn_done_reg <= 1'b0;
            end
        end
    end

    // ========================================
    // 출력
    // ========================================
    // Player 1 출력
    assign player1_x = (state != IDLE && current_player == 1'b0) ? current_x : player1_x_reg;
    assign player1_y = (state != IDLE && current_player == 1'b0) ? current_y : player1_y_reg;
    assign player1_turn_done = player1_turn_done_reg;

    // Player 2 출력
    assign player2_x = (state != IDLE && current_player == 1'b1) ? current_x : player2_x_reg;
    assign player2_y = (state != IDLE && current_player == 1'b1) ? current_y : player2_y_reg;
    assign player2_turn_done = player2_turn_done_reg;

endmodule
