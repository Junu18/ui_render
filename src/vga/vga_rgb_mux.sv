// vga_rgb_mux.sv
// VGA RGB 멀티플렉서 - 모든 렌더러 레이어를 합성

import color_pkg::*;

module vga_rgb_mux (
    input  logic       clk,
    input  logic [9:0] x,          // 0 ~ 639
    input  logic [9:0] y,          // 0 ~ 479
    output logic [7:0] r,          // Red output
    output logic [7:0] g,          // Green output
    output logic [7:0] b           // Blue output
);

    // ========================================
    // 배경 렌더러 신호
    // ========================================
    rgb_t  sky_color, grass_color, dirt_color;
    logic  sky_en, grass_en, dirt_en;

    // Sky renderer (0 ~ 140px)
    sky_renderer sky_inst (
        .x(x),
        .y(y),
        .color(sky_color),
        .enable(sky_en)
    );

    // Grass renderer (140 ~ 150px)
    grass_renderer grass_inst (
        .x(x),
        .y(y),
        .color(grass_color),
        .enable(grass_en)
    );

    // Dirt renderer (150 ~ 180px)
    dirt_renderer dirt_inst (
        .x(x),
        .y(y),
        .color(dirt_color),
        .enable(dirt_en)
    );

    // ========================================
    // 레이어 합성 (우선순위: 위 → 아래)
    // 나중에 player, box 추가 시 여기에 추가
    // ========================================
    rgb_t final_color;

    always_comb begin
        // 기본값: 검정 (화면 밖 영역)
        final_color = BLACK;

        // 우선순위: dirt > grass > sky
        // (현재는 y 영역이 겹치지 않지만, 명확한 구조 유지)
        if (sky_en) begin
            final_color = sky_color;
        end

        if (grass_en) begin
            final_color = grass_color;
        end

        if (dirt_en) begin
            final_color = dirt_color;
        end

        // TODO: 나중에 추가
        // if (player_en) final_color = player_color;
        // if (box_en) final_color = box_color;
    end

    // ========================================
    // 출력 (동기화 - 1 clock delay)
    // ========================================
    always_ff @(posedge clk) begin
        r <= final_color.r;
        g <= final_color.g;
        b <= final_color.b;
    end

endmodule
