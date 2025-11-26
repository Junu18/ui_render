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
// 플레이어 컨트롤러 (이동 + 점프)
// ============================================
module player_controller (
    input  logic       clk,
    input  logic       rst,
    input  logic       move_trigger,
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
                        start_x <= tile_to_x(current_tile);
                        target_tile <= current_tile + 1;
                        target_x <= tile_to_x(current_tile + 1);
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
                    end
                end
            endcase
        end
    end

    always_comb begin
        case (state)
            IDLE:    next_state = (move_trigger && current_tile < 9) ? MOVING : IDLE;
            MOVING:  next_state = (counter == MOVE_FRAMES - 1) ? JUMPING : MOVING;
            JUMPING: next_state = (counter == JUMP_FRAMES - 1) ? IDLE : JUMPING;
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
// UI 렌더러 (Top Module)
// ============================================
module ui_render (
    input  logic       clk,
    input  logic       rst,            // 리셋 신호
    input  logic [9:0] x,              // 0 ~ 639
    input  logic [9:0] y,              // 0 ~ 479
    input  logic       move_trigger,   // 한 칸 이동 명령 (펄스)
    output logic [7:0] r,              // Red
    output logic [7:0] g,              // Green
    output logic [7:0] b,              // Blue
    output logic [3:0] current_tile,   // 현재 타일 번호 (0~9)
    output logic       is_moving       // 이동 중 플래그
);

    // 플레이어 좌표 (내부 신호)
    logic [9:0] player_x, player_y;

    // 렌더러 신호
    rgb_t  sky_color, grass_color, dirt_color, player_color;
    logic  sky_en, grass_en, dirt_en, player_en;

    // 플레이어 컨트롤러
    player_controller ctrl (
        .clk(clk),
        .rst(rst),
        .move_trigger(move_trigger),
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

    // 플레이어 렌더러
    player_renderer player_inst (
        .x(x), .y(y),
        .player_x(player_x),
        .player_y(player_y),
        .color(player_color),
        .enable(player_en)
    );

    // 레이어 합성 (우선순위: player > dirt > grass > sky)
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
