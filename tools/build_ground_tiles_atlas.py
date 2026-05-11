"""
将 4 张 AI 生成的 1024×64 px 地形条带合成为 1024×256 的 atlas。
行顺序固定：草地（row 0）、小路（row 1）、耕地（row 2）、石地（row 3）。
每张条带应为 AI 按提示词直接绘制，包含所有 16 个掩码图块的过渡效果。
"""
import argparse
from pathlib import Path
from PIL import Image


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Stack 4 AI-generated terrain strips (1024×64 each) into ground_tiles.png (1024×256)."
    )
    parser.add_argument("--grass",    required=True, type=Path, help="草地条带 1024×64 px")
    parser.add_argument("--path",     required=True, type=Path, help="小路条带 1024×64 px")
    parser.add_argument("--farmland", required=True, type=Path, help="耕地条带 1024×64 px")
    parser.add_argument("--stone",    required=True, type=Path, help="石地条带 1024×64 px")
    parser.add_argument("--out", default=Path("assets/sprites/environment/ground_tiles.png"), type=Path)
    args = parser.parse_args()

    strips = [args.grass, args.path, args.farmland, args.stone]
    atlas = Image.new("RGB", (1024, 256))

    for row, strip_path in enumerate(strips):
        strip = Image.open(strip_path).convert("RGB")
        if strip.width != 1024 or strip.height != 64:
            # 尺寸不符时用 NEAREST 保持像素硬边
            strip = strip.resize((1024, 64), Image.Resampling.NEAREST)
        atlas.paste(strip, (0, row * 64))

    args.out.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(args.out)
    print(f"atlas saved: {args.out}  ({atlas.width}x{atlas.height})")


if __name__ == "__main__":
    main()
