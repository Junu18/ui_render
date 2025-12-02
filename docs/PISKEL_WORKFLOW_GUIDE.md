# Piskel 워크플로우 가이드

Piskel로 스프라이트를 만들고 SystemVerilog로 자동 변환하는 완전 가이드

---

## 전체 워크플로우

```
Piskel → PNG Export → Python 변환 → SystemVerilog 코드 → player_renderer.sv
```

---

## 1단계: Piskel에서 스프라이트 제작

### Piskel 시작하기

1. **Piskel 열기**: https://www.piskelapp.com/
2. **New Sprite** 클릭
3. **Canvas Size 설정**:
   - Width: **16**
   - Height: **16**
   - 확인

### 스프라이트 그리기 팁

#### 도구 사용법
- **Pen tool** (P): 픽셀 하나씩 그리기
- **Paint bucket** (B): 영역 채우기
- **Eraser** (E): 지우개 (투명하게)
- **Color picker** (O): 색상 추출

#### 권장 작업 방식
1. **외곽선 먼저**: 검정색으로 캐릭터 윤곽 그리기
2. **색 채우기**: 큰 영역부터 채우기
3. **디테일 추가**: 눈, 입, 볼터치 등
4. **음영 추가**: 밝은 색/어두운 색으로 입체감

#### 색상 팔레트 관리
- **오른쪽 팔레트**에서 색상 관리
- 비슷한 색상은 통일 (예: 핑크 2-3가지만 사용)
- 투명 영역은 **Alpha = 0**으로 설정

### Export 하기

1. **File → Export** 메뉴
2. **PNG** 선택 (권장) 또는 **BMP**
3. Scale: **1x** (원본 크기 유지)
4. 파일명: `kirby.png`, `dee.png` 등
5. **Download**

---

## 2단계: Python 스크립트로 변환

### 설치 (최초 1회)

```bash
pip install Pillow
```

### 변환 실행

#### 기본 사용법
```bash
# PNG → SystemVerilog case 문 생성
python docs/piskel_to_sv_case.py kirby.png KIRBY > kirby_sprite.sv
```

#### 투명색 지정
```bash
# Magenta(#FF00FF)를 투명으로
python docs/piskel_to_sv_case.py sprite.png SPRITE --transparent 255,0,255 > sprite.sv

# 검정(#000000)을 투명으로
python docs/piskel_to_sv_case.py sprite.png SPRITE --transparent 0,0,0 > sprite.sv
```

#### 색상 변수 없이 직접 값 사용
```bash
python docs/piskel_to_sv_case.py sprite.png SPRITE --no-color-names > sprite.sv
```

### 출력 예시

```systemverilog
// KIRBY Color Palette
localparam rgb_t KIRBY_COLOR_0 = '{r: 8'd255, g: 8'd182, b: 8'd193};  // 핑크
localparam rgb_t KIRBY_COLOR_1 = '{r: 8'd0, g: 8'd0, b: 8'd0};        // 검정
localparam rgb_t KIRBY_COLOR_2 = '{r: 8'd255, g: 8'd255, b: 8'd255};  // 흰색
// ... (더 많은 색상)

// KIRBY sprite (16x16)
case (sprite_y)
    // Row 0
    4'd0: begin
        case (sprite_x)
            4'd7, 4'd8, 4'd9: begin
                color = KIRBY_COLOR_2;  // 흰색
                enable = 1'b1;
            end
            default: begin
                enable = 1'b0;
            end
        endcase
    end

    // Row 1
    4'd1: begin
        case (sprite_x)
            4'd6, 4'd7, 4'd8, 4'd9, 4'd10: begin
                color = KIRBY_COLOR_0;  // 핑크
                enable = 1'b1;
            end
            default: begin
                enable = 1'b0;
            end
        endcase
    end

    // ... (Row 2-15)

    default: begin
        enable = 1'b0;
        color = TRANSPARENT;
    end
endcase

// Statistics:
// Total non-transparent pixels: 178
// Unique colors: 8
// Transparency: 78 pixels
```

---

## 3단계: player_renderer.sv에 적용

### 코드 복사하기

1. **변환된 코드 열기**: `kirby_sprite.sv`
2. **색상 팔레트 복사**:
   - `localparam rgb_t KIRBY_COLOR_...` 부분
   - `player_renderer.sv`의 색상 정의 섹션에 붙여넣기
3. **Case 문 복사**:
   - `case (sprite_y) ... endcase` 전체
   - Player 1 또는 Player 2 섹션에 붙여넣기

### 예시: player_renderer.sv 수정

```systemverilog
module player_renderer (
    // ... (포트 선언)
);

    // ============================================
    // 색상 정의
    // ============================================

    // Piskel에서 생성된 색상 팔레트 (여기에 복사)
    localparam rgb_t KIRBY_COLOR_0 = '{r: 8'd255, g: 8'd182, b: 8'd193};
    localparam rgb_t KIRBY_COLOR_1 = '{r: 8'd0, g: 8'd0, b: 8'd0};
    // ... (나머지 색상)

    always_comb begin
        if (in_player_area) begin
            if (player_id == 1'b0) begin
                // Player 1: Piskel에서 생성된 case 문 (여기에 복사)
                case (sprite_y)
                    4'd0: begin
                        case (sprite_x)
                            4'd7, 4'd8, 4'd9: begin
                                color = KIRBY_COLOR_2;
                                enable = 1'b1;
                            end
                            // ...
                        endcase
                    end
                    // ... (나머지 행)
                endcase
            end else begin
                // Player 2: 다른 스프라이트
                // ...
            end
        end
    end

endmodule
```

---

## 4단계: 테스트 및 디버그

### 시뮬레이션
```bash
cd sim
iverilog -g2012 -o sim tb_ui_render_test_top.sv ../src/**/*.sv
./sim
gtkwave waveform.vcd
```

### FPGA 업로드
Vivado에서 빌드하고 Basys3에 업로드

---

## 실전 예제

### 예제 1: 크리스마스 커비 만들기

#### Piskel 작업
1. 16×16 캔버스 생성
2. 둥근 핑크 몸체 그리기
3. 큰 타원형 눈 (검정 테두리, 흰 눈자, 파란 하이라이트)
4. 분홍 볼터치
5. 빨간 미소
6. 빨간 산타모자 (위에)
7. 작은 빨간 발 (아래)
8. Export → `kirby_christmas.png`

#### 변환
```bash
python docs/piskel_to_sv_case.py kirby_christmas.png KIRBY_XMAS > kirby_xmas.sv
```

#### 적용
- `kirby_xmas.sv` 내용을 `player_renderer.sv`에 복사
- Player 1 섹션에 붙여넣기

### 예제 2: 배경 투명 처리

Piskel에서:
- 배경을 Magenta(#FF00FF)로 채움
- 캐릭터만 그림

변환:
```bash
python docs/piskel_to_sv_case.py sprite.png SPRITE --transparent 255,0,255 > sprite.sv
```

결과:
- Magenta 픽셀은 `enable = 1'b0`으로 처리 (투명)

---

## 색상 팔레트 최적화 팁

### 문제: 색상이 너무 많음
Piskel에서 256색을 사용하면 코드가 너무 길어집니다.

### 해결: 색상 수 제한
- **3-5가지 주요 색상**만 사용
- 각 색상마다 **밝은/어두운 버전** 2개
- 총 **8-10가지 색상** 권장

### 예시: 커비 팔레트
1. 핑크 (밝음, 어두움) - 2색
2. 검정 (눈 테두리) - 1색
3. 흰색 (눈 흰자) - 1색
4. 파란색 (눈 하이라이트) - 1색
5. 빨강 (입, 발) - 2색
6. 산타모자 (빨강, 흰색) - 이미 있음
7. **총 7가지 색상**

---

## 여러 애니메이션 프레임 만들기

### 1. Piskel에서 프레임 추가
- 오른쪽 **Frames** 패널에서 **Duplicate frame**
- 각 프레임마다 약간씩 수정 (걷는 애니메이션 등)

### 2. 각 프레임 Export
```
frame0.png
frame1.png
frame2.png
frame3.png
```

### 3. 각각 변환
```bash
python docs/piskel_to_sv_case.py frame0.png KIRBY_FRAME0 > frame0.sv
python docs/piskel_to_sv_case.py frame1.png KIRBY_FRAME1 > frame1.sv
python docs/piskel_to_sv_case.py frame2.png KIRBY_FRAME2 > frame2.sv
python docs/piskel_to_sv_case.py frame3.png KIRBY_FRAME3 > frame3.sv
```

### 4. SystemVerilog에서 프레임 선택
```systemverilog
// 애니메이션 프레임 선택
always_comb begin
    case (animation_frame)
        2'd0: begin
            // frame0.sv의 case 문
        end
        2'd1: begin
            // frame1.sv의 case 문
        end
        2'd2: begin
            // frame2.sv의 case 문
        end
        2'd3: begin
            // frame3.sv의 case 문
        end
    endcase
end
```

---

## 트러블슈팅

### 문제 1: "Error: Image is not 16x16"
**원인**: Piskel에서 Export 시 Scale을 변경함

**해결**:
- Piskel에서 Export 설정 확인
- Scale을 **1x**로 설정
- 또는 스크립트가 자동으로 리사이즈 (경고 메시지 출력)

### 문제 2: 투명 영역이 제대로 안 됨
**원인**: Piskel에서 Alpha 값이 중간값 (예: 128)

**해결**:
- Piskel에서 Eraser tool로 완전히 지우기 (Alpha = 0)
- 또는 특정 색상을 투명색으로 지정:
  ```bash
  --transparent 255,0,255
  ```

### 문제 3: 색상이 이상하게 나옴
**원인**: RGB 값이 정확하지 않음

**해결**:
- Piskel의 Color picker로 정확한 색상 확인
- 또는 변환 후 `localparam` 색상 값 수동 조정

### 문제 4: 코드가 너무 길어짐
**원인**: 색상이 너무 많음 (100가지 이상)

**해결**:
- Piskel에서 **Limited palette** 사용
- 색상 수를 8-12가지로 제한
- 비슷한 색상 통일

---

## 비교: 수동 vs Piskel 워크플로우

### 수동 픽셀 아트 (현재)
**장점:**
- 도구 필요 없음
- 코드에서 바로 수정
- 정확한 제어

**단점:**
- 시각적으로 확인 어려움
- 픽셀 하나하나 코딩
- 수정 번거로움

### Piskel 워크플로우
**장점:**
- ✅ 시각적 에디터 (실시간 미리보기)
- ✅ Undo/Redo, Copy/Paste
- ✅ 색상 팔레트 관리
- ✅ 애니메이션 프레임 지원
- ✅ 자동 코드 생성

**단점:**
- Python 설치 필요
- 변환 과정 추가
- PNG 파일 관리

---

## 권장 워크플로우

### 초기 디자인
1. **Piskel**에서 스프라이트 디자인
2. Python 스크립트로 변환
3. SystemVerilog에 적용
4. 테스트

### 미세 조정
1. FPGA에서 확인
2. 수정이 작으면: **코드에서 직접 수정**
3. 수정이 크면: **Piskel로 돌아가서 재작업**

---

## 참고 자료

- **Piskel 공식 사이트**: https://www.piskelapp.com/
- **Piskel 튜토리얼**: https://www.piskelapp.com/tutorials
- **픽셀 아트 가이드**: https://lospec.com/pixel-art-tutorials
- **색상 팔레트**: https://lospec.com/palette-list

---

## 요약

```bash
# 1. Piskel에서 16x16 스프라이트 제작 → Export PNG

# 2. Python 변환
python docs/piskel_to_sv_case.py sprite.png SPRITE > sprite.sv

# 3. player_renderer.sv에 복사 붙여넣기

# 4. 컴파일 및 테스트
cd sim && iverilog -g2012 -o sim tb_ui_render_test_top.sv ../src/**/*.sv && ./sim
```

이제 Piskel로 쉽게 스프라이트를 만들고 자동으로 SystemVerilog로 변환할 수 있습니다! 🎨
