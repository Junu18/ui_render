// ui_render.sv
// NES 보드 게임 스타일 UI 렌더러 (All-in-one)
// 배경: 하늘(0~140px) + 잔디(140~150px) + 흙(150~180px)
// 플레이어: IC 칩 (16x16, 좌우 핀)

// ============================================
// 색상 정의 패키지
// ============================================
package color_pkg;
    typedef struct packed {
        logic [7:0] r;
        logic [7:0] g;
        logic [7:0] b;
    } rgb_t;

    // 하늘
    parameter rgb_t SKY_LIGHT_BLUE = '{r: 8'h87, g: 8'hCE, b: 8'hEB};
    parameter rgb_t SKY_BLUE       = '{r: 8'h5D, g: 8'hAD, b: 8'hE2};

    // 잔디
    parameter rgb_t GRASS_BRIGHT   = '{r: 8'h7F, g: 8'hC8, b: 8'h3F};
    parameter rgb_t GRASS_GREEN    = '{r: 8'h55, g: 8'hA0, b: 8'h2F};

    // 흙
    parameter rgb_t DIRT_DARK      = '{r: 8'h6B, g: 8'h4A, b: 8'h2F};
    parameter rgb_t DIRT_MID       = '{r: 8'h8B, g: 8'h65, b: 8'h3F};
    parameter rgb_t DIRT_LIGHT     = '{r: 8'hA0, g: 8'h7A, b: 8'h50};
    parameter rgb_t DIRT_GRAY      = '{r: 8'h70, g: 8'h70, b: 8'h70};

    // IC 칩 캐릭터
    parameter rgb_t IC_BLACK       = '{r: 8'h20, g: 8'h20, b: 8'h20};
    parameter rgb_t IC_GRAY        = '{r: 8'h50, g: 8'h50, b: 8'h50};
    parameter rgb_t IC_SILVER      = '{r: 8'hC0, g: 8'hC0, b: 8'hC0};
    parameter rgb_t IC_RED         = '{r: 8'hFF, g: 8'h00, b: 8'h00};

    // 기본
    parameter rgb_t BLACK          = '{r: 8'h00, g: 8'h00, b: 8'h00};
    parameter rgb_t TRANSPARENT    = '{r: 8'hFF, g: 8'h00, b: 8'hFF};
endpackage


// ============================================
// 하늘 렌더러 (0 ~ 140px)
// ============================================
import color_pkg::*;

module sky_renderer (
    input  logic [9:0] x,
    input  logic [9:0] y,
    output rgb_t       color,
    output logic       enable
);
    always_comb begin
        if (y < 140) begin
            enable = 1'b1;
            if (y < 70) begin
                color = SKY_LIGHT_BLUE;
            end else begin
                color = SKY_BLUE;
            end
        end else begin
            enable = 1'b0;
            color = BLACK;
        end
    end
endmodule


// ============================================
// 잔디 렌더러 (140 ~ 150px)
// ============================================
module grass_renderer (
    input  logic [9:0] x,
    input  logic [9:0] y,
    output rgb_t       color,
    output logic       enable
);
    always_comb begin
        if (y >= 140 && y < 150) begin
            enable = 1'b1;
            if (y == 140) begin
                color = GRASS_BRIGHT;
            end else begin
                color = GRASS_GREEN;
            end
        end else begin
            enable = 1'b0;
            color = BLACK;
        end
    end
endmodule


// ============================================
// 흙 렌더러 (150 ~ 180px)
// ============================================
module dirt_renderer (
    input  logic [9:0] x,
    input  logic [9:0] y,
    output rgb_t       color,
    output logic       enable
);
    logic [1:0] pattern_x;
    logic [1:0] pattern_y;
    logic [3:0] pattern_code;

    assign pattern_x = x[2:1];
    assign pattern_y = (y - 150) >> 1;
    assign pattern_code = {pattern_x, pattern_y};

    always_comb begin
        if (y >= 150 && y < 180) begin
            enable = 1'b1;
            case (pattern_code)
                4'b0000, 4'b0101, 4'b1010, 4'b1111: color = DIRT_DARK;
                4'b0001, 4'b0100, 4'b1001, 4'b1100: color = DIRT_MID;
                4'b0010, 4'b0111, 4'b1000, 4'b1101: color = DIRT_LIGHT;
                4'b0011, 4'b0110, 4'b1011, 4'b1110: color = DIRT_GRAY;
                default: color = DIRT_MID;
            endcase
        end else begin
            enable = 1'b0;
            color = BLACK;
        end
    end
endmodule


// ============================================
// 플레이어 컨트롤러 (이동 + 점프, 연속 이동 지원)
// ============================================
module player_controller (
    input  logic       clk,
    input  logic       rst,
    input  logic       move_1,          // 1칸 이동 명령 (Red 주사위)
    input  logic       move_2,          // 2칸 이동 명령 (Green 주사위)
    input  logic       move_3,          // 3칸 이동 명령 (Blue 주사위)
    output logic [9:0] player_x,
    output logic [9:0] player_y,
    output logic [3:0] current_tile,
    output logic       is_moving
);
    localparam TILE_SIZE = 48;
    localparam PLAYER_OFFSET = 16;
    localparam BASE_Y = 124;
    localparam MOVE_FRAMES = 24;
    localparam JUMP_FRAMES = 16;

    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        MOVING  = 2'b01,
        JUMPING = 2'b10
    } state_t;

    state_t state, next_state;
    logic [3:0] target_tile;
    logic [4:0] counter;
    logic [9:0] start_x, target_x, current_x;
    logic [9:0] jump_offset;
    logic [1:0] remaining_moves;         // 남은 이동 횟수 (0~3)

    // Edge detection for move_1/2/3
    logic move_1_prev, move_2_prev, move_3_prev;
    logic move_1_pulse, move_2_pulse, move_3_pulse;

    logic [5:0] jump_lut [0:15];
    initial begin
        jump_lut[0]  = 0;  jump_lut[1]  = 4;  jump_lut[2]  = 8;  jump_lut[3]  = 12;
        jump_lut[4]  = 16; jump_lut[5]  = 20; jump_lut[6]  = 24; jump_lut[7]  = 28;
        jump_lut[8]  = 30; jump_lut[9]  = 28; jump_lut[10] = 24; jump_lut[11] = 20;
        jump_lut[12] = 16; jump_lut[13] = 12; jump_lut[14] = 8;  jump_lut[15] = 4;
    end

    function automatic logic [9:0] tile_to_x(input logic [3:0] tile);
        return tile * TILE_SIZE + PLAYER_OFFSET;
    endfunction

    // Edge detection (Rising edge만 감지)
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            move_1_prev <= 1'b0;
            move_2_prev <= 1'b0;
            move_3_prev <= 1'b0;
        end else begin
            move_1_prev <= move_1;
            move_2_prev <= move_2;
            move_3_prev <= move_3;
        end
    end

    assign move_1_pulse = move_1 && !move_1_prev;
    assign move_2_pulse = move_2 && !move_2_prev;
    assign move_3_pulse = move_3 && !move_3_prev;

    // 상태 머신
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            current_tile <= 4'd0;
            counter <= 5'd0;
            start_x <= tile_to_x(0);
            target_x <= tile_to_x(0);
            remaining_moves <= 2'd0;
        end else begin
            state <= next_state;
            case (state)
                IDLE: begin
                    counter <= 5'd0;
                    // 이동 명령 감지 (Rising edge)
                    if (current_tile < 9) begin
                        if (move_1_pulse) begin
                            remaining_moves <= 2'd0;  // 1칸 이동 (점프 후 0)
                            start_x <= tile_to_x(current_tile);
                            target_tile <= current_tile + 1;
                            target_x <= tile_to_x(current_tile + 1);
                        end else if (move_2_pulse) begin
                            remaining_moves <= 2'd1;  // 2칸 이동 (점프 후 1칸 남음)
                            start_x <= tile_to_x(current_tile);
                            target_tile <= current_tile + 1;
                            target_x <= tile_to_x(current_tile + 1);
                        end else if (move_3_pulse) begin
                            remaining_moves <= 2'd2;  // 3칸 이동 (점프 후 2칸 남음)
                            start_x <= tile_to_x(current_tile);
                            target_tile <= current_tile + 1;
                            target_x <= tile_to_x(current_tile + 1);
                        end
                    end
                end
                MOVING: begin
                    counter <= counter + 1;
                    if (counter == MOVE_FRAMES - 1) begin
                        current_tile <= target_tile;
                        counter <= 5'd0;
                    end
                end
                JUMPING: begin
                    counter <= counter + 1;
                    if (counter == JUMP_FRAMES - 1) begin
                        counter <= 5'd0;
                        // 점프 완료 후 남은 이동이 있으면 다음 타일로
                        if (remaining_moves > 0 && current_tile < 9) begin
                            remaining_moves <= remaining_moves - 1;
                            start_x <= tile_to_x(target_tile);
                            target_tile <= target_tile + 1;
                            target_x <= tile_to_x(target_tile + 1);
                        end
                    end
                end
            endcase
        end
    end

    always_comb begin
        case (state)
            IDLE: begin
                if (current_tile < 9 && (move_1_pulse || move_2_pulse || move_3_pulse))
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
                    // 남은 이동이 있으면 다시 MOVING, 없으면 IDLE
                    if (remaining_moves > 0 && current_tile < 9)
                        next_state = MOVING;
                    else
                        next_state = IDLE;
                end else begin
                    next_state = JUMPING;
                end
            end
            default: next_state = IDLE;
        endcase
    end

    always_comb begin
        if (state == MOVING)
            current_x = start_x + ((target_x - start_x) * counter) / MOVE_FRAMES;
        else
            current_x = tile_to_x(current_tile);
    end

    always_comb begin
        if (state == JUMPING)
            jump_offset = jump_lut[counter[3:0]];
        else
            jump_offset = 0;
    end

    assign player_x = current_x;
    assign player_y = BASE_Y - jump_offset;
    assign is_moving = (state != IDLE);
endmodule


// ============================================
// IC 칩 플레이어 렌더러 (16x16, 좌우 핀)
// ============================================
module player_renderer (
    input  logic [9:0] x,
    input  logic [9:0] y,
    input  logic [9:0] player_x,
    input  logic [9:0] player_y,
    output rgb_t       color,
    output logic       enable
);
    logic in_player_area;
    logic [3:0] sprite_x;
    logic [3:0] sprite_y;

    assign in_player_area = (x >= player_x) && (x < player_x + 16) &&
                            (y >= player_y) && (y < player_y + 16);
    assign sprite_x = x - player_x;
    assign sprite_y = y - player_y;

    always_comb begin
        if (in_player_area) begin
            case (sprite_y)
                // Row 0: 상단 테두리
                4'd0: begin
                    if (sprite_x >= 2 && sprite_x <= 13) begin
                        color = IC_GRAY;
                        enable = 1'b1;
                    end else begin
                        enable = 1'b0;
                        color = TRANSPARENT;
                    end
                end

                // Row 1: 테두리 + 몸체
                4'd1: begin
                    if (sprite_x == 1 || sprite_x == 14) begin
                        color = IC_GRAY;
                        enable = 1'b1;
                    end else if (sprite_x >= 2 && sprite_x <= 13) begin
                        color = IC_BLACK;
                        enable = 1'b1;
                    end else begin
                        enable = 1'b0;
                        color = TRANSPARENT;
                    end
                end

                // Row 2-3: 빨간 점 (방향 표시)
                4'd2, 4'd3: begin
                    if (sprite_x == 1 || sprite_x == 14) begin
                        color = IC_GRAY;
                        enable = 1'b1;
                    end else if (sprite_x >= 6 && sprite_x <= 7) begin
                        color = IC_RED;
                        enable = 1'b1;
                    end else if (sprite_x >= 2 && sprite_x <= 13) begin
                        color = IC_BLACK;
                        enable = 1'b1;
                    end else begin
                        enable = 1'b0;
                        color = TRANSPARENT;
                    end
                end

                // Row 4-11: 좌우 핀 + 몸체
                4'd4, 4'd5, 4'd6, 4'd7, 4'd8, 4'd9, 4'd10, 4'd11: begin
                    if (sprite_x <= 1 || sprite_x >= 14) begin
                        color = IC_SILVER;
                        enable = 1'b1;
                    end else if (sprite_x == 2 || sprite_x == 13) begin
                        color = IC_GRAY;
                        enable = 1'b1;
                    end else if (sprite_x >= 3 && sprite_x <= 12) begin
                        color = IC_BLACK;
                        enable = 1'b1;
                    end else begin
                        enable = 1'b0;
                        color = TRANSPARENT;
                    end
                end

                // Row 12-14: 테두리 + 몸체
                4'd12, 4'd13, 4'd14: begin
                    if (sprite_x == 1 || sprite_x == 14) begin
                        color = IC_GRAY;
                        enable = 1'b1;
                    end else if (sprite_x >= 2 && sprite_x <= 13) begin
                        color = IC_BLACK;
                        enable = 1'b1;
                    end else begin
                        enable = 1'b0;
                        color = TRANSPARENT;
                    end
                end

                // Row 15: 하단 테두리
                4'd15: begin
                    if (sprite_x >= 2 && sprite_x <= 13) begin
                        color = IC_GRAY;
                        enable = 1'b1;
                    end else begin
                        enable = 1'b0;
                        color = TRANSPARENT;
                    end
                end

                default: begin
                    enable = 1'b0;
                    color = TRANSPARENT;
                end
            endcase
        end else begin
            enable = 1'b0;
            color = TRANSPARENT;
        end
    end
endmodule


// ============================================
// 골인 깃발 렌더러 (체커보드 패턴)
// ============================================
module flag_renderer (
    input  logic [9:0] x,
    input  logic [9:0] y,
    output rgb_t       color,
    output logic       enable
);
    localparam FLAG_TILE = 9;
    localparam FLAG_X_BASE = FLAG_TILE * 48 + 24;  // 타일 9 중앙 (x=456)

    localparam POLE_X_START = FLAG_X_BASE;
    localparam POLE_X_END   = FLAG_X_BASE + 1;     // 깃대 폭 2px
    localparam POLE_Y_TOP   = 80;                  // 깃대 위쪽
    localparam POLE_Y_BOTTOM = 150;                // 깃대 아래 (흙 위)

    localparam FLAG_X_START = FLAG_X_BASE + 2;     // 깃발 시작 (깃대 오른쪽)
    localparam FLAG_X_END   = FLAG_X_START + 15;   // 깃발 폭 16px
    localparam FLAG_Y_TOP   = 80;                  // 깃발 위쪽
    localparam FLAG_Y_BOTTOM = 95;                 // 깃발 높이 16px

    localparam CHECKER_SIZE = 4;

    logic in_pole_area;
    logic in_flag_area;
    logic [3:0] flag_local_x;
    logic [3:0] flag_local_y;
    logic checker_pattern;

    assign in_pole_area = (x >= POLE_X_START && x <= POLE_X_END) &&
                          (y >= POLE_Y_TOP && y < POLE_Y_BOTTOM);

    assign in_flag_area = (x >= FLAG_X_START && x <= FLAG_X_END) &&
                          (y >= FLAG_Y_TOP && y < FLAG_Y_BOTTOM);

    assign flag_local_x = x - FLAG_X_START;
    assign flag_local_y = y - FLAG_Y_TOP;

    // 체커보드 패턴: (x/4 + y/4) % 2
    assign checker_pattern = ((flag_local_x[3:2] + flag_local_y[3:2]) & 1'b1);

    always_comb begin
        if (in_pole_area) begin
            color = '{r: 8'hE0, g: 8'hE0, b: 8'hE0};  // 밝은 회색 깃대
            enable = 1'b1;
        end else if (in_flag_area) begin
            if (checker_pattern) begin
                color = BLACK;
            end else begin
                color = WHITE;
            end
            enable = 1'b1;
        end else begin
            enable = 1'b0;
            color = TRANSPARENT;
        end
    end
endmodule


// ============================================
// UI 렌더러 (Top Module)
// ============================================
module ui_render (
    input  logic       clk,
    input  logic       rst,            // 리셋 신호
    input  logic [9:0] x,              // 0 ~ 639
    input  logic [9:0] y,              // 0 ~ 479
    input  logic       move_1,         // 1칸 이동 명령 (Red 주사위)
    input  logic       move_2,         // 2칸 이동 명령 (Green 주사위)
    input  logic       move_3,         // 3칸 이동 명령 (Blue 주사위)
    output logic [7:0] r,              // Red
    output logic [7:0] g,              // Green
    output logic [7:0] b,              // Blue
    output logic [3:0] current_tile,   // 현재 타일 번호 (0~9)
    output logic       is_moving       // 이동 중 플래그
);

    // 플레이어 좌표 (내부 신호)
    logic [9:0] player_x, player_y;

    // 렌더러 신호
    rgb_t  sky_color, grass_color, dirt_color, flag_color, player_color;
    logic  sky_en, grass_en, dirt_en, flag_en, player_en;

    // 플레이어 컨트롤러
    player_controller ctrl (
        .clk(clk),
        .rst(rst),
        .move_1(move_1),
        .move_2(move_2),
        .move_3(move_3),
        .player_x(player_x),
        .player_y(player_y),
        .current_tile(current_tile),
        .is_moving(is_moving)
    );

    // 배경 렌더러
    sky_renderer sky_inst (
        .x(x), .y(y),
        .color(sky_color),
        .enable(sky_en)
    );

    grass_renderer grass_inst (
        .x(x), .y(y),
        .color(grass_color),
        .enable(grass_en)
    );

    dirt_renderer dirt_inst (
        .x(x), .y(y),
        .color(dirt_color),
        .enable(dirt_en)
    );

    // 깃발 렌더러 (골인 지점)
    flag_renderer flag_inst (
        .x(x), .y(y),
        .color(flag_color),
        .enable(flag_en)
    );

    // 플레이어 렌더러
    player_renderer player_inst (
        .x(x), .y(y),
        .player_x(player_x),
        .player_y(player_y),
        .color(player_color),
        .enable(player_en)
    );

    // 레이어 합성 (우선순위: player > flag > dirt > grass > sky)
    rgb_t final_color;

    always_comb begin
        final_color = BLACK;  // 기본 배경

        if (sky_en) begin
            final_color = sky_color;
        end

        if (grass_en) begin
            final_color = grass_color;
        end

        if (dirt_en) begin
            final_color = dirt_color;
        end

        if (flag_en) begin
            final_color = flag_color;
        end

        if (player_en) begin
            final_color = player_color;
        end
    end

    // 출력 (1 clock delay)
    always_ff @(posedge clk) begin
        r <= final_color.r;
        g <= final_color.g;
        b <= final_color.b;
    end

endmodule
