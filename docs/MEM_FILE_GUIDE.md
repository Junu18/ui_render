# .mem 파일을 사용한 스프라이트 로드 가이드

## .mem 파일이란?

`.mem` 파일은 Verilog/SystemVerilog의 `$readmemh`로 읽을 수 있는 **메모리 초기화 파일**입니다.

---

## .mem 파일 형식

### RGB444 형식 (12-bit)

```
// kerby.mem - 16x16 Kirby sprite
// Format: RGB444 (R4G4B4)
// Total: 256 pixels (16 rows × 16 columns)

// Row 0 (Pixel 0-15)
000  // Pixel 0: Transparent (Black)
000  // Pixel 1: Transparent
FFF  // Pixel 2: White (Santa hat pom-pom)
FFF  // Pixel 3: White
000  // Pixel 4: Transparent
...  // Pixel 5-15

// Row 1 (Pixel 16-31)
000  // Pixel 16
C03  // Pixel 17: Red (Santa hat)
C03  // Pixel 18: Red
...

// ... Row 2-15 (Pixel 32-255)
```

### RGB444 색상 코드

| 색상 | RGB444 | 의미 |
|------|--------|------|
| 검정 (투명) | 000 | Transparent |
| 흰색 | FFF | White |
| 빨강 | F00 | Red |
| 핑크 | FFB | Pink |
| 파랑 | 00F | Blue |
| 초록 | 0F0 | Green |

**계산 방법**: RGB888 → RGB444
- R8: 255 → R4: F (255/16 = 15 = F)
- G8: 182 → G4: B (182/16 = 11 = B)
- B8: 193 → B4: C (193/16 = 12 = C)
- **결과: FBC**

---

## player_renderer.sv에서 사용하기

### 방법 1: initial block + $readmemh (권장)

```systemverilog
module player_renderer (
    // ... ports
);

    // ROM 배열 선언
    logic [11:0] kirby_rom [0:255];
    logic [11:0] dee_rom [0:255];

    // .mem 파일에서 로드
    initial begin
        $readmemh("src/kerby.mem", kirby_rom);
        $readmemh("src/dee.mem", dee_rom);
    end

    // ROM 주소 계산
    logic [7:0] rom_addr;
    assign rom_addr = {sprite_y, sprite_x};  // y*16 + x

    // ROM 읽기
    logic [11:0] rom_data;
    assign rom_data = player_id ? dee_rom[rom_addr] : kirby_rom[rom_addr];

    // RGB 출력
    always_comb begin
        if (in_player_area) begin
            if (rom_data == 12'h000) begin
                enable = 1'b0;  // 투명
            end else begin
                enable = 1'b1;
                // RGB444 → RGB888
                color.r = {rom_data[11:8], rom_data[11:8]};
                color.g = {rom_data[7:4], rom_data[7:4]};
                color.b = {rom_data[3:0], rom_data[3:0]};
            end
        end
    end

endmodule
```

---

## .mem 파일 생성하기

### 방법 1: Python 스크립트 (Piskel PNG → .mem)

```python
#!/usr/bin/env python3
from PIL import Image
import sys

def png_to_mem(png_file, mem_file):
    img = Image.open(png_file).convert('RGB')
    if img.size != (16, 16):
        img = img.resize((16, 16), Image.NEAREST)

    pixels = img.load()

    with open(mem_file, 'w') as f:
        f.write("// 16x16 sprite in RGB444 format\n")
        f.write("// Total: 256 pixels\n\n")

        for y in range(16):
            f.write(f"// Row {y}\n")
            for x in range(16):
                r, g, b = pixels[x, y]
                # RGB888 → RGB444
                r4 = r >> 4
                g4 = g >> 4
                b4 = b >> 4
                rgb444 = (r4 << 8) | (g4 << 4) | b4
                f.write(f"{rgb444:03X}\n")

if __name__ == "__main__":
    png_to_mem(sys.argv[1], sys.argv[2])
```

사용:
```bash
python png_to_mem.py kirby.png kerby.mem
```

### 방법 2: 수동 작성

```
// kerby.mem
000  // (0,0) Transparent
000  // (0,1) Transparent
FFF  // (0,2) White
FFF  // (0,3) White
...  // 252 more lines
```

---

## 파일 위치 및 경로

### .mem 파일 위치
```
ui_render/
├── src/
│   ├── kerby.mem        ← Player 1 sprite
│   ├── dee.mem          ← Player 2 sprite
│   └── vga/ui_render/
│       └── player_renderer.sv
```

### SystemVerilog에서 경로 지정

```systemverilog
// 상대 경로 (프로젝트 루트 기준)
$readmemh("src/kerby.mem", kirby_rom);

// 또는 절대 경로
$readmemh("/home/user/ui_render/src/kerby.mem", kirby_rom);
```

---

## 시뮬레이션 vs FPGA

### 시뮬레이션 (iverilog, ModelSim 등)
✅ `$readmemh` **동작함**
- .mem 파일을 런타임에 읽음
- 파일 경로 확인 필요

### FPGA 합성 (Vivado)
⚠️ `$readmemh`는 **합성 시에만** 동작
- 합성 중에 ROM으로 변환됨
- 런타임에는 ROM에서 읽음
- .mem 파일은 비트스트림에 포함됨

---

## 장점 vs 단점

### .mem 파일 방식

**장점:**
- ✅ 코드와 데이터 분리
- ✅ .mem 파일만 교체하면 스프라이트 변경
- ✅ 큰 데이터에 적합
- ✅ 여러 스프라이트 관리 용이

**단점:**
- ❌ 파일 경로 관리 필요
- ❌ 시뮬레이션 시 경로 오류 가능
- ❌ Git에 .mem 파일 추가 관리

### localparam 배열 방식 (현재)

**장점:**
- ✅ 파일 하나로 완결
- ✅ 경로 문제 없음
- ✅ Git 관리 쉬움

**단점:**
- ❌ 코드가 길어짐
- ❌ 데이터 수정 시 코드 재컴파일

---

## 추천 방법

### 작은 스프라이트 (16x16, 1-2개)
→ **localparam 배열** (현재 방식)

### 큰 스프라이트 또는 많은 스프라이트 (32x32 이상, 10개 이상)
→ **.mem 파일**

---

## 예제: kerby.mem 생성

Piskel에서 만든 Kirby 스프라이트를 .mem으로:

```bash
# 1. Piskel에서 16x16 PNG export
# 2. Python 변환
python docs/png_to_mem.py kirby.png src/kerby.mem

# 3. player_renderer.sv 수정 (위 예제 참고)

# 4. 테스트
cd sim
iverilog -g2012 -o sim tb_ui_render_test_top.sv ../src/**/*.sv
./sim
```

---

## 트러블슈팅

### 문제 1: "Error: Cannot open file src/kerby.mem"

**원인**: 파일 경로가 잘못됨

**해결**:
```systemverilog
// 시뮬레이션 실행 위치 기준으로 경로 설정
// sim/ 폴더에서 실행한다면:
$readmemh("../src/kerby.mem", kirby_rom);
```

### 문제 2: "Warning: memory has X elements, data file has Y"

**원인**: .mem 파일의 데이터 개수가 256개가 아님

**해결**:
- .mem 파일이 정확히 256줄(16×16)인지 확인

### 문제 3: FPGA에서 스프라이트가 안 보임

**원인**: .mem 파일이 Vivado 프로젝트에 포함 안 됨

**해결**:
- Vivado에서 Add Sources → Add Files → .mem 파일 추가

---

## 요약

```
1. Piskel에서 16x16 PNG 생성
   ↓
2. Python 스크립트로 .mem 변환
   python png_to_mem.py kirby.png src/kerby.mem
   ↓
3. player_renderer.sv에서 $readmemh 사용
   initial begin
       $readmemh("src/kerby.mem", kirby_rom);
   end
   ↓
4. 테스트
```

.mem 파일 방식은 데이터가 많을 때 유용합니다! 🎨
