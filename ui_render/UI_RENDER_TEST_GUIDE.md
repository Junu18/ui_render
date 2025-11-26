# 🎮 UI Render 테스트 가이드

## 📁 테스트용 파일

### 1. Top 모듈
- **파일**: `src/ui_render_test_top.sv`
- **목적**: 버튼으로 UI Render 동작 테스트

### 2. 제약 파일
- **파일**: `constraints/basys3_test.xdc`
- **보드**: Digilent Basys3 (Artix-7)

---

## 🔧 하드웨어 구성

### Basys3 보드 연결

```
보드          →  연결
---------------------------------
클럭          →  100MHz (자동)
리셋 버튼     →  BTNC (Center)
테스트 버튼   →  BTNL, BTNU, BTNR
VGA 출력      →  VGA 포트
LED           →  현재 타일 번호 표시
```

---

## 🎮 버튼 기능

| 버튼 | 기능 | 동작 |
|------|------|------|
| **BTNC** | 리셋 | 플레이어를 시작 위치(x=20)로 초기화 |
| **BTNL** | 1칸 이동 | Player 1을 60px 앞으로 이동 |
| **BTNU** | 2칸 이동 | Player 1을 120px 앞으로 이동 |
| **BTNR** | 3칸 이동 | Player 1을 180px 앞으로 이동 |

---

## 📊 타일 레이아웃

```
시작: x=20
간격: 60px

Tile 0: x=20   ← 시작 위치
Tile 1: x=80
Tile 2: x=140
Tile 3: x=200
Tile 4: x=260
Tile 5: x=320
Tile 6: x=380
Tile 7: x=440
Tile 8: x=500
Tile 9: x=560
깃발:   x=620  ← 골인 지점
```

---

## 🚀 테스트 시나리오

### 시나리오 1: 기본 이동 테스트
1. BTNC를 눌러 리셋
2. BTNL을 눌러 1칸 이동
   - Player 1 (빨간 점)이 x=20 → x=80으로 이동
   - 애니메이션: MOVING (24 frames) → JUMPING (16 frames)
3. BTNU를 눌러 2칸 이동
   - x=80 → x=200 (2칸)
4. LED로 현재 타일 확인

### 시나리오 2: 깃발 도착 테스트
1. BTNC로 리셋
2. 버튼을 반복해서 눌러 x=560까지 이동
3. BTNL을 눌러 깃발(x=620)까지 이동
4. **FLAG_SLIDING** 애니메이션 확인
   - 점프 → 깃발 타고 내려오기 (20 frames)

### 시나리오 3: 연속 이동 테스트
1. BTNR (3칸 이동) 테스트
   - 한 번의 버튼 입력으로 3칸 연속 이동
   - 각 칸마다 점프 애니메이션

---

## 🔨 Vivado에서 빌드 방법

### 1. 프로젝트 생성
```tcl
# Vivado TCL Console
create_project ui_render_test ./vivado_project -part xc7a35tcpg236-1 -force

# 소스 파일 추가
add_files {
    src/ui_render.sv
    src/ui_render_test_top.sv
    src/util/color_pkg.sv
    src/ov7670 driver/VGA_Syncher.sv
}

# 제약 파일 추가
add_files -fileset constrs_1 constraints/basys3_test.xdc

# Top 모듈 설정
set_property top ui_render_test_top [current_fileset]
```

### 2. 합성 및 구현
```tcl
# 합성
launch_runs synth_1
wait_on_run synth_1

# 구현
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
```

### 3. 비트스트림 다운로드
```tcl
# 프로그램
open_hw
connect_hw_server
open_hw_target
current_hw_device [lindex [get_hw_devices] 0]
set_property PROGRAM.FILE {./vivado_project/ui_render_test.runs/impl_1/ui_render_test_top.bit} [current_hw_device]
program_hw_devices [current_hw_device]
```

---

## 🎨 화면 구성

```
┌─────────────────────────────────┐
│                                 │
│         하늘 (그라데이션)          │  ← y=0~140
│                                 │
├─────────────────────────────────┤
│▓▓▓▓▓ 잔디 (Minecraft 스타일) ▓▓▓│  ← y=140~150
├─────────────────────────────────┤
│■■■■■ 흙 (갈색) ■■■■■■■■■■■■■│  ← y=150~180
└─────────────────────────────────┘

플레이어:
  🔴 Player 1 (빨간 점 IC 칩)
  🔵 Player 2 (파란 점 IC 칩)

깃발:
  🏁 x=620 (체커보드 패턴)
```

---

## 🐛 디버깅

### LED로 상태 확인
- **LED[3:0]**: 현재 타일 번호 (0~10)
  - LED = 0000: Tile 0 (시작)
  - LED = 0101: Tile 5
  - LED = 1010: Tile 10 (깃발)

### 예상 문제

**문제 1: 화면이 안 나옴**
- VGA 케이블 연결 확인
- 모니터 해상도: 640x480 @ 60Hz 지원 확인
- 클럭 생성 확인 (100MHz → 25MHz)

**문제 2: 버튼이 안 눌림**
- 디바운싱 타이밍 확인
- Edge detection 로직 확인

**문제 3: 플레이어가 움직이지 않음**
- `player1_move_start` 신호 확인
- `player1_turn_done` 신호 대기 확인

---

## 📝 다음 단계

테스트 완료 후:
1. **Game Logic 통합**
   - `game_ui_bridge.sv` 모듈 작성
   - Game Logic → UI Render 연결

2. **카메라 통합**
   - OV7670 카메라 입력
   - 주사위 색상 감지 → 플레이어 이동

3. **완전한 게임**
   - Player 2 제어 추가
   - 턴제 게임 로직
   - 승리 조건 처리

---

## 🎯 기대 결과

1. ✅ 버튼 누르면 플레이어가 애니메이션으로 이동
2. ✅ 각 타일 이동 후 점프 애니메이션
3. ✅ 깃발 도착 시 특수 애니메이션
4. ✅ LED로 현재 위치 확인 가능

**테스트 성공 기준**: 버튼 입력에 따라 플레이어가 부드럽게 이동하고, 깃발 도착 시 슬라이딩 애니메이션이 나타나면 성공!
