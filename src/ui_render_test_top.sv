// ui_render_test_top.sv
// UI Render 테스트용 Top 모듈
// 버튼으로 Game Logic 시뮬레이션 (pos_x + pos_valid 생성)

module ui_render_test_top (
    input  logic       clk_100mhz,    // 100MHz 보드 클럭
    input  logic       btn_reset,     // 리셋 버튼 (active high)

    // 테스트용 버튼
    input  logic       btnL,          // Player 1: 1칸 이동 (60px)
    input  logic       btnU,          // Player 1: 2칸 이동 (120px)
    input  logic       btnR,          // Player 1: 3칸 이동 (180px)

    // VGA 출력
    output logic       vga_hsync,
    output logic       vga_vsync,
    output logic [3:0] vga_r,
    output logic [3:0] vga_g,
    output logic [3:0] vga_b,

    // 디버그 LED
    output logic [3:0] led
);

    // ========================================
    // 클럭 생성 (100MHz → 25MHz)
    // ========================================
    logic clk_25mhz;
    logic [1:0] clk_div;

    always_ff @(posedge clk_100mhz or posedge btn_reset) begin
        if (btn_reset)
            clk_div <= 2'b00;
        else
            clk_div <= clk_div + 1;
    end

    assign clk_25mhz = clk_div[1];  // 100MHz / 4 = 25MHz

    // ========================================
    // VGA 타이밍 생성
    // ========================================
    logic vga_de;
    logic [9:0] vga_x, vga_y;

    VGA_Syncher vga_sync (
        .clk(clk_25mhz),
        .reset(btn_reset),
        .h_sync(vga_hsync),
        .v_sync(vga_vsync),
        .DE(vga_de),
        .x_pixel(vga_x),
        .y_pixel(vga_y)
    );

    // ========================================
    // 버튼 디바운서 + Edge Detector
    // ========================================
    logic btnL_sync, btnU_sync, btnR_sync;
    logic btnL_prev, btnU_prev, btnR_prev;
    logic btnL_pulse, btnU_pulse, btnR_pulse;

    // 동기화 (메타스테이블리티 방지)
    always_ff @(posedge clk_25mhz) begin
        btnL_sync <= btnL;
        btnU_sync <= btnU;
        btnR_sync <= btnR;
    end

    // Edge detection
    always_ff @(posedge clk_25mhz or posedge btn_reset) begin
        if (btn_reset) begin
            btnL_prev <= 1'b0;
            btnU_prev <= 1'b0;
            btnR_prev <= 1'b0;
        end else begin
            btnL_prev <= btnL_sync;
            btnU_prev <= btnU_sync;
            btnR_prev <= btnR_sync;
        end
    end

    assign btnL_pulse = btnL_sync && !btnL_prev;
    assign btnU_pulse = btnU_sync && !btnU_prev;
    assign btnR_pulse = btnR_sync && !btnR_prev;

    // ========================================
    // Game Logic 시뮬레이션 (버튼 → pos_x + pos_valid)
    // ========================================
    localparam TILE_SPACING = 60;
    localparam START_X = 20;
    localparam MAX_X = 620;  // 깃발 위치

    // Player 위치 신호 (Game Logic 시뮬레이션)
    logic [9:0] player1_pos_x_sim;
    logic [9:0] player2_pos_x_sim;
    logic       pos_valid_sim;          // 통합 valid 신호
    logic       active_player_sim;      // 0=Player1, 1=Player2
    logic       turn_done;

    // Player 1: 버튼 입력 → pos_x + pos_valid + active_player 생성
    always_ff @(posedge clk_25mhz or posedge btn_reset) begin
        if (btn_reset) begin
            player1_pos_x_sim <= START_X;
            player2_pos_x_sim <= START_X;
            pos_valid_sim <= 1'b0;
            active_player_sim <= 1'b0;
        end else begin
            // 버튼 입력 처리 (Player 1 제어)
            if (btnL_pulse) begin
                // 1칸 이동 (60px)
                if (player1_pos_x_sim + TILE_SPACING <= MAX_X) begin
                    player1_pos_x_sim <= player1_pos_x_sim + TILE_SPACING;
                    pos_valid_sim <= 1'b1;      // 1 cycle pulse
                    active_player_sim <= 1'b0;  // Player 1
                end
            end else if (btnU_pulse) begin
                // 2칸 이동 (120px)
                if (player1_pos_x_sim + 2*TILE_SPACING <= MAX_X) begin
                    player1_pos_x_sim <= player1_pos_x_sim + 2*TILE_SPACING;
                    pos_valid_sim <= 1'b1;
                    active_player_sim <= 1'b0;
                end
            end else if (btnR_pulse) begin
                // 3칸 이동 (180px)
                if (player1_pos_x_sim + 3*TILE_SPACING <= MAX_X) begin
                    player1_pos_x_sim <= player1_pos_x_sim + 3*TILE_SPACING;
                    pos_valid_sim <= 1'b1;
                    active_player_sim <= 1'b0;
                end
            end else begin
                pos_valid_sim <= 1'b0;  // 1 cycle만
            end
        end
    end

    // ========================================
    // UI Render 인스턴스
    // ========================================
    logic [7:0] ui_r, ui_g, ui_b;

    ui_render ui (
        .clk(clk_25mhz),
        .rst(btn_reset),
        .x(vga_x),
        .y(vga_y),

        // Game Logic 인터페이스 (턴제 게임)
        .player1_pos_x(player1_pos_x_sim),
        .player2_pos_x(player2_pos_x_sim),
        .pos_valid(pos_valid_sim),
        .active_player(active_player_sim),
        .turn_done(turn_done),

        // RGB 출력
        .r(ui_r),
        .g(ui_g),
        .b(ui_b)
    );

    // ========================================
    // VGA 출력 (8비트 → 4비트)
    // ========================================
    always_ff @(posedge clk_25mhz) begin
        if (vga_de) begin
            vga_r <= ui_r[7:4];
            vga_g <= ui_g[7:4];
            vga_b <= ui_b[7:4];
        end else begin
            vga_r <= 4'h0;
            vga_g <= 4'h0;
            vga_b <= 4'h0;
        end
    end

    // ========================================
    // 디버그 LED (현재 타일 표시)
    // ========================================
    // 나누기 대신 비트 시프트 사용 (60 ≈ 64 = 2^6)
    logic [9:0] tile_offset;
    assign tile_offset = player1_pos_x_sim - START_X;
    assign led = tile_offset[9:6];  // /64 근사치 (실제: /60)

endmodule
