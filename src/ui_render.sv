// ui_render.sv
// NES 보드 게임 스타일 UI 렌더러 (All-in-one)
// 배경: 하늘(0~140px) + 잔디(140~150px) + 흙(150~180px)

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

    // 기본
    parameter rgb_t BLACK          = '{r: 8'h00, g: 8'h00, b: 8'h00};
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
                color = GRASS_BRIGHT;  // 밝은 초록 윗줄
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
// UI 렌더러 (Top Module)
// ============================================
module ui_render (
    input  logic       clk,
    input  logic [9:0] x,          // 0 ~ 639
    input  logic [9:0] y,          // 0 ~ 479
    output logic [7:0] r,          // Red
    output logic [7:0] g,          // Green
    output logic [7:0] b           // Blue
);

    // 렌더러 신호
    rgb_t  sky_color, grass_color, dirt_color;
    logic  sky_en, grass_en, dirt_en;

    // 렌더러 인스턴스
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

    // 레이어 합성
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
    end

    // 출력 (1 clock delay)
    always_ff @(posedge clk) begin
        r <= final_color.r;
        g <= final_color.g;
        b <= final_color.b;
    end

endmodule
