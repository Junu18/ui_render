# 플레이어 이동 로직 가이드

## 📋 개요

`ui_render.sv` 모듈에는 **플레이어 자동 이동 + 점프 로직**이 내장되어 있습니다.
Game Logic 쪽에서는 **move_trigger 펄스만 보내면** 플레이어가 자동으로 이동합니다.

---

## 🎮 동작 방식

### 이동 시퀀스
```
1. move_trigger = 1 (1 clock)
   ↓
2. 수평 이동 (24 프레임, 약 0.5초)
   - 현재 타일 → 다음 타일
   - x 좌표만 변경, y는 고정
   ↓
3. 점프 (16 프레임, 약 0.3초)
   - x 고정
   - y: 124 → 94 (최고점) → 124
   ↓
4. IDLE (대기 상태)
```

### 타일 시스템
- **전체 폭**: 480px
- **타일 수**: 10칸 (Tile 0 ~ Tile 9)
- **타일 크기**: 48px
- **시작 위치**: Tile 0 (x=16, y=124)

| Tile | X 범위 | 중앙 X |
|------|--------|--------|
| 0 | 0 ~ 47 | 16 |
| 1 | 48 ~ 95 | 64 |
| 2 | 96 ~ 143 | 112 |
| ... | ... | ... |
| 9 | 432 ~ 479 | 448 |

---

## 🔌 모듈 인터페이스

### ui_render 모듈

```systemverilog
module ui_render (
    // 입력
    input  logic       clk,            // 시스템 클럭 (25MHz VGA)
    input  logic       rst,            // 리셋 (active high)
    input  logic [9:0] x,              // VGA x 좌표 (0~639)
    input  logic [9:0] y,              // VGA y 좌표 (0~479)
    input  logic       move_trigger,   // 한 칸 이동 명령 (펄스)

    // 출력
    output logic [7:0] r,              // VGA Red
    output logic [7:0] g,              // VGA Green
    output logic [7:0] b,              // VGA Blue
    output logic [3:0] current_tile,   // 현재 타일 번호 (0~9)
    output logic       is_moving       // 이동 중 플래그
);
```

---

## 💻 Game Logic 사용 예제

### 기본 사용법

```systemverilog
module game_logic (
    input  logic clk,
    input  logic rst,
    input  logic button_press,    // 사용자 버튼 입력

    // ui_render 연결
    output logic move_trigger,
    input  logic [3:0] current_tile,
    input  logic is_moving
);

    // 이동 트리거 생성 (1 clock 펄스)
    logic button_press_prev;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            button_press_prev <= 1'b0;
            move_trigger <= 1'b0;
        end else begin
            button_press_prev <= button_press;

            // Rising edge 감지 + 이동 중이 아닐 때만
            if (button_press && !button_press_prev && !is_moving) begin
                move_trigger <= 1'b1;  // 1 clock 펄스
            end else begin
                move_trigger <= 1'b0;
            end
        end
    end

endmodule
```

### 주사위 결과로 이동하기

```systemverilog
module dice_game (
    input  logic clk,
    input  logic rst,
    input  logic dice_rolled,      // 주사위 굴림 완료
    input  logic [2:0] dice_value, // 1~6

    output logic move_trigger,
    input  logic [3:0] current_tile,
    input  logic is_moving
);

    logic [2:0] remaining_moves;   // 남은 이동 횟수

    typedef enum logic [1:0] {
        IDLE,
        WAITING,
        MOVING
    } state_t;

    state_t state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            remaining_moves <= 3'd0;
            move_trigger <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (dice_rolled && dice_value > 0) begin
                        remaining_moves <= dice_value;
                        state <= WAITING;
                    end
                end

                WAITING: begin
                    if (!is_moving && remaining_moves > 0) begin
                        move_trigger <= 1'b1;  // 이동 시작
                        remaining_moves <= remaining_moves - 1;
                        state <= MOVING;
                    end else if (remaining_moves == 0) begin
                        state <= IDLE;
                    end
                end

                MOVING: begin
                    move_trigger <= 1'b0;
                    if (!is_moving) begin  // 이동 완료 대기
                        state <= WAITING;
                    end
                end
            endcase
        end
    end

endmodule
```

---

## ⚙️ 내부 파라미터 (커스터마이징 가능)

`ui_render.sv` 내 `player_controller` 모듈:

```systemverilog
localparam TILE_SIZE = 48;         // 타일 크기 (px)
localparam PLAYER_OFFSET = 16;     // 타일 중앙 오프셋
localparam BASE_Y = 124;           // 기본 Y 위치 (잔디 위)
localparam MOVE_FRAMES = 24;       // 수평 이동 프레임 수
localparam JUMP_FRAMES = 16;       // 점프 프레임 수
localparam JUMP_HEIGHT = 30;       // 점프 최대 높이 (px)
```

**이동 속도 조절:**
- `MOVE_FRAMES` ↑ = 느린 이동
- `MOVE_FRAMES` ↓ = 빠른 이동

**점프 높이 조절:**
- `JUMP_HEIGHT` ↑ = 높이 점프
- `JUMP_HEIGHT` ↓ = 낮은 점프

---

## 🔍 디버깅 팁

### 1. 현재 타일 번호 확인
```systemverilog
always_ff @(posedge clk) begin
    if (current_tile != current_tile_prev) begin
        $display("Player moved to tile %d", current_tile);
    end
end
```

### 2. 이동 상태 확인
```systemverilog
always_ff @(posedge clk) begin
    if (is_moving && !is_moving_prev) begin
        $display("Movement started");
    end else if (!is_moving && is_moving_prev) begin
        $display("Movement finished");
    end
end
```

### 3. 골 도달 확인
```systemverilog
if (current_tile == 9 && !is_moving) begin
    $display("Player reached the goal!");
end
```

---

## ⚠️ 주의사항

### 1. move_trigger는 1 clock 펄스여야 함
```systemverilog
// ❌ 잘못된 예: 버튼이 눌린 동안 계속 1
assign move_trigger = button_press;

// ✅ 올바른 예: Rising edge에서만 1 clock
always_ff @(posedge clk) begin
    if (button_press && !button_press_prev && !is_moving)
        move_trigger <= 1'b1;
    else
        move_trigger <= 1'b0;
end
```

### 2. 이동 중에는 새 이동 명령 무시
```systemverilog
// is_moving == 1일 때 move_trigger 보내면 무시됨
if (!is_moving) begin
    // 이동 가능한 상태
end
```

### 3. 타일 9 도달 후 추가 이동 불가
```systemverilog
// current_tile == 9일 때 move_trigger 보내도 무시됨
// (내부적으로 current_tile < 9 체크)
```

---

## 📊 타이밍 다이어그램

```
clk           ___/‾‾‾\___/‾‾‾\___/‾‾‾\___/‾‾‾\___
move_trigger  ______/‾‾‾\________________________
is_moving     _________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\__________
              [IDLE]  [   MOVING + JUMPING  ][IDLE]
current_tile  ====0===|=========1=========|===1===
```

---

## 🚀 Top 모듈 통합 예제

```systemverilog
module top (
    input  logic clk_50MHz,
    input  logic btn_move,
    output logic vga_hsync,
    output logic vga_vsync,
    output logic [7:0] vga_r, vga_g, vga_b
);

    logic clk_25MHz;
    logic rst;
    logic [9:0] pixel_x, pixel_y;
    logic move_trigger;
    logic [3:0] current_tile;
    logic is_moving;

    // 클럭 분주기 (50MHz → 25MHz)
    clk_divider div (.clk_in(clk_50MHz), .clk_out(clk_25MHz));

    // VGA 동기 신호 생성
    vga_sync sync (
        .clk(clk_25MHz),
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y)
    );

    // 게임 로직 (move_trigger 생성)
    game_logic game (
        .clk(clk_25MHz),
        .rst(rst),
        .button(btn_move),
        .move_trigger(move_trigger),
        .current_tile(current_tile),
        .is_moving(is_moving)
    );

    // UI 렌더러
    ui_render ui (
        .clk(clk_25MHz),
        .rst(rst),
        .x(pixel_x),
        .y(pixel_y),
        .move_trigger(move_trigger),
        .r(vga_r),
        .g(vga_g),
        .b(vga_b),
        .current_tile(current_tile),
        .is_moving(is_moving)
    );

endmodule
```

---

## 📝 요약

| 항목 | 값 |
|------|-----|
| **입력** | `move_trigger` (1 clock 펄스) |
| **출력** | `current_tile` (0~9), `is_moving` (boolean) |
| **타일 수** | 10칸 |
| **이동 시간** | 약 0.8초 (이동 0.5초 + 점프 0.3초) |
| **자동 제어** | ✅ 위치, 애니메이션 모두 자동 |

**Game Logic에서 할 일:**
1. 버튼/주사위 입력 받기
2. `move_trigger` 펄스 생성
3. `current_tile`로 게임 상태 확인
