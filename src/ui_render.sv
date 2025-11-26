// ui_render.sv
// VGA UI 렌더러 (All-in-one 파일)
// 플레이어 2명, 턴제 게임 지원

// ============================================
// 색상 패키지
// ============================================
package color_pkg;
    typedef struct packed {
        logic [7:0] r;
        logic [7:0] g;
        logic [7:0] b;
    } rgb_t;

    // 기본 색상
    parameter rgb_t TRANSPARENT = '{r: 8'h00, g: 8'h00, b: 8'h00};
    parameter rgb_t BLACK   = '{r: 8'h00, g: 8'h00, b: 8'h00};
    parameter rgb_t WHITE   = '{r: 8'hFF, g: 8'hFF, b: 8'hFF};

    // 하늘 색상 (그라데이션)
    parameter rgb_t SKY_TOP    = '{r: 8'h5C, g: 8'h9E, b: 8'hD8};
    parameter rgb_t SKY_BOTTOM = '{r: 8'h9E, g: 8'hD8, b: 8'hFF};

    // 마인크래프트 스타일 잔디 (위쪽만)
    parameter rgb_t GRASS_1 = '{r: 8'h7C, g: 8'hB3, b: 8'h42};
    parameter rgb_t GRASS_2 = '{r: 8'h8B, g: 8'hC3, b: 8'h4F};
    parameter rgb_t GRASS_3 = '{r: 8'h6A, g: 8'hA0, b: 8'h35};

    // 흙 (아래쪽)
    parameter rgb_t DIRT_1  = '{r: 8'h8B, g: 8'h6F, b: 8'h47};
    parameter rgb_t DIRT_2  = '{r: 8'h9C, g: 8'h7F, b: 8'h57};
    parameter rgb_t DIRT_3  = '{r: 8'h7A, g: 8'h5F, b: 8'h37};

    // IC 칩 색상
    parameter rgb_t IC_BLACK   = '{r: 8'h20, g: 8'h20, b: 8'h20};
    parameter rgb_t IC_GRAY    = '{r: 8'h50, g: 8'h50, b: 8'h50};
    parameter rgb_t IC_SILVER  = '{r: 8'hC0, g: 8'hC0, b: 8'hC0};
    parameter rgb_t IC_RED     = '{r: 8'hFF, g: 8'h00, b: 8'h00};
endpackage

import color_pkg::*;


// ============================================
// 하늘 렌더러
// ============================================
module sky_renderer (
    input  logic [9:0] x,
    input  logic [9:0] y,
    output rgb_t       color,
    output logic       enable
);
    always_comb begin
        if (y < 140) begin
            if (y < 70) begin
                color = SKY_TOP;
            end else begin
                logic [7:0] ratio = (y - 70);
                color.r = SKY_TOP.r + ((SKY_BOTTOM.r - SKY_TOP.r) * ratio) / 70;
                color.g = SKY_TOP.g + ((SKY_BOTTOM.g - SKY_TOP.g) * ratio) / 70;
                color.b = SKY_TOP.b + ((SKY_BOTTOM.b - SKY_TOP.b) * ratio) / 70;
            end
            enable = 1'b1;
        end else begin
            enable = 1'b0;
            color = TRANSPARENT;
        end
    end
endmodule


// ============================================
// 잔디 렌더러
// ============================================
module grass_renderer (
    input  logic [9:0] x,
    input  logic [9:0] y,
    output rgb_t       color,
    output logic       enable
);
    always_comb begin
        if (y >= 140 && y < 150) begin
            logic [1:0] pattern = x[2:1] + y[1:0];
            case (pattern[1:0])
                2'b00: color = GRASS_1;
                2'b01: color = GRASS_2;
                2'b10: color = GRASS_3;
                2'b11: color = GRASS_1;
            endcase
            enable = 1'b1;
        end else begin
            enable = 1'b0;
            color = TRANSPARENT;
        end
    end
endmodule


// ============================================
// 흙 렌더러
// ============================================
module dirt_renderer (
    input  logic [9:0] x,
    input  logic [9:0] y,
    output rgb_t       color,
    output logic       enable
);
    always_comb begin
        if (y >= 150 && y < 180) begin
            logic [1:0] pattern = x[3:2] + y[2:1];
            case (pattern[1:0])
                2'b00: color = DIRT_1;
                2'b01: color = DIRT_2;
                2'b10: color = DIRT_3;
                2'b11: color = DIRT_1;
            endcase
            enable = 1'b1;
        end else begin
            enable = 1'b0;
            color = TRANSPARENT;
        end
    end
endmodule


// ============================================
// 골인 깃발 렌더러 (x=620)
// ============================================
module flag_renderer (
    input  logic [9:0] x,
    input  logic [9:0] y,
    output rgb_t       color,
    output logic       enable
);
    localparam FLAG_X_BASE = 620;
    localparam POLE_X_START = FLAG_X_BASE;
    localparam POLE_X_END   = FLAG_X_BASE + 1;
    localparam POLE_Y_TOP   = 80;
    localparam POLE_Y_BOTTOM = 150;
    localparam FLAG_X_START = FLAG_X_BASE + 2;
    localparam FLAG_X_END   = FLAG_X_START + 15;
    localparam FLAG_Y_TOP   = 80;
    localparam FLAG_Y_BOTTOM = 95;

    logic in_pole_area, in_flag_area;
    logic [3:0] flag_local_x, flag_local_y;
    logic checker_pattern;

    assign in_pole_area = (x >= POLE_X_START && x <= POLE_X_END) &&
                          (y >= POLE_Y_TOP && y < POLE_Y_BOTTOM);
    assign in_flag_area = (x >= FLAG_X_START && x <= FLAG_X_END) &&
                          (y >= FLAG_Y_TOP && y < FLAG_Y_BOTTOM);
    assign flag_local_x = x - FLAG_X_START;
    assign flag_local_y = y - FLAG_Y_TOP;
    assign checker_pattern = ((flag_local_x[3:2] + flag_local_y[3:2]) & 1'b1);

    always_comb begin
        if (in_pole_area) begin
            color = '{r: 8'hE0, g: 8'hE0, b: 8'hE0};
            enable = 1'b1;
        end else if (in_flag_area) begin
            color = checker_pattern ? BLACK : WHITE;
            enable = 1'b1;
        end else begin
            enable = 1'b0;
            color = TRANSPARENT;
        end
    end
endmodule


// ============================================
// 플레이어 렌더러 (IC 칩)
// ============================================
module player_renderer (
    input  logic [9:0] x,
    input  logic [9:0] y,
    input  logic [9:0] player_x,
    input  logic [9:0] player_y,
    input  logic       player_id,
    output rgb_t       color,
    output logic       enable
);
    logic in_player_area;
    logic [3:0] sprite_x, sprite_y;

    assign in_player_area = (x >= player_x) && (x < player_x + 16) &&
                            (y >= player_y) && (y < player_y + 16);
    assign sprite_x = x - player_x;
    assign sprite_y = y - player_y;

    always_comb begin
        if (in_player_area) begin
            case (sprite_y)
                4'd0: begin
                    if (sprite_x >= 2 && sprite_x <= 13) begin
                        color = IC_GRAY;
                        enable = 1'b1;
                    end else begin
                        enable = 1'b0;
                        color = TRANSPARENT;
                    end
                end

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

                4'd2, 4'd3: begin
                    if (sprite_x == 1 || sprite_x == 14) begin
                        color = IC_GRAY;
                        enable = 1'b1;
                    end else if (sprite_x >= 6 && sprite_x <= 7) begin
                        color = player_id ? '{r: 8'h00, g: 8'h00, b: 8'hFF} : IC_RED;
                        enable = 1'b1;
                    end else if (sprite_x >= 2 && sprite_x <= 13) begin
                        color = IC_BLACK;
                        enable = 1'b1;
                    end else begin
                        enable = 1'b0;
                        color = TRANSPARENT;
                    end
                end

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
// 플레이어 컨트롤러 (2명, 턴제)
// ============================================
module player_controller (
    input  logic       clk,
    input  logic       rst,
    input  logic [9:0] player1_target_x,
    input  logic       player1_move_start,
    output logic [9:0] player1_x,
    output logic [9:0] player1_y,
    output logic       player1_turn_done,
    input  logic [9:0] player2_target_x,
    input  logic       player2_move_start,
    output logic [9:0] player2_x,
    output logic [9:0] player2_y,
    output logic       player2_turn_done
);
    localparam START_X = 20;
    localparam FLAG_X = 620;
    localparam BASE_Y = 124;
    localparam MOVE_FRAMES = 24;
    localparam JUMP_FRAMES = 16;
    localparam FLAG_SLIDE_FRAMES = 20;
    localparam FLAG_TOP_Y = 90;

    typedef enum logic [2:0] {
        IDLE = 3'b000, MOVING = 3'b001, JUMPING = 3'b010, FLAG_SLIDING = 3'b011
    } state_t;

    state_t state, next_state;
    logic current_player;
    logic [9:0] start_x, target_x, current_x, current_y;
    logic [4:0] counter;
    logic [9:0] player1_x_reg, player1_y_reg, player2_x_reg, player2_y_reg;
    logic player1_move_start_prev, player2_move_start_prev;
    logic player1_move_pulse, player2_move_pulse;

    logic [5:0] jump_lut [0:15];
    initial begin
        jump_lut[0]=0; jump_lut[1]=4; jump_lut[2]=8; jump_lut[3]=12;
        jump_lut[4]=16; jump_lut[5]=20; jump_lut[6]=24; jump_lut[7]=28;
        jump_lut[8]=30; jump_lut[9]=28; jump_lut[10]=24; jump_lut[11]=20;
        jump_lut[12]=16; jump_lut[13]=12; jump_lut[14]=8; jump_lut[15]=4;
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            player1_move_start_prev <= 1'b0;
            player2_move_start_prev <= 1'b0;
        end else begin
            player1_move_start_prev <= player1_move_start;
            player2_move_start_prev <= player2_move_start;
        end
    end

    assign player1_move_pulse = player1_move_start && !player1_move_start_prev;
    assign player2_move_pulse = player2_move_start && !player2_move_start_prev;

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
                    if (player1_move_pulse) begin
                        current_player <= 1'b0;
                        start_x <= player1_x_reg;
                        target_x <= player1_target_x;
                    end else if (player2_move_pulse) begin
                        current_player <= 1'b1;
                        start_x <= player2_x_reg;
                        target_x <= player2_target_x;
                    end
                end
                MOVING: begin
                    counter <= counter + 1;
                    if (counter == MOVE_FRAMES - 1) begin
                        if (current_player == 1'b0)
                            player1_x_reg <= target_x;
                        else
                            player2_x_reg <= target_x;
                        counter <= 5'd0;
                    end
                end
                JUMPING: begin
                    counter <= counter + 1;
                    if (counter == JUMP_FRAMES - 1)
                        counter <= 5'd0;
                end
                FLAG_SLIDING: begin
                    counter <= counter + 1;
                    if (counter == FLAG_SLIDE_FRAMES - 1) begin
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

    always_comb begin
        case (state)
            IDLE: next_state = (player1_move_pulse || player2_move_pulse) ? MOVING : IDLE;
            MOVING: next_state = (counter == MOVE_FRAMES - 1) ? JUMPING : MOVING;
            JUMPING: next_state = (counter == JUMP_FRAMES - 1) ? (target_x == FLAG_X ? FLAG_SLIDING : IDLE) : JUMPING;
            FLAG_SLIDING: next_state = (counter == FLAG_SLIDE_FRAMES - 1) ? IDLE : FLAG_SLIDING;
            default: next_state = IDLE;
        endcase
    end

    always_comb begin
        if (state == MOVING)
            current_x = start_x + ((target_x - start_x) * counter) / MOVE_FRAMES;
        else
            current_x = (current_player == 1'b0) ? player1_x_reg : player2_x_reg;
    end

    logic [9:0] jump_offset, slide_y;
    always_comb begin
        jump_offset = (state == JUMPING) ? jump_lut[counter[3:0]] : 10'd0;
        slide_y = (state == FLAG_SLIDING) ? FLAG_TOP_Y + ((BASE_Y - FLAG_TOP_Y) * counter) / FLAG_SLIDE_FRAMES : BASE_Y;
        current_y = (state == FLAG_SLIDING) ? slide_y : (BASE_Y - jump_offset);
    end

    logic player1_turn_done_reg, player2_turn_done_reg;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            player1_turn_done_reg <= 1'b0;
            player2_turn_done_reg <= 1'b0;
        end else begin
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

    assign player1_x = (state != IDLE && current_player == 1'b0) ? current_x : player1_x_reg;
    assign player1_y = (state != IDLE && current_player == 1'b0) ? current_y : player1_y_reg;
    assign player1_turn_done = player1_turn_done_reg;
    assign player2_x = (state != IDLE && current_player == 1'b1) ? current_x : player2_x_reg;
    assign player2_y = (state != IDLE && current_player == 1'b1) ? current_y : player2_y_reg;
    assign player2_turn_done = player2_turn_done_reg;
endmodule


// ============================================
// UI 렌더러 (Top Module)
// ============================================
module ui_render (
    input  logic       clk,
    input  logic       rst,
    input  logic [9:0] x, y,

    // Player 1
    input  logic [9:0] player1_target_x,
    input  logic       player1_move_start,
    output logic       player1_turn_done,

    // Player 2
    input  logic [9:0] player2_target_x,
    input  logic       player2_move_start,
    output logic       player2_turn_done,

    // VGA 출력
    output logic [7:0] r, g, b
);

    logic [9:0] player1_x, player1_y, player2_x, player2_y;
    rgb_t sky_color, grass_color, dirt_color, flag_color, player1_color, player2_color;
    logic sky_en, grass_en, dirt_en, flag_en, player1_en, player2_en;

    player_controller ctrl (
        .clk(clk), .rst(rst),
        .player1_target_x(player1_target_x), .player1_move_start(player1_move_start),
        .player1_x(player1_x), .player1_y(player1_y), .player1_turn_done(player1_turn_done),
        .player2_target_x(player2_target_x), .player2_move_start(player2_move_start),
        .player2_x(player2_x), .player2_y(player2_y), .player2_turn_done(player2_turn_done)
    );

    sky_renderer sky_inst (.x(x), .y(y), .color(sky_color), .enable(sky_en));
    grass_renderer grass_inst (.x(x), .y(y), .color(grass_color), .enable(grass_en));
    dirt_renderer dirt_inst (.x(x), .y(y), .color(dirt_color), .enable(dirt_en));
    flag_renderer flag_inst (.x(x), .y(y), .color(flag_color), .enable(flag_en));
    player_renderer player1_inst (.x(x), .y(y), .player_x(player1_x), .player_y(player1_y),
                                    .player_id(1'b0), .color(player1_color), .enable(player1_en));
    player_renderer player2_inst (.x(x), .y(y), .player_x(player2_x), .player_y(player2_y),
                                    .player_id(1'b1), .color(player2_color), .enable(player2_en));

    rgb_t final_color;
    always_comb begin
        final_color = BLACK;
        if (sky_en) final_color = sky_color;
        if (grass_en) final_color = grass_color;
        if (dirt_en) final_color = dirt_color;
        if (flag_en) final_color = flag_color;
        if (player2_en) final_color = player2_color;
        if (player1_en) final_color = player1_color;
    end

    always_ff @(posedge clk) begin
        r <= final_color.r;
        g <= final_color.g;
        b <= final_color.b;
    end
endmodule
