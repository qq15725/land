from pathlib import Path
from PIL import Image, ImageEnhance, ImageDraw


ENV_ATLAS = Path("/Users/wxm/.codex/generated_images/019e0cfa-f5b3-74b3-81a0-80ebc031c437/ig_02b502c468532fc80169ff54e72cfc819187406312d79665b1.png")
BUILDING_ATLAS = Path("/Users/wxm/.codex/generated_images/019e0cfa-f5b3-74b3-81a0-80ebc031c437/ig_02b502c468532fc80169ff55313a508191bfc1765056d6eca2.png")
ITEM_ATLAS = Path("/Users/wxm/.codex/generated_images/019e0cfa-f5b3-74b3-81a0-80ebc031c437/ig_02b502c468532fc80169ff57d3b0bc81919006465064d0cd64.png")


def keyed_rgba(img: Image.Image) -> Image.Image:
    rgba = img.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = pixels[x, y]
            if (r > 180 and b > 150 and g < 120) or (r > 95 and b > 95 and g < 90 and abs(r - b) < 90):
                pixels[x, y] = (0, 0, 0, 0)
    return rgba


def trim(img: Image.Image) -> Image.Image:
    bbox = img.getbbox()
    if not bbox:
        return img
    return img.crop(bbox)


def cell(atlas: Image.Image, cols: int, rows: int, col: int, row: int) -> Image.Image:
    w = atlas.width // cols
    h = atlas.height // rows
    return atlas.crop((col * w, row * h, (col + 1) * w, (row + 1) * h))


def fit_sprite(src: Image.Image, size: tuple[int, int], bottom_pad: int = 0) -> Image.Image:
    src = trim(keyed_rgba(src))
    max_w = max(1, size[0] - 8)
    max_h = max(1, size[1] - 8 - bottom_pad)
    scale = min(max_w / src.width, max_h / src.height)
    resized = src.resize((max(1, int(src.width * scale)), max(1, int(src.height * scale))), Image.Resampling.NEAREST)
    pixels = resized.load()
    for y in range(resized.height):
        for x in range(resized.width):
            r, g, b, a = pixels[x, y]
            if a < 80 or ((r > 80 and b > 80 and g < 120 and (r + b) > g * 3) and a < 180):
                pixels[x, y] = (0, 0, 0, 0)
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    x = (size[0] - resized.width) // 2
    y = size[1] - resized.height - bottom_pad
    out.alpha_composite(resized, (x, y))
    return out


def damaged_variant(img: Image.Image, level: int) -> Image.Image:
    out = keyed_rgba(img)
    alpha = out.getchannel("A")
    rgb = out.convert("RGB")
    if level == 1:
        rgb = ImageEnhance.Brightness(rgb).enhance(0.82)
        rgb = ImageEnhance.Contrast(rgb).enhance(1.08)
    else:
        rgb = ImageEnhance.Brightness(rgb).enhance(0.55)
        rgb = ImageEnhance.Color(rgb).enhance(0.55)
    out = rgb.convert("RGBA")
    out.putalpha(alpha)
    draw = ImageDraw.Draw(out)
    color = (35, 28, 22, 190)
    if level == 1:
        draw.line([(out.width * 0.35, out.height * 0.36), (out.width * 0.48, out.height * 0.44), (out.width * 0.42, out.height * 0.52)], fill=color, width=3)
        draw.line([(out.width * 0.58, out.height * 0.45), (out.width * 0.70, out.height * 0.53)], fill=color, width=2)
    else:
        draw.rectangle((0, 0, out.width * 0.28, out.height * 0.45), fill=(0, 0, 0, 0))
        draw.rectangle((out.width * 0.70, 0, out.width, out.height * 0.38), fill=(0, 0, 0, 0))
        draw.line([(out.width * 0.28, out.height * 0.48), (out.width * 0.58, out.height * 0.58)], fill=color, width=3)
    return out


def save_breakable(path: str, frames: list[Image.Image], frame_size: tuple[int, int]) -> None:
    out = Image.new("RGBA", (frame_size[0], frame_size[1] * 3), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        out.alpha_composite(fit_sprite(frame, frame_size), (0, i * frame_size[1]))
    out.save(path)


def save_static(path: str, src: Image.Image, size: tuple[int, int]) -> None:
    fit_sprite(src, size).save(path)


def save_ground_tiles(path: str, env: Image.Image) -> None:
    # TileMap 当前使用 4 个 16x16 顶视图瓦片。这里从生成图提取主色，再做可平铺像素纹理。
    colors = [
        ("#72bd1d", ["#9ee035", "#55a01a", "#3f8418", "#b9ee3b"]),
        ("#d7b267", ["#f2cf82", "#b98b42", "#e7c477", "#9f7536"]),
        ("#5c351d", ["#8a572c", "#3a2215", "#754421", "#2b1a11"]),
        ("#8f9493", ["#babebc", "#686e70", "#cfd1cf", "#54595b"]),
    ]
    img = Image.new("RGB", (64, 16), "#000")
    px = img.load()
    for tile, (base, variants) in enumerate(colors):
        ox = tile * 16
        for y in range(16):
            for x in range(16):
                idx = (x * 31 + y * 17 + tile * 13) % (len(variants) + 3)
                px[ox + x, y] = Image.new("RGB", (1, 1), variants[idx] if idx < len(variants) else base).getpixel((0, 0))
    draw = ImageDraw.Draw(img)
    for y in [3, 7, 11, 15]:
        draw.line((32, y, 47, y), fill="#2b1a10")
    draw.line((50, 4, 55, 4, 55, 7), fill="#45494a")
    draw.line((58, 10, 63, 10), fill="#45494a")
    img.save(path)


def save_item_icons(path: str, atlas: Image.Image) -> None:
    out = Image.new("RGBA", (256, 128), (0, 0, 0, 0))
    for row in range(2):
        for col in range(4):
            sprite = fit_sprite(cell(atlas, 4, 2, col, row), (64, 64))
            out.alpha_composite(sprite, (col * 64, row * 64))
    out.save(path)


def main() -> None:
    env = Image.open(ENV_ATLAS)
    buildings = Image.open(BUILDING_ATLAS)
    items = Image.open(ITEM_ATLAS)

    Path("assets/sprites/environment").mkdir(parents=True, exist_ok=True)
    Path("assets/sprites/buildings").mkdir(parents=True, exist_ok=True)
    Path("assets/sprites/items").mkdir(parents=True, exist_ok=True)

    tree_frames = [cell(env, 3, 6, 0, 0), cell(env, 3, 6, 1, 0), cell(env, 3, 6, 2, 0)]
    save_breakable("assets/sprites/environment/tree.png", tree_frames, (128, 192))

    stone_frames = [cell(env, 3, 6, 0, 1), cell(env, 3, 6, 1, 1), cell(env, 3, 6, 2, 1)]
    save_breakable("assets/sprites/environment/stone.png", stone_frames, (128, 96))

    bush = cell(env, 3, 6, 1, 2)
    save_breakable("assets/sprites/environment/berry_bush.png", [bush, damaged_variant(bush, 1), damaged_variant(bush, 2)], (128, 128))

    save_static("assets/sprites/environment/grass.png", cell(env, 3, 6, 0, 2), (64, 64))
    save_static("assets/sprites/environment/dead_tree.png", cell(env, 3, 6, 2, 2), (96, 192))
    save_static("assets/sprites/environment/mushroom.png", cell(env, 3, 6, 0, 3), (64, 96))
    save_ground_tiles("assets/sprites/environment/ground_tiles.png", env)

    save_static("assets/sprites/buildings/workbench.png", cell(buildings, 3, 2, 0, 0), (192, 192))
    save_static("assets/sprites/buildings/storage_chest.png", cell(buildings, 3, 2, 1, 0), (192, 192))
    save_static("assets/sprites/buildings/cooking_pot.png", cell(buildings, 3, 2, 2, 0), (192, 192))
    save_static("assets/sprites/buildings/farm_plot.png", cell(buildings, 3, 2, 0, 1), (192, 192))
    save_static("assets/sprites/buildings/trading_post.png", cell(buildings, 3, 2, 1, 1), (256, 256))
    save_item_icons("assets/sprites/items/icons.png", items)


if __name__ == "__main__":
    main()
