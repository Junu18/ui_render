#!/usr/bin/env python3
"""
Piskel PNG/BMP to SystemVerilog Case Statement Converter
Piskel에서 만든 16x16 스프라이트를 SystemVerilog case 문으로 변환

사용법:
    python piskel_to_sv_case.py sprite.png SPRITE_NAME [--transparent 255,0,255]
    python piskel_to_sv_case.py kirby.png KIRBY
    python piskel_to_sv_case.py dee.png DEE --transparent 0,0,0
"""

from PIL import Image
import sys
import argparse
from collections import defaultdict

def rgb_to_sv_color(r, g, b):
    """RGB888을 SystemVerilog rgb_t 구조체 형식으로 변환"""
    return f"{{r: 8'd{r}, g: 8'd{g}, b: 8'd{b}}}"

def get_color_name(r, g, b, color_map):
    """색상에 대한 변수 이름 생성 또는 기존 이름 반환"""
    color_key = (r, g, b)
    if color_key not in color_map:
        color_count = len(color_map)
        color_map[color_key] = f"COLOR_{color_count}"
    return color_map[color_key]

def generate_sv_case(image_path, sprite_name, transparent_color=None, use_color_names=True):
    """
    이미지를 SystemVerilog case 문으로 변환

    Args:
        image_path: PNG/BMP 파일 경로
        sprite_name: 스프라이트 이름 (주석용)
        transparent_color: 투명으로 처리할 RGB (r, g, b) 튜플
        use_color_names: True면 색상을 변수로, False면 직접 값으로
    """
    try:
        img = Image.open(image_path).convert('RGBA')
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return

    # 16x16 확인 및 리사이즈
    if img.size != (16, 16):
        print(f"Warning: Image is {img.size}, resizing to 16x16", file=sys.stderr)
        img = img.resize((16, 16), Image.NEAREST)

    pixels = img.load()

    # 색상 맵 생성
    color_map = {}

    # 픽셀 데이터 수집
    sprite_data = {}
    for y in range(16):
        sprite_data[y] = {}
        for x in range(16):
            r, g, b, a = pixels[x, y]

            # 투명 픽셀 체크
            is_transparent = False
            if a < 128:  # Alpha가 낮으면 투명
                is_transparent = True
            elif transparent_color and (r, g, b) == transparent_color:
                is_transparent = True

            if not is_transparent:
                sprite_data[y][x] = (r, g, b)
                if use_color_names:
                    get_color_name(r, g, b, color_map)

    # 색상 정의 출력 (localparam)
    if use_color_names:
        print(f"// {sprite_name} Color Palette")
        for (r, g, b), name in sorted(color_map.items(), key=lambda x: x[1]):
            print(f"localparam rgb_t {sprite_name}_{name} = '{rgb_to_sv_color(r, g, b)};")
        print()

    # Case 문 생성
    print(f"// {sprite_name} sprite (16x16)")
    print(f"case (sprite_y)")

    for y in range(16):
        if y not in sprite_data or len(sprite_data[y]) == 0:
            # 빈 행은 건너뛰기
            continue

        print(f"    // Row {y}")
        print(f"    4'd{y}: begin")
        print(f"        case (sprite_x)")

        # 같은 색상의 연속된 픽셀들을 그룹화
        row_data = sprite_data[y]
        x_positions = sorted(row_data.keys())

        # 색상별로 x 좌표 그룹화
        color_groups = defaultdict(list)
        for x in x_positions:
            color = row_data[x]
            color_groups[color].append(x)

        for color, x_list in sorted(color_groups.items()):
            r, g, b = color
            if use_color_names:
                color_str = f"{sprite_name}_{color_map[color]}"
            else:
                color_str = rgb_to_sv_color(r, g, b)

            # x 좌표들을 콤마로 연결
            x_coords = ", ".join([f"4'd{x}" for x in x_list])
            print(f"            {x_coords}: begin")
            print(f"                color = {color_str};")
            print(f"                enable = 1'b1;")
            print(f"            end")

        print(f"            default: begin")
        print(f"                enable = 1'b0;")
        print(f"            end")
        print(f"        endcase")
        print(f"    end")
        print()

    print(f"    default: begin")
    print(f"        enable = 1'b0;")
    print(f"        color = TRANSPARENT;")
    print(f"    end")
    print(f"endcase")
    print()

    # 통계
    total_pixels = sum(len(row) for row in sprite_data.values())
    print(f"// Statistics:")
    print(f"// Total non-transparent pixels: {total_pixels}")
    print(f"// Unique colors: {len(color_map)}")
    print(f"// Transparency: {256 - total_pixels} pixels")

def main():
    parser = argparse.ArgumentParser(
        description='Convert Piskel PNG/BMP to SystemVerilog case statement'
    )
    parser.add_argument('image', help='Input PNG or BMP file (16x16)')
    parser.add_argument('name', help='Sprite name (e.g., KIRBY, DEE)')
    parser.add_argument('--transparent', '-t',
                        help='Transparent color as R,G,B (e.g., 255,0,255)')
    parser.add_argument('--no-color-names', action='store_true',
                        help='Use direct color values instead of variable names')

    args = parser.parse_args()

    # 투명색 파싱
    transparent_color = None
    if args.transparent:
        try:
            r, g, b = map(int, args.transparent.split(','))
            transparent_color = (r, g, b)
        except:
            print("Error: Invalid transparent color format. Use R,G,B (e.g., 255,0,255)",
                  file=sys.stderr)
            sys.exit(1)

    generate_sv_case(args.image, args.name, transparent_color,
                     not args.no_color_names)

if __name__ == "__main__":
    main()
