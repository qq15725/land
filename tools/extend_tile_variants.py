"""
在现有 ground_tiles.png 右侧追加内部格（mask=15）装饰变体列。
每种地形生成 N 列变体，程序化在 mask=15 基础格上叠加草丛/野花像素。
等 AI 生成高质量变体后，直接替换对应列即可。

用法：
  python tools/extend_tile_variants.py
  python tools/extend_tile_variants.py --variants 3 --seed 42
"""
import argparse
import random
from pathlib import Path
from PIL import Image

CELL = 64
TERRAIN_ROWS = 4
BASE_INTERIOR_COL = 15   # mask=15 在 atlas 中的列索引


def _make_tuft_variant(base: Image.Image, rng: random.Random) -> Image.Image:
    """草丛变体：随机深色小簇（模拟草芽/矮丛）"""
    v = base.copy().convert("RGBA")
    px = v.load()
    w, h = v.size
    for _ in range(rng.randint(6, 10)):
        cx = rng.randint(3, w - 4)
        cy = rng.randint(3, h - 4)
        r, g, b, a = px[cx, cy]
        dark = (max(0, r - rng.randint(35, 60)),
                max(0, g - rng.randint(35, 60)),
                max(0, b - rng.randint(20, 40)),
                255)
        # 竖向细条（2×3 像素，跳过斜角 → 更像草叶）
        for dy in range(-1, 2):
            for dx in (-1, 0, 1):
                if abs(dx) == 1 and dy != 0:
                    continue
                nx, ny = cx + dx, cy + dy
                if 0 <= nx < w and 0 <= ny < h:
                    px[nx, ny] = dark
    return v


def _make_flower_variant(base: Image.Image, rng: random.Random, row: int) -> Image.Image:
    """野花变体：3-5 个十字形亮色像素（草地/路面专属配色）"""
    v = base.copy().convert("RGBA")
    px = v.load()
    w, h = v.size
    palettes = [
        [(220, 180,  60, 255), (255, 240, 120, 255), (180, 220,  80, 255)],  # grass: 黄/浅绿
        [(200, 160,  80, 255), (220, 190, 100, 255)],                          # path: 土黄
        [(160, 110,  60, 255), (140, 100,  50, 255)],                          # farmland: 深棕
        [(160, 160, 160, 255), (200, 200, 200, 255)],                          # stone: 灰白
    ]
    colors = palettes[min(row, len(palettes) - 1)]
    for _ in range(rng.randint(3, 5)):
        cx = rng.randint(3, w - 4)
        cy = rng.randint(3, h - 4)
        col = colors[rng.randint(0, len(colors) - 1)]
        for dy, dx in [(0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)]:
            nx, ny = cx + dx, cy + dy
            if 0 <= nx < w and 0 <= ny < h:
                px[nx, ny] = col
    return v


def _make_sparse_variant(base: Image.Image, rng: random.Random) -> Image.Image:
    """稀疏噪点变体：随机亮暗像素（模拟地面细粒感）"""
    v = base.copy().convert("RGBA")
    px = v.load()
    w, h = v.size
    for _ in range(rng.randint(12, 20)):
        x = rng.randint(0, w - 1)
        y = rng.randint(0, h - 1)
        r, g, b, a = px[x, y]
        delta = rng.randint(-25, 25)
        px[x, y] = (
            max(0, min(255, r + delta)),
            max(0, min(255, g + delta)),
            max(0, min(255, b + delta)),
            255,
        )
    return v


_VARIANT_GENERATORS = [_make_tuft_variant, _make_flower_variant, _make_sparse_variant]


def extend(atlas_path: Path, variant_count: int, seed: int) -> None:
    atlas = Image.open(atlas_path).convert("RGBA")
    orig_w, orig_h = atlas.size
    expected_h = TERRAIN_ROWS * CELL
    if orig_h != expected_h:
        raise ValueError(f"atlas 高度应为 {expected_h}px，实际 {orig_h}px")

    new_w = orig_w + variant_count * CELL
    new_atlas = Image.new("RGBA", (new_w, orig_h))
    new_atlas.paste(atlas, (0, 0))

    rng = random.Random(seed)
    gen_fns = _VARIANT_GENERATORS

    for var_idx in range(variant_count):
        gen_fn = gen_fns[var_idx % len(gen_fns)]
        for row in range(TERRAIN_ROWS):
            base_x = BASE_INTERIOR_COL * CELL
            base_tile = atlas.crop((base_x, row * CELL, base_x + CELL, (row + 1) * CELL))
            if gen_fn == _make_flower_variant:
                variant = gen_fn(base_tile, rng, row)
            else:
                variant = gen_fn(base_tile, rng)
            dest_x = orig_w + var_idx * CELL
            new_atlas.paste(variant, (dest_x, row * CELL))

    new_atlas.save(atlas_path)
    print(f"✓ {atlas_path}  {orig_w}×{orig_h} → {new_w}×{orig_h}  (+{variant_count} 变体列)")


def main() -> None:
    parser = argparse.ArgumentParser(description="为 ground_tiles.png 追加内部格装饰变体列")
    parser.add_argument("--atlas", default=Path("assets/sprites/environment/ground_tiles.png"), type=Path)
    parser.add_argument("--variants", default=3, type=int, help="追加变体列数（默认 3）")
    parser.add_argument("--seed", default=42, type=int)
    args = parser.parse_args()
    extend(args.atlas, args.variants, args.seed)


if __name__ == "__main__":
    main()
