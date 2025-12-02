// player_renderer.sv (MEM 파일 버전)
// .mem 파일에서 스프라이트 로드

import color_pkg::*;

module player_renderer (
    input  logic [9:0] x,
    input  logic [9:0] y,
    input  logic [9:0] player_x,
    input  logic [9:0] player_y,
    input  logic       player_id,
    output rgb_t       color,
    output logic       enable
);

    // 플레이어 영역 체크 (16x16)
    logic in_player_area;
    logic [3:0] sprite_x;
    logic [3:0] sprite_y;
    logic [7:0] rom_addr;

    assign in_player_area = (x >= player_x) && (x < player_x + 16) &&
                            (y >= player_y) && (y < player_y + 16);
    assign sprite_x = x - player_x;
    assign sprite_y = y - player_y;
    assign rom_addr = {sprite_y, sprite_x};  // y*16 + x (0-255)

    // ============================================
    // 스프라이트 ROM (.mem 파일에서 로드)
    // ============================================

    // Player 1: Kirby sprite ROM
    logic [11:0] kirby_rom [0:255];
    initial begin
        $readmemh("src/kerby.mem", kirby_rom);
    end

    // Player 2: Dee sprite ROM (다른 .mem 파일)
    logic [11:0] dee_rom [0:255];
    initial begin
        $readmemh("src/dee.mem", dee_rom);
    end

    // ROM 데이터 선택
    logic [11:0] rom_data;
    assign rom_data = player_id ? dee_rom[rom_addr] : kirby_rom[rom_addr];

    // RGB 출력
    always_comb begin
        if (in_player_area) begin
            // 투명색 체크 (12'h000 = 검정 = 투명)
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
