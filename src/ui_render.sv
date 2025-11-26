// ui_render.sv
// VGA UI 렌더러 (Top Module)
// 플레이어 2명, 턴제 게임 지원
// Game Logic 인터페이스: pos_x + pos_valid

import color_pkg::*;

module ui_render (
    input  logic       clk,
    input  logic       rst,
    input  logic [9:0] x, y,

    // Player 1 (Game Logic 인터페이스)
    input  logic [9:0] player1_pos_x,      // 목표 x 좌표
    input  logic       player1_pos_valid,  // 위치 업데이트 (1 cycle pulse)
    output logic       player1_turn_done,  // 턴 완료 (1 cycle pulse)

    // Player 2
    input  logic [9:0] player2_pos_x,
    input  logic       player2_pos_valid,
    output logic       player2_turn_done,

    // VGA 출력
    output logic [7:0] r, g, b
);

    // ========================================
    // 내부 신호
    // ========================================
    logic [9:0] player1_x, player1_y, player2_x, player2_y;
    rgb_t sky_color, grass_color, dirt_color, flag_color, player1_color, player2_color;
    logic sky_en, grass_en, dirt_en, flag_en, player1_en, player2_en;

    // ========================================
    // 플레이어 컨트롤러
    // ========================================
    player_controller ctrl (
        .clk(clk),
        .rst(rst),
        .player1_pos_x(player1_pos_x),
        .player1_pos_valid(player1_pos_valid),
        .player1_x(player1_x),
        .player1_y(player1_y),
        .player1_turn_done(player1_turn_done),
        .player2_pos_x(player2_pos_x),
        .player2_pos_valid(player2_pos_valid),
        .player2_x(player2_x),
        .player2_y(player2_y),
        .player2_turn_done(player2_turn_done)
    );

    // ========================================
    // 배경 렌더러
    // ========================================
    sky_renderer sky_inst (
        .x(x),
        .y(y),
        .color(sky_color),
        .enable(sky_en)
    );

    grass_renderer grass_inst (
        .x(x),
        .y(y),
        .color(grass_color),
        .enable(grass_en)
    );

    dirt_renderer dirt_inst (
        .x(x),
        .y(y),
        .color(dirt_color),
        .enable(dirt_en)
    );

    // ========================================
    // 깃발 렌더러
    // ========================================
    flag_renderer flag_inst (
        .x(x),
        .y(y),
        .color(flag_color),
        .enable(flag_en)
    );

    // ========================================
    // 플레이어 렌더러 (2명)
    // ========================================
    player_renderer player1_inst (
        .x(x),
        .y(y),
        .player_x(player1_x),
        .player_y(player1_y),
        .player_id(1'b0),           // Player 1 (빨강)
        .color(player1_color),
        .enable(player1_en)
    );

    player_renderer player2_inst (
        .x(x),
        .y(y),
        .player_x(player2_x),
        .player_y(player2_y),
        .player_id(1'b1),           // Player 2 (파랑)
        .color(player2_color),
        .enable(player2_en)
    );

    // ========================================
    // 레이어 합성 (우선순위: player1 > player2 > flag > dirt > grass > sky)
    // ========================================
    rgb_t final_color;

    always_comb begin
        final_color = BLACK;

        if (sky_en)     final_color = sky_color;
        if (grass_en)   final_color = grass_color;
        if (dirt_en)    final_color = dirt_color;
        if (flag_en)    final_color = flag_color;
        if (player2_en) final_color = player2_color;
        if (player1_en) final_color = player1_color;
    end

    // ========================================
    // VGA 출력 (1 clock delay)
    // ========================================
    always_ff @(posedge clk) begin
        r <= final_color.r;
        g <= final_color.g;
        b <= final_color.b;
    end

endmodule
