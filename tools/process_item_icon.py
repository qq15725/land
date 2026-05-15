#!/usr/bin/env python3
"""Convert generated chroma-key item art into a 64x64 transparent icon."""

from __future__ import annotations

import os
import sys
from pathlib import Path

from PIL import Image


def is_key_pixel(r: int, g: int, b: int) -> bool:
    return g > 180 and r < 90 and b < 90


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: process_item_icon.py <input.png> <output.png>", file=sys.stderr)
        return 2

    src = Path(sys.argv[1])
    out = Path(sys.argv[2])
    image = Image.open(src).convert("RGBA")
    pixels = image.load()
    width, height = image.size

    xs: list[int] = []
    ys: list[int] = []
    for y in range(height):
        for x in range(width):
            r, g, b, _a = pixels[x, y]
            if is_key_pixel(r, g, b):
                pixels[x, y] = (0, 255, 0, 0)
            else:
                xs.append(x)
                ys.append(y)

    if xs:
        pad = 8
        box = (
            max(min(xs) - pad, 0),
            max(min(ys) - pad, 0),
            min(max(xs) + pad + 1, width),
            min(max(ys) + pad + 1, height),
        )
        image = image.crop(box)

    icon_max = 54
    crop_width, crop_height = image.size
    scale = min(icon_max / crop_width, icon_max / crop_height)
    new_size = (max(1, round(crop_width * scale)), max(1, round(crop_height * scale)))
    image = image.resize(new_size, Image.Resampling.NEAREST)

    canvas = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    canvas.alpha_composite(image, ((64 - new_size[0]) // 2, (64 - new_size[1]) // 2))

    os.makedirs(out.parent, exist_ok=True)
    canvas.save(out)
    print(out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
