#!/usr/bin/env python3
"""
PNG to .mem file converter for Verilog/SystemVerilog
16x16 PNG 이미지를 RGB444 .mem 파일로 변환

사용법:
    python png_to_mem.py input.png output.mem
    python png_to_mem.py kirby.png src/kerby.mem
"""

from PIL import Image
import sys
import os

def png_to_mem(png_file, mem_file, transparent_color=None):
    """
    PNG 파일을 .mem 파일로 변환

    Args:
        png_file: 입력 PNG 파일 (16x16)
        mem_file: 출력 .mem 파일
        transparent_color: 투명으로 처리할 RGB 튜플 (r, g, b)
    """
    try:
        img = Image.open(png_file).convert('RGBA')
    except Exception as e:
        print(f"Error opening image: {e}", file=sys.stderr)
        return False

    # 16x16 확인 및 리사이즈
    if img.size != (16, 16):
        print(f"Warning: Image is {img.size}, resizing to 16x16", file=sys.stderr)
        img = img.resize((16, 16), Image.NEAREST)

    pixels = img.load()

    # .mem 파일 작성
    try:
        with open(mem_file, 'w') as f:
            f.write(f"// Generated from: {os.path.basename(png_file)}\n")
            f.write(f"// Format: RGB444 (12-bit per pixel)\n")
            f.write(f"// Size: 16x16 = 256 pixels\n")
            if transparent_color:
                f.write(f"// Transparent color: RGB{transparent_color}\n")
            f.write(f"// 000 = Transparent (Black)\n")
            f.write(f"\n")

            pixel_count = 0
            transparent_count = 0

            for y in range(16):
                f.write(f"// Row {y} (Pixel {y*16}-{y*16+15})\n")

                for x in range(16):
                    r, g, b, a = pixels[x, y]

                    # 투명 처리
                    is_transparent = False
                    if a < 128:  # Alpha가 낮으면 투명
                        is_transparent = True
                    elif transparent_color and (r, g, b) == transparent_color:
                        is_transparent = True

                    if is_transparent:
                        # 투명 = 검정 (000)
                        f.write("000")
                        transparent_count += 1
                    else:
                        # RGB888 → RGB444 변환
                        r4 = r >> 4
                        g4 = g >> 4
                        b4 = b >> 4
                        rgb444 = (r4 << 8) | (g4 << 4) | b4
                        f.write(f"{rgb444:03X}")

                    f.write("\n")
                    pixel_count += 1

                f.write("\n")

            # 통계
            print(f"Conversion complete!")
            print(f"  Input:  {png_file}")
            print(f"  Output: {mem_file}")
            print(f"  Total pixels: {pixel_count}")
            print(f"  Transparent:  {transparent_count} ({transparent_count*100//pixel_count}%)")
            print(f"  Opaque:       {pixel_count - transparent_count} ({(pixel_count - transparent_count)*100//pixel_count}%)")

            return True

    except Exception as e:
        print(f"Error writing .mem file: {e}", file=sys.stderr)
        return False

def main():
    if len(sys.argv) < 3:
        print("Usage: python png_to_mem.py <input.png> <output.mem> [transparent_color]")
        print()
        print("Examples:")
        print("  python png_to_mem.py kirby.png src/kerby.mem")
        print("  python png_to_mem.py sprite.png sprite.mem 255,0,255  # Magenta transparent")
        sys.exit(1)

    png_file = sys.argv[1]
    mem_file = sys.argv[2]

    # 투명색 파싱
    transparent_color = None
    if len(sys.argv) > 3:
        try:
            r, g, b = map(int, sys.argv[3].split(','))
            transparent_color = (r, g, b)
        except:
            print("Error: Invalid transparent color. Use: R,G,B (e.g., 255,0,255)", file=sys.stderr)
            sys.exit(1)

    # 변환 실행
    success = png_to_mem(png_file, mem_file, transparent_color)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
