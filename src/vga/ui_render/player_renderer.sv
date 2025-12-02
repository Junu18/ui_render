// player_renderer.sv
// 16x16 픽셀 플레이어 (측면 뷰 - 오른쪽 보기)
// Player 1: Christmas Kirby - 핑크 커비 + 산타모자
// Player 2: Blue Bandana Dee - 살색/주황 + 파란 두건

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

    // ============================================
    // 색상 정의 (제공된 이미지 기반)
    // ============================================

    // Christmas Kirby 색상 (이미지 참고)
    localparam rgb_t KIRBY_PINK        = '{r: 8'd255, g: 8'd182, b: 8'd193};  // 핑크 몸체
    localparam rgb_t KIRBY_PINK_DARK   = '{r: 8'd230, g: 8'd140, b: 8'd160};  // 어두운 핑크
    localparam rgb_t KIRBY_BLUSH       = '{r: 8'd255, g: 8'd150, b: 8'd180};  // 볼터치
    localparam rgb_t KIRBY_EYE_BLACK   = '{r: 8'd0,   g: 8'd0,   b: 8'd0};    // 눈 테두리
    localparam rgb_t KIRBY_EYE_WHITE   = '{r: 8'd255, g: 8'd255, b: 8'd255};  // 눈 흰자
    localparam rgb_t KIRBY_EYE_BLUE    = '{r: 8'd100, g: 8'd180, b: 8'd255};  // 눈 하이라이트
    localparam rgb_t KIRBY_MOUTH_RED   = '{r: 8'd200, g: 8'd50,  b: 8'd80};   // 입
    localparam rgb_t KIRBY_MOUTH_DARK  = '{r: 8'd150, g: 8'd30,  b: 8'd50};   // 입 안쪽
    localparam rgb_t KIRBY_FEET_RED    = '{r: 8'd220, g: 8'd60,  b: 8'd80};   // 발

    // Santa Hat 색상
    localparam rgb_t HAT_RED           = '{r: 8'd220, g: 8'd20,  b: 8'd60};   // 빨간 모자
    localparam rgb_t HAT_RED_DARK      = '{r: 8'd150, g: 8'd10,  b: 8'd40};   // 어두운 빨강
    localparam rgb_t HAT_WHITE         = '{r: 8'd255, g: 8'd255, b: 8'd255};  // 흰색 테두리

    // Bandana Dee 색상
    localparam rgb_t DEE_PEACH         = '{r: 8'd255, g: 8'd220, b: 8'd180};  // 살색
    localparam rgb_t DEE_PEACH_DARK    = '{r: 8'd230, g: 8'd180, b: 8'd140};  // 어두운 살색
    localparam rgb_t DEE_ORANGE        = '{r: 8'd255, g: 8'd150, b: 8'd100};  // 주황
    localparam rgb_t DEE_ORANGE_DARK   = '{r: 8'd220, g: 8'd100, b: 8'd60};   // 어두운 주황
    localparam rgb_t DEE_BLUSH         = '{r: 8'd255, g: 8'd140, b: 8'd100};  // 볼터치
    localparam rgb_t DEE_FEET_YELLOW   = '{r: 8'd255, g: 8'd200, b: 8'd50};   // 노란 발
    localparam rgb_t BANDANA_BLUE      = '{r: 8'd50,  g: 8'd100, b: 8'd200};  // 파란 두건
    localparam rgb_t BANDANA_BLUE_DARK = '{r: 8'd30,  g: 8'd70,  b: 8'd150};  // 어두운 파랑

    localparam rgb_t BLACK = '{r: 8'd0, g: 8'd0, b: 8'd0};

    // 스프라이트 렌더링
    always_comb begin
        if (in_player_area) begin
            enable = 1'b0;
            color = TRANSPARENT;

            if (player_id == 1'b0) begin
                // ========================================
                // Player 1: Christmas Kirby (이미지 기반 픽셀 아트)
                // ========================================
                case (sprite_y)
                    // Row 0: 산타모자 폼폼
                    4'd0: begin
                        case (sprite_x)
                            4'd7, 4'd8, 4'd9: begin color = HAT_WHITE; enable = 1'b1; end
                            default: begin enable = 1'b0; end
                        endcase
                    end

                    // Row 1-2: 산타모자 상단
                    4'd1, 4'd2: begin
                        case (sprite_x)
                            4'd6, 4'd10: begin color = HAT_RED_DARK; enable = 1'b1; end
                            4'd7, 4'd8, 4'd9: begin color = HAT_RED; enable = 1'b1; end
                            default: begin enable = 1'b0; end
                        endcase
                    end

                    // Row 3: 산타모자 흰 테두리
                    4'd3: begin
                        case (sprite_x)
                            4'd5, 4'd6, 4'd7, 4'd8, 4'd9, 4'd10, 4'd11: begin
                                color = HAT_WHITE; enable = 1'b1;
                            end
                            default: begin enable = 1'b0; end
                        endcase
                    end

                    // Row 4-5: 핑크 머리 상단
                    4'd4, 4'd5: begin
                        case (sprite_x)
                            4'd4, 4'd11: begin color = KIRBY_PINK_DARK; enable = 1'b1; end
                            4'd5, 4'd6, 4'd7, 4'd8, 4'd9, 4'd10: begin
                                color = KIRBY_PINK; enable = 1'b1;
                            end
                            default: begin enable = 1'b0; end
                        endcase
                    end

                    // Row 6: 눈 시작 (큰 타원형 눈)
                    4'd6: begin
                        case (sprite_x)
                            4'd3, 4'd12: begin color = KIRBY_PINK_DARK; enable = 1'b1; end
                            4'd4, 4'd5, 4'd10, 4'd11: begin color = KIRBY_PINK; enable = 1'b1; end
                            4'd6, 4'd7: begin color = KIRBY_EYE_BLACK; enable = 1'b1; end  // 왼쪽 눈 테두리
                            4'd8, 4'd9: begin color = KIRBY_PINK; enable = 1'b1; end
                            default: begin enable = 1'b0; end
                        endcase
                    end

                    // Row 7: 눈 (흰자 + 파란 하이라이트)
                    4'd7: begin
                        case (sprite_x)
                            4'd3, 4'd12: begin color = KIRBY_PINK_DARK; enable = 1'b1; end
                            4'd4, 4'd5: begin color = KIRBY_PINK; enable = 1'b1; end
                            4'd6: begin color = KIRBY_EYE_BLACK; enable = 1'b1; end
                            4'd7: begin color = KIRBY_EYE_WHITE; enable = 1'b1; end  // 눈 흰자
                            4'd8: begin color = KIRBY_EYE_BLUE; enable = 1'b1; end   // 파란 하이라이트
                            4'd9: begin color = KIRBY_EYE_BLACK; enable = 1'b1; end
                            4'd10, 4'd11: begin color = KIRBY_PINK; enable = 1'b1; end
                            default: begin enable = 1'b0; end
                        endcase
                    end

                    // Row 8: 눈 아래 + 볼터치 시작
                    4'd8: begin
                        case (sprite_x)
                            4'd2, 4'd13: begin color = KIRBY_PINK_DARK; enable = 1'b1; end
                            4'd3, 4'd4, 4'd5: begin color = KIRBY_PINK; enable = 1'b1; end
                            4'd6, 4'd7: begin color = KIRBY_EYE_BLACK; enable = 1'b1; end
                            4'd8, 4'd9: begin color = KIRBY_PINK; enable = 1'b1; end
                            4'd10, 4'd11: begin color = KIRBY_BLUSH; enable = 1'b1; end  // 볼터치
                            4'd12: begin color = KIRBY_PINK; enable = 1'b1; end
                            default: begin enable = 1'b0; end
                        endcase
                    end

                    // Row 9: 입 (빨간 미소)
                    4'd9: begin
                        case (sprite_x)
                            4'd2, 4'd13: begin color = KIRBY_PINK_DARK; enable = 1'b1; end
                            4'd3, 4'd4, 4'd5: begin color = KIRBY_PINK; enable = 1'b1; end
                            4'd6, 4'd9: begin color = KIRBY_MOUTH_RED; enable = 1'b1; end  // 입 가장자리
                            4'd7, 4'd8: begin color = KIRBY_MOUTH_DARK; enable = 1'b1; end // 입 안
                            4'd10, 4'd11, 4'd12: begin color = KIRBY_PINK; enable = 1'b1; end
                            default: begin enable = 1'b0; end
                        endcase
                    end

                    // Row 10-11: 하단 몸체
                    4'd10, 4'd11: begin
                        case (sprite_x)
                            4'd3, 4'd12: begin color = KIRBY_PINK_DARK; enable = 1'b1; end
                            4'd4, 4'd5, 4'd6, 4'd7, 4'd8, 4'd9, 4'd10, 4'd11: begin
                                color = KIRBY_PINK; enable = 1'b1;
                            end
                            default: begin enable = 1'b0; end
                        endcase
                    end

                    // Row 12: 하단 (좁아짐)
                    4'd12: begin
                        case (sprite_x)
                            4'd4, 4'd5, 4'd6, 4'd7, 4'd8, 4'd9, 4'd10, 4'd11: begin
                                color = KIRBY_PINK; enable = 1'b1;
                            end
                            default: begin enable = 1'b0; end
                        endcase
                    end

                    // Row 13: 몸체 끝
                    4'd13: begin
                        case (sprite_x)
                            4'd5, 4'd6, 4'd7, 4'd8, 4'd9, 4'd10: begin
                                color = KIRBY_PINK; enable = 1'b1;
                            end
                            default: begin enable = 1'b0; end
                        endcase
                    end

                    // Row 14-15: 빨간 발
                    4'd14, 4'd15: begin
                        case (sprite_x)
                            4'd5, 4'd6, 4'd9, 4'd10: begin
                                color = KIRBY_FEET_RED; enable = 1'b1;
                            end
                            default: begin enable = 1'b0; end
                        endcase
                    end

                    default: begin
                        enable = 1'b0;
                        color = TRANSPARENT;
                    end
                endcase

            end else begin
                // ========================================
                // Player 2: Blue Bandana Dee
                // ========================================
                case (sprite_y)
                    // Row 0-1: 파란 두건 상단
                    4'd0: begin
                        case (sprite_x)
                            4'd7, 4'd8, 4'd9: begin color = BANDANA_BLUE; enable = 1'b1; end
                            default: begin enable = 1'b0; end
                        endcase
                    end

                    4'd1: begin
                        case (sprite_x)
                            4'd6, 4'd10: begin color = BANDANA_BLUE_DARK; enable = 1'b1; end
                            4'd7, 4'd8, 4'd9: begin color = BANDANA_BLUE; enable = 1'b1; end
                            default: begin enable = 1'b0; end
                        endcase
                    end

                    // Row 2: 두건 + 얼굴 시작
                    4'd2: begin
                        case (sprite_x)
                            4'd5: begin color = DEE_PEACH_DARK; enable = 1'b1; end
                            4'd6, 4'd7, 4'd8: begin color = DEE_PEACH; enable = 1'b1; end
                            4'd9, 4'd10, 4'd11: begin color = BANDANA_BLUE; enable = 1'b1; end
                            4'd12: begin color = BANDANA_BLUE_DARK; enable = 1'b1; end
                            default: begin enable = 1'b0; end
                        endcase
                    end

                    // Row 3: 두건 끝 + 얼굴
                    4'd3: begin
                        case (sprite_x)
                            4'd4: begin color = DEE_PEACH_DARK; enable = 1'b1; end
                            4'd5, 4'd6, 4'd7, 4'd8, 4'd9: begin color = DEE_PEACH; enable = 1'b1; end
                            4'd10, 4'd11: begin color = BANDANA_BLUE; enable = 1'b1; end
                            default: begin enable = 1'b0; end
                        endcase
                    end

                    // Row 4-5: 살색 얼굴
                    4'd4, 4'd5: begin
                        case (sprite_x)
                            4'd3, 4'd11: begin color = DEE_PEACH_DARK; enable = 1'b1; end
                            4'd4, 4'd5, 4'd6, 4'd7, 4'd8, 4'd9, 4'd10: begin
                                color = DEE_PEACH; enable = 1'b1;
                            end
                            default: begin enable = 1'b0; end
                        endcase
                    end

                    // Row 6: 눈 시작
                    4'd6: begin
                        case (sprite_x)
                            4'd3, 4'd12: begin color = DEE_PEACH_DARK; enable = 1'b1; end
                            4'd4, 4'd5: begin color = DEE_PEACH; enable = 1'b1; end
                            4'd6, 4'd7: begin color = BLACK; enable = 1'b1; end  // 왼쪽 눈
                            4'd8, 4'd9, 4'd10, 4'd11: begin color = DEE_PEACH; enable = 1'b1; end
                            default: begin enable = 1'b0; end
                        endcase
                    end

                    // Row 7: 눈 (흰자)
                    4'd7: begin
                        case (sprite_x)
                            4'd2, 4'd13: begin color = DEE_PEACH_DARK; enable = 1'b1; end
                            4'd3, 4'd4, 4'd5: begin color = DEE_PEACH; enable = 1'b1; end
                            4'd6: begin color = BLACK; enable = 1'b1; end
                            4'd7: begin color = KIRBY_EYE_WHITE; enable = 1'b1; end
                            4'd8: begin color = KIRBY_EYE_BLUE; enable = 1'b1; end
                            4'd9: begin color = BLACK; enable = 1'b1; end
                            4'd10, 4'd11, 4'd12: begin color = DEE_PEACH; enable = 1'b1; end
                            default: begin enable = 1'b0; end
                        endcase
                    end

                    // Row 8: 주황색 몸통 시작 + 볼터치
                    4'd8: begin
                        case (sprite_x)
                            4'd2, 4'd13: begin color = DEE_ORANGE_DARK; enable = 1'b1; end
                            4'd3, 4'd4, 4'd5: begin color = DEE_ORANGE; enable = 1'b1; end
                            4'd6, 4'd7: begin color = BLACK; enable = 1'b1; end
                            4'd8, 4'd9: begin color = DEE_ORANGE; enable = 1'b1; end
                            4'd10, 4'd11: begin color = DEE_BLUSH; enable = 1'b1; end
                            4'd12: begin color = DEE_ORANGE; enable = 1'b1; end
                            default: begin enable = 1'b0; end
                        endcase
                    end

                    // Row 9-11: 주황 몸통 (넓어짐)
                    4'd9, 4'd10, 4'd11: begin
                        case (sprite_x)
                            4'd1, 4'd14: begin color = DEE_ORANGE_DARK; enable = 1'b1; end
                            4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd8, 4'd9, 4'd10, 4'd11, 4'd12, 4'd13: begin
                                color = DEE_ORANGE; enable = 1'b1;
                            end
                            default: begin enable = 1'b0; end
                        endcase
                    end

                    // Row 12: 하단 (좁아짐)
                    4'd12: begin
                        case (sprite_x)
                            4'd2, 4'd13: begin color = DEE_ORANGE_DARK; enable = 1'b1; end
                            4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd8, 4'd9, 4'd10, 4'd11, 4'd12: begin
                                color = DEE_ORANGE; enable = 1'b1;
                            end
                            default: begin enable = 1'b0; end
                        endcase
                    end

                    // Row 13: 몸체 끝
                    4'd13: begin
                        case (sprite_x)
                            4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd8, 4'd9, 4'd10, 4'd11, 4'd12: begin
                                color = DEE_ORANGE; enable = 1'b1;
                            end
                            default: begin enable = 1'b0; end
                        endcase
                    end

                    // Row 14-15: 노란 발
                    4'd14, 4'd15: begin
                        case (sprite_x)
                            4'd4, 4'd5, 4'd6, 4'd10, 4'd11, 4'd12: begin
                                color = DEE_FEET_YELLOW; enable = 1'b1;
                            end
                            default: begin enable = 1'b0; end
                        endcase
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
