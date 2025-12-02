// player_renderer.sv
// 16x16 픽셀 플레이어 (측면 뷰 - 오른쪽 보기)
// Player 1: Christmas Kirby (핑크 몸체 + 빨간 산타모자)
// Player 2: Blue Bandana Dee (살색 몸체 + 파란 두건)

import color_pkg::*;

module player_renderer (
    input  logic [9:0] x,           // 화면 x 좌표
    input  logic [9:0] y,           // 화면 y 좌표
    input  logic [9:0] player_x,    // 플레이어 x 위치
    input  logic [9:0] player_y,    // 플레이어 y 위치
    input  logic       player_id,   // 0=Player1(Christmas Kirby), 1=Player2(Bandana Dee)
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

    // 색상 정의
    // Kirby 색상
    localparam rgb_t KIRBY_PINK       = '{r: 8'd255, g: 8'd182, b: 8'd193};  // 밝은 핑크
    localparam rgb_t KIRBY_PINK_DARK  = '{r: 8'd255, g: 8'd130, b: 8'd150};  // 어두운 핑크
    localparam rgb_t KIRBY_ROSY       = '{r: 8'd255, g: 8'd120, b: 8'd140};  // 볼터치
    localparam rgb_t KIRBY_FEET_RED   = '{r: 8'd220, g: 8'd60,  b: 8'd80};   // 빨간 발

    // Waddle Dee 색상
    localparam rgb_t BODY_PEACH       = '{r: 8'd255, g: 8'd220, b: 8'd180};  // 살색 몸통
    localparam rgb_t BODY_PEACH_DARK  = '{r: 8'd230, g: 8'd180, b: 8'd140};  // 어두운 살색
    localparam rgb_t BODY_ORANGE      = '{r: 8'd255, g: 8'd150, b: 8'd100};  // 주황 몸통
    localparam rgb_t BODY_ORANGE_DARK = '{r: 8'd220, g: 8'd100, b: 8'd60};   // 어두운 주황
    localparam rgb_t BLUSH_ORANGE     = '{r: 8'd255, g: 8'd140, b: 8'd100};  // 주황 볼터치
    localparam rgb_t FEET_YELLOW      = '{r: 8'd255, g: 8'd200, b: 8'd50};   // 노란 발
    localparam rgb_t FEET_YELLOW_DARK = '{r: 8'd220, g: 8'd160, b: 8'd30};   // 어두운 노랑

    // 공통 색상
    localparam rgb_t BLUE_BANDANA     = '{r: 8'd50,  g: 8'd100, b: 8'd200};  // 파란 두건
    localparam rgb_t BLUE_DARK        = '{r: 8'd30,  g: 8'd70,  b: 8'd150};  // 어두운 파랑
    localparam rgb_t RED_HAT          = '{r: 8'd220, g: 8'd20,  b: 8'd60};   // 빨간 모자
    localparam rgb_t RED_DARK         = '{r: 8'd150, g: 8'd10,  b: 8'd40};   // 어두운 빨강
    localparam rgb_t WHITE            = '{r: 8'd255, g: 8'd255, b: 8'd255};  // 흰색
    localparam rgb_t BLACK            = '{r: 8'd0,   g: 8'd0,   b: 8'd0};    // 검정

    // 스프라이트 (16x16, 측면 뷰 - 오른쪽 보기)
    always_comb begin
        if (in_player_area) begin
            enable = 1'b0;
            color = TRANSPARENT;

            if (player_id == 1'b0) begin
                // ========================================
                // Player 1: Christmas Kirby (핑크 몸체 + 산타모자)
                // ========================================
                case (sprite_y)
                    // Row 0: 모자 꼭대기 (흰색 폼폼)
                    4'd0: begin
                        if (sprite_x >= 7 && sprite_x <= 10) begin
                            color = WHITE;
                            enable = 1'b1;
                        end
                    end

                    // Row 1: 모자 상단
                    4'd1: begin
                        if (sprite_x >= 6 && sprite_x <= 11) begin
                            color = (sprite_x == 6 || sprite_x == 11) ? RED_DARK : RED_HAT;
                            enable = 1'b1;
                        end
                    end

                    // Row 2: 모자
                    4'd2: begin
                        if (sprite_x >= 5 && sprite_x <= 12) begin
                            color = (sprite_x == 5 || sprite_x == 12) ? RED_DARK : RED_HAT;
                            enable = 1'b1;
                        end
                    end

                    // Row 3: 모자 테두리 (흰색)
                    4'd3: begin
                        if (sprite_x >= 4 && sprite_x <= 12) begin
                            color = WHITE;
                            enable = 1'b1;
                        end
                    end

                    // Row 4: 몸체 시작
                    4'd4: begin
                        if (sprite_x >= 3 && sprite_x <= 12) begin
                            if (sprite_x == 3 || sprite_x == 12) begin
                                color = KIRBY_PINK_DARK;
                            end else begin
                                color = KIRBY_PINK;
                            end
                            enable = 1'b1;
                        end
                    end

                    // Row 5-6: 눈 (오른쪽 위치)
                    4'd5, 4'd6: begin
                        if (sprite_x >= 2 && sprite_x <= 14) begin
                            if (sprite_x >= 9 && sprite_x <= 11) begin
                                color = BLACK;  // 눈
                            end else if (sprite_x == 2 || sprite_x == 14) begin
                                color = KIRBY_PINK_DARK;
                            end else begin
                                color = KIRBY_PINK;
                            end
                            enable = 1'b1;
                        end
                    end

                    // Row 7-8: 몸체
                    4'd7, 4'd8: begin
                        if (sprite_x >= 1 && sprite_x <= 14) begin
                            if (sprite_x == 1 || sprite_x == 14) begin
                                color = KIRBY_PINK_DARK;
                            end else begin
                                color = KIRBY_PINK;
                            end
                            enable = 1'b1;
                        end
                    end

                    // Row 9: 볼터치 (오른쪽)
                    4'd9: begin
                        if (sprite_x >= 1 && sprite_x <= 14) begin
                            if (sprite_x >= 11 && sprite_x <= 12) begin
                                color = KIRBY_ROSY;  // 볼터치
                            end else if (sprite_x == 1 || sprite_x == 14) begin
                                color = KIRBY_PINK_DARK;
                            end else begin
                                color = KIRBY_PINK;
                            end
                            enable = 1'b1;
                        end
                    end

                    // Row 10: 몸체
                    4'd10: begin
                        if (sprite_x >= 1 && sprite_x <= 14) begin
                            if (sprite_x == 1 || sprite_x == 14) begin
                                color = KIRBY_PINK_DARK;
                            end else begin
                                color = KIRBY_PINK;
                            end
                            enable = 1'b1;
                        end
                    end

                    // Row 11: 몸체 하단
                    4'd11: begin
                        if (sprite_x >= 2 && sprite_x <= 13) begin
                            if (sprite_x == 2 || sprite_x == 13) begin
                                color = KIRBY_PINK_DARK;
                            end else begin
                                color = KIRBY_PINK;
                            end
                            enable = 1'b1;
                        end
                    end

                    // Row 12: 몸체 하단
                    4'd12: begin
                        if (sprite_x >= 3 && sprite_x <= 12) begin
                            color = KIRBY_PINK;
                            enable = 1'b1;
                        end
                    end

                    // Row 13: 몸체 최하단
                    4'd13: begin
                        if (sprite_x >= 4 && sprite_x <= 11) begin
                            color = KIRBY_PINK;
                            enable = 1'b1;
                        end
                    end

                    // Row 14-15: 발 (빨간색)
                    4'd14, 4'd15: begin
                        if ((sprite_x >= 5 && sprite_x <= 6) || (sprite_x >= 9 && sprite_x <= 10)) begin
                            color = KIRBY_FEET_RED;
                            enable = 1'b1;
                        end
                    end

                    default: begin
                        enable = 1'b0;
                        color = TRANSPARENT;
                    end
                endcase

            end else begin
                // ========================================
                // Player 2: Blue Bandana Dee (살색 몸체 + 파란 두건)
                // ========================================
                case (sprite_y)
                    // Row 0: 두건 상단
                    4'd0: begin
                        if (sprite_x >= 6 && sprite_x <= 11) begin
                            color = (sprite_x == 6 || sprite_x == 11) ? BLUE_DARK : BLUE_BANDANA;
                            enable = 1'b1;
                        end
                    end

                    // Row 1: 두건
                    4'd1: begin
                        if (sprite_x >= 5 && sprite_x <= 12) begin
                            color = (sprite_x == 5 || sprite_x == 12) ? BLUE_DARK : BLUE_BANDANA;
                            enable = 1'b1;
                        end
                    end

                    // Row 2: 두건 + 얼굴 시작
                    4'd2: begin
                        if (sprite_x >= 4 && sprite_x <= 13) begin
                            if (sprite_x >= 9 && sprite_x <= 13) begin
                                color = (sprite_x == 13) ? BLUE_DARK : BLUE_BANDANA;
                            end else begin
                                color = BODY_PEACH;
                            end
                            enable = 1'b1;
                        end
                    end

                    // Row 3: 두건 끝 + 얼굴
                    4'd3: begin
                        if (sprite_x >= 3 && sprite_x <= 13) begin
                            if (sprite_x >= 10 && sprite_x <= 13) begin
                                color = BLUE_BANDANA;
                            end else begin
                                color = (sprite_x == 3) ? BODY_PEACH_DARK : BODY_PEACH;
                            end
                            enable = 1'b1;
                        end
                    end

                    // Row 4: 얼굴
                    4'd4: begin
                        if (sprite_x >= 2 && sprite_x <= 13) begin
                            if (sprite_x == 2 || sprite_x == 13) begin
                                color = BODY_PEACH_DARK;
                            end else begin
                                color = BODY_PEACH;
                            end
                            enable = 1'b1;
                        end
                    end

                    // Row 5-6: 눈 (오른쪽 위치)
                    4'd5, 4'd6: begin
                        if (sprite_x >= 2 && sprite_x <= 14) begin
                            if (sprite_x >= 9 && sprite_x <= 11) begin
                                color = BLACK;  // 눈
                            end else if (sprite_x == 2 || sprite_x == 14) begin
                                color = BODY_PEACH_DARK;
                            end else begin
                                color = BODY_PEACH;
                            end
                            enable = 1'b1;
                        end
                    end

                    // Row 7: 얼굴에서 몸통으로 전환
                    4'd7: begin
                        if (sprite_x >= 1 && sprite_x <= 14) begin
                            if (sprite_x == 1 || sprite_x == 14) begin
                                color = BODY_PEACH_DARK;
                            end else begin
                                color = BODY_PEACH;
                            end
                            enable = 1'b1;
                        end
                    end

                    // Row 8: 몸통 (주황색 시작)
                    4'd8: begin
                        if (sprite_x >= 1 && sprite_x <= 14) begin
                            if (sprite_x == 1 || sprite_x == 14) begin
                                color = BODY_ORANGE_DARK;
                            end else if (sprite_x >= 11 && sprite_x <= 12) begin
                                color = BLUSH_ORANGE;  // 볼터치
                            end else begin
                                color = BODY_ORANGE;
                            end
                            enable = 1'b1;
                        end
                    end

                    // Row 9-10: 주황 몸통
                    4'd9, 4'd10: begin
                        if (sprite_x >= 1 && sprite_x <= 14) begin
                            if (sprite_x == 1 || sprite_x == 14) begin
                                color = BODY_ORANGE_DARK;
                            end else begin
                                color = BODY_ORANGE;
                            end
                            enable = 1'b1;
                        end
                    end

                    // Row 11: 몸통 하단
                    4'd11: begin
                        if (sprite_x >= 2 && sprite_x <= 13) begin
                            if (sprite_x == 2 || sprite_x == 13) begin
                                color = BODY_ORANGE_DARK;
                            end else begin
                                color = BODY_ORANGE;
                            end
                            enable = 1'b1;
                        end
                    end

                    // Row 12: 몸통 하단
                    4'd12: begin
                        if (sprite_x >= 3 && sprite_x <= 12) begin
                            color = BODY_ORANGE;
                            enable = 1'b1;
                        end
                    end

                    // Row 13: 몸통 최하단
                    4'd13: begin
                        if (sprite_x >= 4 && sprite_x <= 11) begin
                            color = BODY_ORANGE;
                            enable = 1'b1;
                        end
                    end

                    // Row 14: 발
                    4'd14: begin
                        if ((sprite_x >= 4 && sprite_x <= 6) || (sprite_x >= 9 && sprite_x <= 11)) begin
                            color = FEET_YELLOW;
                            enable = 1'b1;
                        end
                    end

                    // Row 15: 발 하단
                    4'd15: begin
                        if ((sprite_x >= 4 && sprite_x <= 6) || (sprite_x >= 9 && sprite_x <= 11)) begin
                            color = (sprite_x == 6 || sprite_x == 11) ? FEET_YELLOW_DARK : FEET_YELLOW;
                            enable = 1'b1;
                        end
                    end

                    default: begin
                        enable = 1'b0;
                        color = TRANSPARENT;
                    end
                endcase
            end

        end else begin
            enable = 1'b0;
            color = TRANSPARENT;
        end
    end

endmodule
