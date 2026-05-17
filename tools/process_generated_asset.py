#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def parse_color(value: str) -> tuple[int, int, int]:
    value = value.strip().lstrip("#")
    if len(value) != 6:
        raise ValueError("color must be RRGGBB")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def sample_border_key(img: Image.Image) -> tuple[int, int, int]:
    rgb = img.convert("RGB")
    width, height = rgb.size
    samples: list[tuple[int, int, int]] = []
    for x in range(width):
        samples.append(rgb.getpixel((x, 0)))
        samples.append(rgb.getpixel((x, height - 1)))
    for y in range(height):
        samples.append(rgb.getpixel((0, y)))
        samples.append(rgb.getpixel((width - 1, y)))
    samples.sort(key=lambda c: c[0] + c[1] + c[2])
    mid = len(samples) // 2
    return samples[mid]


def remove_key(img: Image.Image, key: tuple[int, int, int], threshold: int) -> Image.Image:
    rgba = img.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            distance = max(abs(r - key[0]), abs(g - key[1]), abs(b - key[2]))
            if distance <= threshold:
                pixels[x, y] = (r, g, b, 0)
    return rgba


def remove_magenta_key(img: Image.Image, threshold: int) -> Image.Image:
    rgba = img.convert("RGBA")
    pixels = rgba.load()
    width, height = rgba.size
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if r > 150 and b > 150 and g < 90 and abs(r - b) <= threshold:
                pixels[x, y] = (r, g, b, 0)
    return rgba


def fit_canvas(img: Image.Image, size: tuple[int, int]) -> Image.Image:
    target_w, target_h = size
    src_w, src_h = img.size
    scale = min(target_w / src_w, target_h / src_h)
    resized = img.resize(
        (max(1, round(src_w * scale)), max(1, round(src_h * scale))),
        Image.Resampling.NEAREST,
    )
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    x = (target_w - resized.width) // 2
    y = (target_h - resized.height) // 2
    canvas.alpha_composite(resized, (x, y))
    return canvas


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output")
    parser.add_argument("--width", type=int)
    parser.add_argument("--height", type=int)
    parser.add_argument("--key", default="#ff00ff")
    parser.add_argument("--threshold", type=int, default=12)
    parser.add_argument("--opaque", action="store_true")
    parser.add_argument("--auto-key-border", action="store_true")
    parser.add_argument("--magenta-key", action="store_true")
    parser.add_argument("--split-dir")
    parser.add_argument("--names")
    parser.add_argument("--cols", type=int)
    parser.add_argument("--rows", type=int)
    parser.add_argument("--cell-width", type=int)
    parser.add_argument("--cell-height", type=int)
    args = parser.parse_args()

    img = Image.open(args.input)
    if args.opaque:
        processed = img.convert("RGBA")
    elif args.magenta_key:
        processed = remove_magenta_key(img, args.threshold)
    else:
        key = sample_border_key(img) if args.auto_key_border else parse_color(args.key)
        processed = remove_key(img, key, args.threshold)

    if args.split_dir:
        if not all([args.names, args.cols, args.rows, args.cell_width, args.cell_height]):
            raise ValueError("split mode requires names, cols, rows, cell-width, and cell-height")
        names = [name.strip() for name in args.names.split(",") if name.strip()]
        sheet = fit_canvas(processed, (args.cols * args.cell_width, args.rows * args.cell_height))
        out_dir = Path(args.split_dir)
        out_dir.mkdir(parents=True, exist_ok=True)
        for index, name in enumerate(names):
            x = index % args.cols * args.cell_width
            y = index // args.cols * args.cell_height
            cell = sheet.crop((x, y, x + args.cell_width, y + args.cell_height))
            out = out_dir / f"{name}.png"
            cell.save(out)
            print(f"{out}: {cell.size[0]}x{cell.size[1]} {cell.mode}")
        return

    if not args.output or not args.width or not args.height:
        raise ValueError("single mode requires output, width, and height")
    processed = fit_canvas(processed, (args.width, args.height))
    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    processed.save(out)
    check = Image.open(out)
    print(f"{out}: {check.size[0]}x{check.size[1]} {check.mode}")


if __name__ == "__main__":
    main()
