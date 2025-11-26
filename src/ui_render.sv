// ui_render.sv
// VGA UI 렌더링 Top 모듈 (2인 플레이어 + 깃발, 타일 기반 이동)

import color_pkg::*;

module ui_render (
    input  logic       clk,
    input  logic       reset_n,
    input  logic [9:0] x,             // 0 ~ 639
    input  logic [9:0] y,             // 0 ~ 479

    // Player 1 제어
    input  logic       move_start_p1,
    input  logic [9:0] target_x_p1,
    output logic       turn_done_p1,

    // Player 2 제어
    input  logic       move_start_p2,
    input  logic [9:0] target_x_p2,
    output logic       turn_done_p2,

    output logic [7:0] r,             // Red
    output logic [7:0] g,             // Green
    output logic [7:0] b              // Blue
);

    // 배경 및 오브젝트 색상
    rgb_t  sky_color, grass_color, dirt_color, flag_color;
    logic  sky_en, grass_en, dirt_en, flag_en;

    // 플레이어 렌더링
    rgb_t  player1_color, player2_color;
    logic  player1_en, player2_en;
    logic [9:0] player1_x, player1_y;
    logic [9:0] player2_x, player2_y;

    // 배경 레이어
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

    // 깃발 (x=620 고정)
    flag_renderer #(
        .FLAG_X(620),
        .FLAG_TOP_Y(40),
        .FLAG_HEIGHT(130)
    ) flag_inst (
        .x(x),
        .y(y),
        .color(flag_color),
        .enable(flag_en)
    );

    // 플레이어 FSM
    player_controller #(
        .FLAG_X(620)
    ) player_ctrl_p1 (
        .clk(clk),
        .reset_n(reset_n),
        .move_start(move_start_p1),
        .target_x(target_x_p1),
        .player_x(player1_x),
        .player_y(player1_y),
        .turn_done(turn_done_p1)
    );

    player_controller #(
        .FLAG_X(620)
    ) player_ctrl_p2 (
        .clk(clk),
        .reset_n(reset_n),
        .move_start(move_start_p2),
        .target_x(target_x_p2),
        .player_x(player2_x),
        .player_y(player2_y),
        .turn_done(turn_done_p2)
    );

    // 플레이어 스프라이트
    player_renderer player1_renderer (
        .x(x),
        .y(y),
        .player_id(1'b0),
        .player_x(player1_x),
        .player_y(player1_y),
        .color(player1_color),
        .enable(player1_en)
    );

    player_renderer player2_renderer (
        .x(x),
        .y(y),
        .player_id(1'b1),
        .player_x(player2_x),
        .player_y(player2_y),
        .color(player2_color),
        .enable(player2_en)
    );

    // 레이어 합성 (우선순위: sky → grass → dirt → flag → P1 → P2)
    rgb_t final_color;
    always_comb begin
        final_color = BLACK;

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

        if (player1_en) begin
            final_color = player1_color;
        end

        if (player2_en) begin
            final_color = player2_color;
        end
    end

    // RGB 출력 (1 clock pipeline)
    always_ff @(posedge clk) begin
        r <= final_color.r;
        g <= final_color.g;
        b <= final_color.b;
    end
endmodule
