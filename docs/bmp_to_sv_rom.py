#!/usr/bin/env python3
"""
BMP to SystemVerilog ROM converter
16x16 이미지를 SystemVerilog localparam 배열로 변환

사용법:
    python bmp_to_sv_rom.py kirby.bmp KIRBY
    python bmp_to_sv_rom.py dee.bmp DEE
"""

from PIL import Image
import sys

def bmp_to_sv_rom(filename, rom_name, transparent_color=None):
    """
    BMP 파일을 SystemVerilog ROM 배열로 변환

    Args:
        filename: BMP 파일 경로
        rom_name: ROM 이름 (예: KIRBY, DEE)
        transparent_color: 투명으로 처리할 RGB 색상 (예: (255, 0, 255))
    """
    try:
        img = Image.open(filename).convert('RGB')
    except Exception as e:
        print(f"Error opening image: {e}", file=sys.stderr)
        return

    # 16x16 크기 확인
    if img.size != (16, 16):
        print(f"Warning: Image size is {img.size}, resizing to 16x16", file=sys.stderr)
        img = img.resize((16, 16), Image.NEAREST)

    pixels = img.load()

    print(f"// {rom_name} sprite ROM (16x16 pixels, RGB444 format)")
    print(f"// Generated from: {filename}")
    print(f"// Transparent color: {transparent_color if transparent_color else 'None (use 12'h000)'}")
    print(f"localparam logic [11:0] {rom_name}_ROM [0:255] = '{{")

    pixel_count = 0
    for y in range(16):
        print(f"    // Row {y}", end=" ")
        for x in range(16):
            r, g, b = pixels[x, y]

            # 투명색 체크
            if transparent_color and (r, g, b) == transparent_color:
                rgb444 = 0x000
            else:
                # RGB888 → RGB444 변환
                r4 = r >> 4
                g4 = g >> 4
                b4 = b >> 4
                rgb444 = (r4 << 8) | (g4 << 4) | b4

            print(f"12'h{rgb444:03X}", end="")

            pixel_count += 1
            if pixel_count < 256:
                print(",", end=" ")

            # 8픽셀마다 줄바꿈
            if (x + 1) % 8 == 0 and x < 15:
                print()
                print("             ", end=" ")

        print()

    print("};")
    print()
    print(f"// Total pixels: {pixel_count}")
    print(f"// ROM size: {pixel_count * 12} bits = {pixel_count * 12 // 8} bytes")

def main():
    if len(sys.argv) < 3:
        print("Usage: python bmp_to_sv_rom.py <input.bmp> <ROM_NAME> [transparent_color]")
        print()
        print("Examples:")
        print("  python bmp_to_sv_rom.py kirby.bmp KIRBY")
        print("  python bmp_to_sv_rom.py dee.bmp DEE")
        print("  python bmp_to_sv_rom.py sprite.bmp SPRITE 255,0,255  # Magenta as transparent")
        sys.exit(1)

    filename = sys.argv[1]
    rom_name = sys.argv[2]

    transparent_color = None
    if len(sys.argv) > 3:
        try:
            r, g, b = map(int, sys.argv[3].split(','))
            transparent_color = (r, g, b)
        except:
            print("Invalid transparent color format. Use: R,G,B (e.g., 255,0,255)", file=sys.stderr)
            sys.exit(1)

    bmp_to_sv_rom(filename, rom_name, transparent_color)

if __name__ == "__main__":
    main()
