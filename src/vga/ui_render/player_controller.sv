// player_controller.sv
// 플레이어 이동 + 점프 제어
// 동작: 수평 이동 → 제자리 점프

module player_controller (
    input  logic       clk,
    input  logic       rst,
    input  logic       move_trigger,    // 한 칸 이동 명령 (펄스)
    output logic [9:0] player_x,        // 플레이어 x 좌표
    output logic [9:0] player_y,        // 플레이어 y 좌표
    output logic [3:0] current_tile,    // 현재 타일 번호 (0~9)
    output logic       is_moving        // 이동/점프 중
);

    // ========================================
    // 파라미터
    // ========================================
    localparam TILE_SIZE = 48;           // 타일 크기
    localparam PLAYER_OFFSET = 16;       // 타일 중앙 오프셋
    localparam BASE_Y = 124;             // 잔디 위 (140 - 16)

    localparam MOVE_FRAMES = 24;         // 수평 이동 프레임 수
    localparam JUMP_FRAMES = 16;         // 점프 프레임 수
    localparam JUMP_HEIGHT = 30;         // 점프 높이

    // ========================================
    // 상태 정의
    // ========================================
    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        MOVING  = 2'b01,
        JUMPING = 2'b10
    } state_t;

    state_t state, next_state;

    // ========================================
    // 내부 신호
    // ========================================
    logic [3:0] target_tile;             // 목표 타일
    logic [4:0] counter;                 // 애니메이션 카운터
    logic [9:0] start_x, target_x;       // 시작/목표 x 좌표
    logic [9:0] current_x;               // 현재 x 좌표 (이동 중)
    logic [9:0] jump_offset;             // 점프 y 오프셋

    // 점프 높이 LUT (삼각형 커브)
    // 16프레임: 0→최대→0
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
    // 타일 좌표 계산
    // ========================================
    function automatic logic [9:0] tile_to_x(input logic [3:0] tile);
        return tile * TILE_SIZE + PLAYER_OFFSET;
    endfunction

    // ========================================
    // 상태 머신
    // ========================================
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            current_tile <= 4'd0;
            counter <= 5'd0;
            start_x <= tile_to_x(0);
            target_x <= tile_to_x(0);
        end else begin
            state <= next_state;

            case (state)
                IDLE: begin
                    counter <= 5'd0;
                    if (move_trigger && current_tile < 9) begin
                        // 이동 시작
                        start_x <= tile_to_x(current_tile);
                        target_tile <= current_tile + 1;
                        target_x <= tile_to_x(current_tile + 1);
                    end
                end

                MOVING: begin
                    counter <= counter + 1;
                    if (counter == MOVE_FRAMES - 1) begin
                        // 이동 완료, 타일 업데이트
                        current_tile <= target_tile;
                        counter <= 5'd0;
                    end
                end

                JUMPING: begin
                    counter <= counter + 1;
                    if (counter == JUMP_FRAMES - 1) begin
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
                if (move_trigger && current_tile < 9)
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
                if (counter == JUMP_FRAMES - 1)
                    next_state = IDLE;
                else
                    next_state = JUMPING;
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
            // x = start_x + (target_x - start_x) * (counter / MOVE_FRAMES)
            // 간단하게: 비트 시프트 사용
            current_x = start_x + ((target_x - start_x) * counter) / MOVE_FRAMES;
        end else begin
            current_x = tile_to_x(current_tile);
        end
    end

    // ========================================
    // Y 좌표 계산 (점프)
    // ========================================
    always_comb begin
        if (state == JUMPING) begin
            jump_offset = jump_lut[counter[3:0]];
        end else begin
            jump_offset = 0;
        end
    end

    // ========================================
    // 출력
    // ========================================
    assign player_x = current_x;
    assign player_y = BASE_Y - jump_offset;
    assign is_moving = (state != IDLE);

endmodule
