// player_renderer.sv
// IC 칩 모양 플레이어 (16x16 픽셀, 상하 핀)

import color_pkg::*;

module player_renderer (
    input  logic [9:0] x,           // 화면 x 좌표
    input  logic [9:0] y,           // 화면 y 좌표
    input  logic [9:0] player_x,    // 플레이어 x 위치
    input  logic [9:0] player_y,    // 플레이어 y 위치
    output rgb_t       color,       // RGB 출력
    output logic       enable       // 이 픽셀 그릴지 여부
);

    // 플레이어 영역 체크 (16x16)
    logic in_player_area;
    logic [3:0] sprite_x;  // 0~15
    logic [3:0] sprite_y;  // 0~15

    assign in_player_area = (x >= player_x) && (x < player_x + 16) &&
                            (y >= player_y) && (y < player_y + 16);
    assign sprite_x = x - player_x;
    assign sprite_y = y - player_y;

    // IC 칩 스프라이트 (16x16)
    // . = 투명, S = 핀(은색), G = 테두리(회색), B = 몸체(검정), R = 빨간점
    always_comb begin
        if (in_player_area) begin
            case (sprite_y)
                // Row 0-1: 위쪽 핀
                4'd0, 4'd1: begin
                    if ((sprite_x >= 2 && sprite_x <= 3) ||   // 첫번째 핀
                        (sprite_x >= 6 && sprite_x <= 7) ||   // 두번째 핀
                        (sprite_x >= 10 && sprite_x <= 11)) begin  // 세번째 핀
                        color = IC_SILVER;
                        enable = 1'b1;
                    end else begin
                        color = TRANSPARENT;
                        enable = 1'b0;  // 투명
                    end
                end

                // Row 2: 테두리 상단
                4'd2: begin
                    if (sprite_x >= 1 && sprite_x <= 14) begin
                        color = IC_GRAY;
                        enable = 1'b1;
                    end else begin
                        color = TRANSPARENT;
                        enable = 1'b0;
                    end
                end

                // Row 3: 테두리 + 몸체
                4'd3: begin
                    if (sprite_x == 1 || sprite_x == 14) begin
                        color = IC_GRAY;
                        enable = 1'b1;
                    end else if (sprite_x >= 2 && sprite_x <= 13) begin
                        color = IC_BLACK;
                        enable = 1'b1;
                    end else begin
                        color = TRANSPARENT;
                        enable = 1'b0;
                    end
                end

                // Row 4-5: 빨간 점 (방향 표시)
                4'd4, 4'd5: begin
                    if (sprite_x == 1 || sprite_x == 14) begin
                        color = IC_GRAY;
                        enable = 1'b1;
                    end else if (sprite_x >= 6 && sprite_x <= 7) begin
                        color = IC_RED;  // 빨간 점
                        enable = 1'b1;
                    end else if (sprite_x >= 2 && sprite_x <= 13) begin
                        color = IC_BLACK;
                        enable = 1'b1;
                    end else begin
                        color = TRANSPARENT;
                        enable = 1'b0;
                    end
                end

                // Row 6-12: 몸체
                4'd6, 4'd7, 4'd8, 4'd9, 4'd10, 4'd11, 4'd12: begin
                    if (sprite_x == 1 || sprite_x == 14) begin
                        color = IC_GRAY;
                        enable = 1'b1;
                    end else if (sprite_x >= 2 && sprite_x <= 13) begin
                        color = IC_BLACK;
                        enable = 1'b1;
                    end else begin
                        color = TRANSPARENT;
                        enable = 1'b0;
                    end
                end

                // Row 13: 테두리 하단
                4'd13: begin
                    if (sprite_x >= 1 && sprite_x <= 14) begin
                        color = IC_GRAY;
                        enable = 1'b1;
                    end else begin
                        color = TRANSPARENT;
                        enable = 1'b0;
                    end
                end

                // Row 14-15: 아래쪽 핀
                4'd14, 4'd15: begin
                    if ((sprite_x >= 2 && sprite_x <= 3) ||
                        (sprite_x >= 6 && sprite_x <= 7) ||
                        (sprite_x >= 10 && sprite_x <= 11)) begin
                        color = IC_SILVER;
                        enable = 1'b1;
                    end else begin
                        color = TRANSPARENT;
                        enable = 1'b0;
                    end
                end

                default: begin
                    color = TRANSPARENT;
                    enable = 1'b0;
                end
            endcase
        end else begin
            color = TRANSPARENT;
            enable = 1'b0;
        end
    end

endmodule
