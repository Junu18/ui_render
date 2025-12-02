// player_renderer.sv (BMP ROM 버전)
// 16x16 픽셀 플레이어 (.bmp 이미지 사용)
// Player 1: Christmas Kirby
// Player 2: Blue Bandana Dee

import color_pkg::*;

module player_renderer (
    input  logic [9:0] x,           // 화면 x 좌표
    input  logic [9:0] y,           // 화면 y 좌표
    input  logic [9:0] player_x,    // 플레이어 x 위치
    input  logic [9:0] player_y,    // 플레이어 y 위치
    input  logic       player_id,   // 0=Player1(Kirby), 1=Player2(Dee)
    output rgb_t       color,       // RGB 출력
    output logic       enable       // 이 픽셀 그릴지 여부
);

    // 플레이어 영역 체크 (16x16)
    logic in_player_area;
    logic [3:0] sprite_x;  // 0~15
    logic [3:0] sprite_y;  // 0~15
    logic [7:0] rom_addr;  // 0~255 (16x16)

    assign in_player_area = (x >= player_x) && (x < player_x + 16) &&
                            (y >= player_y) && (y < player_y + 16);
    assign sprite_x = x - player_x;
    assign sprite_y = y - player_y;
    assign rom_addr = {sprite_y, sprite_x};  // y*16 + x

    // ============================================
    // 스프라이트 ROM (16x16 = 256 pixels)
    // RGB444 형식 (12비트): {R[3:0], G[3:0], B[3:0]}
    // ============================================

    // Player 1: Christmas Kirby ROM
    // TODO: .bmp 파일을 변환해서 여기에 넣으세요
    localparam logic [11:0] KIRBY_ROM [0:255] = '{
        // Row 0 (16 pixels)
        12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000,
        12'hFFF, 12'hFFF, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000,

        // Row 1-15...
        // (여기에 나머지 240개 픽셀 데이터)
        // 지금은 예시로 투명 픽셀로 채움
        12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000,
        12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000,
        // ... (248개 더)
        // FIXME: Python 스크립트로 실제 데이터 생성 필요
        default: 12'h000
    };

    // Player 2: Bandana Dee ROM
    localparam logic [11:0] DEE_ROM [0:255] = '{
        // Row 0-15...
        // TODO: .bmp 파일을 변환해서 여기에 넣으세요
        default: 12'h000
    };

    // ROM 읽기
    logic [11:0] rom_data;
    assign rom_data = player_id ? DEE_ROM[rom_addr] : KIRBY_ROM[rom_addr];

    // RGB 출력
    always_comb begin
        if (in_player_area) begin
            // 투명색 체크 (예: 순수 검정 = 투명)
            if (rom_data == 12'h000) begin
                enable = 1'b0;
                color = TRANSPARENT;
            end else begin
                enable = 1'b1;
                // RGB444 → RGB888 변환
                color.r = {rom_data[11:8], rom_data[11:8]};  // R4 → R8
                color.g = {rom_data[7:4], rom_data[7:4]};     // G4 → G8
                color.b = {rom_data[3:0], rom_data[3:0]};     // B4 → B8
            end
        end else begin
            enable = 1'b0;
            color = TRANSPARENT;
        end
    end

endmodule
