# BMP 이미지를 플레이어 스프라이트로 사용하는 방법

## 개요

현재 `player_renderer.sv`는 case 문으로 픽셀을 직접 정의하고 있습니다.
.bmp 이미지 파일을 사용하려면 ROM (Read-Only Memory) 방식으로 변경해야 합니다.

## 방법 비교

### 현재 방식 (Case Statement)
```systemverilog
case (sprite_y)
    4'd0: begin
        if (sprite_x >= 8 && sprite_x <= 9) begin
            color = WHITE;
            enable = 1'b1;
        end
    end
    // ... 16행 반복
endcase
```

**장점:**
- 간단하고 직관적
- 추가 도구 불필요

**단점:**
- 코드가 길어짐
- 이미지 수정이 어려움
- 픽셀 단위로 수작업 필요

### ROM 방식 (BMP 사용)
```systemverilog
localparam logic [11:0] SPRITE_ROM [0:255] = '{
    12'hFFF, 12'hFFF, 12'h000, ... // Row 0
    12'h000, 12'hF00, 12'hF00, ... // Row 1
    // ... (256 pixels)
};
assign rom_data = SPRITE_ROM[sprite_y * 16 + sprite_x];
```

**장점:**
- 이미지 에디터로 직접 편집 가능
- 픽셀 데이터만 교체하면 됨
- 복잡한 이미지도 쉽게 사용

**단점:**
- 변환 과정 필요
- 메모리 사용량 동일하지만 구조가 다름

---

## 단계별 구현 방법

### 1단계: 16x16 BMP 이미지 준비

#### 이미지 에디터 사용 (GIMP, Photoshop, Paint.NET 등)

1. 새 이미지 생성: **16x16 pixels**
2. 배경을 투명으로 설정 (또는 특정 색상을 투명으로 지정)
3. 캐릭터 디자인
4. **BMP 형식**으로 저장
   - `kirby_christmas.bmp` (Player 1)
   - `dee_bandana.bmp` (Player 2)

#### 투명색 처리 방법

**Option A:** 순수 검정(#000000)을 투명으로 사용
- 변환 시 `12'h000`이 자동으로 투명 처리됨
- 간단하지만, 검정색을 스프라이트에 사용 못함

**Option B:** Magenta(#FF00FF)를 투명으로 사용
- 변환 시 `255,0,255` 지정
- 검정색도 사용 가능

### 2단계: BMP → SystemVerilog 변환

#### Python 스크립트 사용

```bash
# PIL 설치 (한 번만)
pip install Pillow

# BMP → SV 변환
python docs/bmp_to_sv_rom.py kirby_christmas.bmp KIRBY > kirby_rom.sv
python docs/bmp_to_sv_rom.py dee_bandana.bmp DEE > dee_rom.sv

# 투명색 지정 (Magenta)
python docs/bmp_to_sv_rom.py sprite.bmp SPRITE 255,0,255 > sprite_rom.sv
```

#### 출력 예시

```systemverilog
// KIRBY sprite ROM (16x16 pixels, RGB444 format)
// Generated from: kirby_christmas.bmp
localparam logic [11:0] KIRBY_ROM [0:255] = '{
    // Row 0 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'hFFF,
             12'hFFF, 12'hFFF, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000,
    // Row 1 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'hC03, 12'hC03,
             12'hC03, 12'hC03, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000,
    // ... (Row 2-15)
};
```

### 3단계: player_renderer.sv 수정

#### 기존 파일 백업
```bash
cp src/vga/ui_render/player_renderer.sv src/vga/ui_render/player_renderer.sv.backup
```

#### ROM 데이터 추가

1. `kirby_rom.sv`와 `dee_rom.sv` 내용을 `player_renderer.sv`에 복사
2. 기존 case 문 제거
3. ROM 읽기 로직 추가

예시는 `docs/player_renderer_bmp_example.sv` 참고

#### 핵심 변경사항

**Before (Case 방식):**
```systemverilog
always_comb begin
    if (in_player_area) begin
        case (sprite_y)
            4'd0: begin
                if (sprite_x >= 8 && sprite_x <= 9) begin
                    color = WHITE;
                    enable = 1'b1;
                end
            end
            // ... 많은 case 문
        endcase
    end
end
```

**After (ROM 방식):**
```systemverilog
// ROM 주소 계산
logic [7:0] rom_addr;
assign rom_addr = {sprite_y, sprite_x};  // y*16 + x

// ROM 읽기
logic [11:0] rom_data;
assign rom_data = player_id ? DEE_ROM[rom_addr] : KIRBY_ROM[rom_addr];

// RGB 출력
always_comb begin
    if (in_player_area) begin
        if (rom_data == 12'h000) begin  // 투명
            enable = 1'b0;
            color = TRANSPARENT;
        end else begin
            enable = 1'b1;
            // RGB444 → RGB888 변환
            color.r = {rom_data[11:8], rom_data[11:8]};
            color.g = {rom_data[7:4], rom_data[7:4]};
            color.b = {rom_data[3:0], rom_data[3:0]};
        end
    end else begin
        enable = 1'b0;
        color = TRANSPARENT;
    end
end
```

### 4단계: 테스트

#### 시뮬레이션
```bash
cd sim
iverilog -g2012 -o sim tb_ui_render_test_top.sv ../src/**/*.sv
./sim
gtkwave waveform.vcd
```

#### FPGA 비트스트림
Vivado에서 빌드하고 FPGA에 업로드

---

## 프로젝트 통합

### 현재 구조
```
src/vga/ui_render/
├── player_renderer.sv          (case 문 방식)
├── player_controller.sv        (애니메이션 제어)
└── ...
```

### ROM 방식으로 변경 후
```
src/vga/ui_render/
├── player_renderer.sv          (ROM 방식)
│   ├── KIRBY_ROM [0:255]      (16x16 = 256 pixels)
│   └── DEE_ROM [0:255]
├── player_controller.sv        (변경 없음)
└── ...
```

### 인터페이스 변경 없음!

`player_renderer.sv`의 **포트는 그대로**입니다:
```systemverilog
module player_renderer (
    input  logic [9:0] x,
    input  logic [9:0] y,
    input  logic [9:0] player_x,
    input  logic [9:0] player_y,
    input  logic       player_id,
    output rgb_t       color,
    output logic       enable
);
```

따라서 `ui_render.sv`, `player_controller.sv` 등 **다른 파일은 수정 불필요**합니다!

---

## 메모리 사용량

### ROM 크기 계산
- 1 pixel = 12 bits (RGB444)
- 16x16 = 256 pixels
- **1 sprite = 256 × 12 = 3,072 bits = 384 bytes**

### 2 players
- **Total = 768 bytes = 6,144 bits**

Basys3 FPGA (Artix-7)는 충분한 Block RAM을 가지고 있으므로 문제없습니다.

---

## 자주 하는 질문 (FAQ)

### Q1: ImgMemReader를 사용해야 하나요?

**A:** 아니요. `ImgMemReader`는 320×240 크기의 카메라 이미지용입니다.
16×16 스프라이트에는 위의 ROM 방식이 더 적합합니다.

### Q2: RGB444 vs RGB565 vs RGB888?

| 형식   | 비트수 | 색상 수          | 사용처                  |
|--------|--------|------------------|-------------------------|
| RGB444 | 12bit  | 4,096 colors     | 작은 스프라이트 (추천)  |
| RGB565 | 16bit  | 65,536 colors    | 고품질 이미지           |
| RGB888 | 24bit  | 16,777,216 colors| 최고 품질 (메모리 많음) |

16x16 스프라이트에는 **RGB444면 충분**합니다.

### Q3: 투명색을 어떻게 처리하나요?

**방법 1:** `12'h000` (검정)을 투명으로 사용
```systemverilog
if (rom_data == 12'h000) begin
    enable = 1'b0;  // 투명
end
```

**방법 2:** 특정 색상을 투명으로 지정 (예: Magenta `12'hF0F`)
```systemverilog
if (rom_data == 12'hF0F) begin  // Magenta
    enable = 1'b0;  // 투명
end
```

### Q4: 이미지를 바꾸려면 어떻게 하나요?

1. 새 BMP 파일 준비 (16x16)
2. Python 스크립트로 변환
3. `player_renderer.sv`의 ROM 데이터만 교체
4. 재컴파일

**코드 로직은 전혀 수정 불필요!**

### Q5: 여러 애니메이션 프레임을 사용하려면?

각 프레임을 별도 ROM으로 만들고, 프레임 번호로 선택:

```systemverilog
localparam logic [11:0] KIRBY_FRAME0 [0:255] = '{...};
localparam logic [11:0] KIRBY_FRAME1 [0:255] = '{...};
localparam logic [11:0] KIRBY_FRAME2 [0:255] = '{...};

// 프레임 선택
logic [11:0] rom_data;
always_comb begin
    case (animation_frame)
        2'd0: rom_data = KIRBY_FRAME0[rom_addr];
        2'd1: rom_data = KIRBY_FRAME1[rom_addr];
        2'd2: rom_data = KIRBY_FRAME2[rom_addr];
        default: rom_data = KIRBY_FRAME0[rom_addr];
    endcase
end
```

---

## 참고 파일

- `docs/player_renderer_bmp_example.sv` - ROM 방식 예제 코드
- `docs/bmp_to_sv_rom.py` - BMP → SV 변환 스크립트
- `src/ov7670 driver/ImgMemReader.sv` - 참고용 (320×240 이미지용)

---

## 요약

1. **16×16 BMP 이미지** 준비
2. **Python 스크립트**로 SystemVerilog ROM 생성
3. **player_renderer.sv**에 ROM 데이터 추가 및 로직 수정
4. **다른 파일 수정 불필요** (인터페이스 동일)
5. **테스트 및 디버그**

이 방식을 사용하면 이미지 에디터로 스프라이트를 쉽게 편집할 수 있습니다!
