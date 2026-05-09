from PIL import Image, ImageDraw


SCALE = 4


def save_scaled(img, path):
    size = (img.width * SCALE, img.height * SCALE)
    img.resize(size, Image.Resampling.NEAREST).save(path)


def ensure_dirs():
    from pathlib import Path

    for path in [
        "assets/sprites/characters",
        "assets/sprites/environment",
        "assets/sprites/buildings",
        "assets/sprites/items",
        "assets/sprites/ui",
    ]:
        Path(path).mkdir(parents=True, exist_ok=True)


def px(draw, xy, fill):
    draw.rectangle(xy, fill=fill)


def speckles(draw, rect, colors, step=5, seed=0):
    x0, y0, x1, y1 = rect
    for y in range(y0, y1 + 1, step):
        for x in range(x0 + ((y + seed) % step), x1 + 1, step):
            idx = (x * 3 + y * 5 + seed) % len(colors)
            px(draw, (x, y, x + 1, y + 1), colors[idx])


def textured_rect(draw, rect, base, lights, step=5, seed=0):
    px(draw, rect, base)
    speckles(draw, rect, lights, step, seed)


def outline_rect(draw, rect, light, dark):
    x0, y0, x1, y1 = rect
    px(draw, (x0, y0, x1, y0), light)
    px(draw, (x0, y0, x0, y1), light)
    px(draw, (x0, y1, x1, y1), dark)
    px(draw, (x1, y0, x1, y1), dark)


def iso_block(draw, x, y, w, h, top, left, right, detail="grass"):
    top_h = max(5, h // 4)
    textured_rect(draw, (x, y, x + w - 1, y + top_h - 1), top, ["#9ee21c", "#6fbd12", "#c3ef32"], 4, x + y)
    textured_rect(draw, (x, y + top_h, x + w // 2 - 1, y + h - 1), left, ["#8a5a29", "#5a3519", "#2f8a1e"], 5, x)
    textured_rect(draw, (x + w // 2, y + top_h, x + w - 1, y + h - 1), right, ["#6a3f1f", "#3f2716", "#23721b"], 5, y)
    outline_rect(draw, (x, y, x + w - 1, y + h - 1), "#d4f35a", "#2f220f")
    if detail == "stone":
        speckles(draw, (x + 1, y + 1, x + w - 2, y + h - 2), ["#c6c8c8", "#777b7c", "#56595b"], 4, x)
    elif detail == "wood":
        for yy in range(y + top_h + 3, y + h - 2, 5):
            px(draw, (x + 2, yy, x + w - 3, yy + 1), "#5b351b")


def frame_rect(origin, rect):
    ox, oy = origin
    x0, y0, x1, y1 = rect
    return ox + x0, oy + y0, ox + x1, oy + y1


def draw_block_person(draw, origin, palette, direction, step, hat=False, pack=False):
    ox, oy = origin
    sway = [-2, 0, 2, 0][step]
    head_y = 7
    body_y = 28
    if direction == "up":
        face = palette["hair"]
    elif direction == "left":
        face = palette["skin_dark"]
    else:
        face = palette["skin"]

    if hat:
        textured_rect(draw, (ox + 5, oy + head_y - 4, ox + 26, oy + head_y), palette["hat_dark"], ["#d39a43", "#83551e"], 4, step)
        textured_rect(draw, (ox + 9, oy + head_y - 10, ox + 22, oy + head_y - 2), palette["hat"], ["#dba84d", "#7d501d"], 4, step)

    textured_rect(draw, (ox + 9, oy + head_y, ox + 23, oy + head_y + 15), face, [palette["skin_light"], palette["skin_dark"]], 5, step)
    px(draw, (ox + 9, oy + head_y, ox + 23, oy + head_y + 3), palette["hair"])
    px(draw, (ox + 9, oy + head_y, ox + 12, oy + head_y + 15), palette["skin_light"])
    if direction != "up":
        px(draw, (ox + 13, oy + head_y + 7, ox + 14, oy + head_y + 8), palette["eye"])
        px(draw, (ox + 19, oy + head_y + 7, ox + 20, oy + head_y + 8), palette["eye"])

    textured_rect(draw, (ox + 8, oy + body_y, ox + 24, oy + body_y + 20), palette["shirt"], [palette["shirt_hi"], palette["shirt_shadow"]], 5, step)
    px(draw, (ox + 10, oy + body_y + 7, ox + 22, oy + body_y + 26), palette["pants"])
    px(draw, (ox + 10, oy + body_y + 7, ox + 13, oy + body_y + 26), palette["pants_hi"])
    px(draw, (ox + 6 + sway, oy + body_y + 2, ox + 10 + sway, oy + body_y + 19), palette["sleeve"])
    px(draw, (ox + 22 - sway, oy + body_y + 2, ox + 26 - sway, oy + body_y + 19), palette["sleeve"])
    px(draw, (ox + 11 - sway, oy + 52, ox + 15 - sway, oy + 60), palette["boot"])
    px(draw, (ox + 18 + sway, oy + 52, ox + 22 + sway, oy + 60), palette["boot"])
    if pack and direction in ["up", "left", "right"]:
        textured_rect(draw, (ox + 7, oy + 30, ox + 25, oy + 46), palette["pack"], [palette["pack_hi"], "#4a2c17"], 5, step)
        px(draw, (ox + 10, oy + 32, ox + 22, oy + 35), palette["pack_hi"])


def draw_creature(draw, origin, kind, direction, step):
    ox, oy = origin
    bounce = [0, -2, 0, 1][step]
    if kind == "slime":
        textured_rect(draw, (ox + 7, oy + 30 + bounce, ox + 25, oy + 53 + bounce), "#44b94a", ["#8aec59", "#247f31"], 4, step)
        px(draw, (ox + 7, oy + 30 + bounce, ox + 25, oy + 37 + bounce), "#65d96a")
        px(draw, (ox + 12, oy + 42 + bounce, ox + 14, oy + 44 + bounce), "#17351b")
        px(draw, (ox + 19, oy + 42 + bounce, ox + 21, oy + 44 + bounce), "#17351b")
        return
    if kind == "skeleton":
        bone = "#e8e2cf"
        shade = "#b9b39f"
        textured_rect(draw, (ox + 9, oy + 10 + bounce, ox + 23, oy + 24 + bounce), bone, ["#fff9e8", shade], 5, step)
        px(draw, (ox + 12, oy + 17 + bounce, ox + 14, oy + 19 + bounce), "#202020")
        px(draw, (ox + 19, oy + 17 + bounce, ox + 21, oy + 19 + bounce), "#202020")
        px(draw, (ox + 13, oy + 28 + bounce, ox + 19, oy + 43 + bounce), bone)
        px(draw, (ox + 8 + step % 2, oy + 29, ox + 11 + step % 2, oy + 47), shade)
        px(draw, (ox + 22 - step % 2, oy + 29, ox + 25 - step % 2, oy + 47), shade)
        px(draw, (ox + 11, oy + 44, ox + 14, oy + 59), bone)
        px(draw, (ox + 19, oy + 44, ox + 22, oy + 59), bone)
        return
    if kind == "chicken":
        textured_rect(draw, (ox + 7, oy + 31 + bounce, ox + 25, oy + 48 + bounce), "#f4f0df", ["#ffffff", "#d8ceb8"], 5, step)
        textured_rect(draw, (ox + 10, oy + 21 + bounce, ox + 23, oy + 35 + bounce), "#fff8e7", ["#ffffff", "#d8ceb8"], 5, step)
        px(draw, (ox + 22, oy + 28 + bounce, ox + 27, oy + 31 + bounce), "#f0a21a")
        px(draw, (ox + 15, oy + 27 + bounce, ox + 16, oy + 28 + bounce), "#1f1f1f")
        px(draw, (ox + 12, oy + 48, ox + 14, oy + 55), "#d48810")
        px(draw, (ox + 20, oy + 48, ox + 22, oy + 55), "#d48810")


def character_sheet(path, subject):
    img = Image.new("RGBA", (128, 256), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    dirs = ["down", "up", "left", "right"]
    for row, direction in enumerate(dirs):
        for col in range(4):
            origin = (col * 32, row * 64)
            if subject == "player":
                draw_block_person(draw, origin, {
                    "skin": "#d99a66", "skin_light": "#efb47d", "skin_dark": "#a86b43",
                    "hair": "#5b341b", "eye": "#1f1f1f",
                    "shirt": "#8a572d", "shirt_hi": "#b07035", "shirt_shadow": "#56321b",
                    "sleeve": "#6d4124", "pants": "#2f66b3", "pants_hi": "#4a8bd8", "boot": "#3a2a1c",
                }, direction, col)
            elif subject == "merchant":
                draw_block_person(draw, origin, {
                    "skin": "#c9875d", "skin_light": "#e0a06f", "skin_dark": "#925b3c",
                    "hair": "#3b2618", "eye": "#1f1f1f",
                    "shirt": "#7a4a2f", "shirt_hi": "#9a643d", "shirt_shadow": "#4b2a1b",
                    "sleeve": "#51301f", "pants": "#263b57", "pants_hi": "#3b5578", "boot": "#211913",
                    "hat": "#b88237", "hat_dark": "#6e4a20", "pack": "#7a5431", "pack_hi": "#a07243",
                }, direction, col, hat=True, pack=True)
            else:
                draw_creature(draw, origin, subject, direction, col)
    save_scaled(img, path)


def draw_tree_state(draw, oy, damage):
    textured_rect(draw, (12, oy + 20, 20, oy + 47), "#7c4b21", ["#a86f31", "#4d2e16"], 4, oy)
    px(draw, (14, oy + 20, 16, oy + 47), "#a56b30")
    textured_rect(draw, (4, oy + 9, 27, oy + 27), "#15912d", ["#52c82f", "#09691e"], 3, oy)
    textured_rect(draw, (8, oy + 1, 23, oy + 15), "#48b61f", ["#a0e721", "#1c7d1c"], 3, oy + 2)
    textured_rect(draw, (13, oy + 7, 30, oy + 21), "#217f21", ["#53bf30", "#0e5f17"], 3, oy + 5)
    if damage:
        px(draw, (13, oy + 28, 16, oy + 31), "#2d1d10")
        px(draw, (18, oy + 34, 20, oy + 38), "#2d1d10")
    if damage == 2:
        px(draw, (4, oy + 1, 13, oy + 11), (0, 0, 0, 0))
        px(draw, (23, oy + 13, 30, oy + 22), (0, 0, 0, 0))


def breakable_environment(path, size, kind):
    w, h = size
    img = Image.new("RGBA", (w, h * 3), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    for row in range(3):
        oy = row * h
        if kind == "tree":
            draw_tree_state(draw, oy, row)
        elif kind == "stone":
            textured_rect(draw, (4, oy + 9, 25, oy + 23), "#6f7475", ["#959b9c", "#45494b"], 4, oy)
            textured_rect(draw, (8, oy + 4, 29, oy + 17), "#9ea3a2", ["#c8cbca", "#696e70"], 4, oy + 3)
            px(draw, (10, oy + 5, 23, oy + 8), "#cfd2cf")
            if row:
                px(draw, (13, oy + 10, 16, oy + 12), "#3d4045")
                px(draw, (20, oy + 13, 24, oy + 15), "#3d4045")
            if row == 2:
                px(draw, (5, oy + 8, 11, oy + 12), (0, 0, 0, 0))
                px(draw, (24, oy + 17, 29, oy + 23), (0, 0, 0, 0))
        elif kind == "berry_bush":
            textured_rect(draw, (3, oy + 10, 28, oy + 31), "#248d31", ["#50c740", "#0e5f1d"], 3, oy)
            textured_rect(draw, (6, oy + 5, 24, oy + 20), "#43aa38", ["#8ada3a", "#197326"], 3, oy + 2)
            for x, y in [(9, 13), (18, 10), (22, 21), (13, 23)]:
                px(draw, (x, oy + y, x + 2, oy + y + 2), "#e54237")
            if row:
                px(draw, (7, oy + 18, 11, oy + 21), "#1d5a27")
            if row == 2:
                px(draw, (4, oy + 7, 12, oy + 14), (0, 0, 0, 0))
                px(draw, (20, oy + 19, 28, oy + 28), (0, 0, 0, 0))
    save_scaled(img, path)


def static_environment(path, size, kind):
    w, h = size
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    if kind == "grass":
        textured_rect(draw, (1, 8, 15, 15), "#49b526", ["#9ade2a", "#257e1d"], 3, 4)
        px(draw, (3, 4, 5, 13), "#8ed831")
        px(draw, (8, 2, 10, 14), "#6fc926")
        px(draw, (12, 5, 14, 15), "#2f8d20")
    elif kind == "dead_tree":
        textured_rect(draw, (9, 14, 16, 47), "#706b5d", ["#99937f", "#473f35"], 4, 8)
        px(draw, (12, 14, 14, 47), "#9b927a")
        px(draw, (4, 23, 11, 27), "#696252")
        px(draw, (15, 18, 22, 22), "#5a5348")
    elif kind == "mushroom":
        textured_rect(draw, (6, 11, 10, 23), "#eee2c8", ["#fff4db", "#bfae91"], 4, 2)
        textured_rect(draw, (2, 5, 14, 12), "#c73732", ["#ef5d4c", "#8f1f1f"], 3, 1)
        px(draw, (5, 6, 6, 7), "#f2d6c8")
        px(draw, (10, 8, 11, 9), "#f2d6c8")
    save_scaled(img, path)


def building(path, size, kind):
    w, h = size
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    if kind == "workbench":
        iso_block(draw, 7, 13, 34, 32, "#c98b35", "#8a5629", "#633919", "wood")
        for x in [13, 24, 33]:
            px(draw, (x, 16, x + 2, 20), "#4e3018")
    elif kind == "storage_chest":
        iso_block(draw, 7, 16, 34, 28, "#be7a35", "#8a4e24", "#5d3319", "wood")
        px(draw, (9, 29, 39, 32), "#4d2b15")
        px(draw, (22, 27, 26, 35), "#d9c46b")
    elif kind == "cooking_pot":
        iso_block(draw, 8, 13, 32, 32, "#9b9f9d", "#666b6b", "#45494b", "stone")
        px(draw, (13, 29, 35, 41), "#303235")
        textured_rect(draw, (18, 31, 30, 40), "#f08a1a", ["#ffd35a", "#b64217"], 3, 5)
    elif kind == "farm_plot":
        textured_rect(draw, (5, 15, 43, 43), "#5a331f", ["#8b5a2b", "#2e1d14"], 4, 9)
        px(draw, (5, 15, 43, 23), "#7a4a2b")
        for y in [22, 28, 34, 40]:
            px(draw, (8, y, 40, y + 1), "#24160e")
    elif kind == "trading_post":
        iso_block(draw, 10, 22, 44, 38, "#b97832", "#845021", "#5b3518", "wood")
        textured_rect(draw, (7, 14, 57, 25), "#c1843a", ["#e5ad52", "#724419"], 4, 5)
        px(draw, (12, 8, 52, 16), "#70401f")
        for x, color in [(18, "#d84a3a"), (26, "#f2c14e"), (34, "#3a82d8"), (42, "#55b95d")]:
            px(draw, (x, 30, x + 5, 39), color)
        px(draw, (14, 44, 50, 50), "#5e351d")
    save_scaled(img, path)


def item_icons(path):
    img = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    items = [
        ("wood", 0, 0), ("stone", 16, 0), ("carrot", 32, 0), ("wheat", 48, 0),
        ("egg", 0, 16), ("cooked_carrot", 16, 16), ("rare_seed", 32, 16), ("blueprint", 48, 16),
    ]
    for kind, ox, oy in items:
        if kind == "wood":
            textured_rect(draw, (ox + 3, oy + 3, ox + 12, oy + 12), "#8b5a2b", ["#c0833d", "#4d2d17"], 3, ox)
            px(draw, (ox + 5, oy + 5, ox + 10, oy + 10), "#b8793a")
        elif kind == "stone":
            textured_rect(draw, (ox + 3, oy + 5, ox + 13, oy + 12), "#80848a", ["#b8bbbb", "#4c5053"], 3, ox)
            px(draw, (ox + 5, oy + 3, ox + 12, oy + 8), "#a0a3a8")
            px(draw, (ox + 8, oy + 8, ox + 11, oy + 9), "#3f4246")
        elif kind == "carrot":
            textured_rect(draw, (ox + 6, oy + 5, ox + 11, oy + 13), "#e87919", ["#ffad2c", "#a74212"], 3, ox)
            px(draw, (ox + 5, oy + 3, ox + 7, oy + 6), "#3eaa43")
            px(draw, (ox + 9, oy + 2, ox + 11, oy + 5), "#5ec45d")
        elif kind == "wheat":
            for x in [5, 8, 11]:
                px(draw, (ox + x, oy + 4, ox + x + 1, oy + 13), "#d8a52a")
                px(draw, (ox + x - 1, oy + 4, ox + x + 2, oy + 6), "#f0c44d")
        elif kind == "egg":
            px(draw, (ox + 5, oy + 3, ox + 11, oy + 12), "#f1ead8")
            px(draw, (ox + 6, oy + 2, ox + 10, oy + 13), "#fff7e8")
        elif kind == "cooked_carrot":
            px(draw, (ox + 3, oy + 10, ox + 13, oy + 12), "#b8a078")
            px(draw, (ox + 6, oy + 5, ox + 11, oy + 10), "#c95e18")
        elif kind == "rare_seed":
            textured_rect(draw, (ox + 6, oy + 5, ox + 10, oy + 11), "#19a7ff", ["#a8edff", "#1163bf"], 3, ox)
            px(draw, (ox + 5, oy + 7, ox + 11, oy + 9), "#63d8ff")
            px(draw, (ox + 12, oy + 3, ox + 13, oy + 4), "#d8f8ff")
        elif kind == "blueprint":
            px(draw, (ox + 3, oy + 4, ox + 13, oy + 12), "#ead9b0")
            px(draw, (ox + 5, oy + 6, ox + 11, oy + 7), "#9b6b48")
            px(draw, (ox + 5, oy + 9, ox + 10, oy + 10), "#9b6b48")
    save_scaled(img, path)


def ui_sheet(path):
    img = Image.new("RGBA", (512, 832), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    y = 0
    px(draw, (0, y, 127, y + 127), "#30343a")
    px(draw, (0, y, 127, y + 31), "#555a62")
    px(draw, (0, y, 31, y + 127), "#555a62")
    px(draw, (96, y, 127, y + 127), "#1f2227")
    px(draw, (0, y + 96, 127, y + 127), "#1f2227")
    for offset in range(16, 112, 24):
        px(draw, (offset, y + 36, offset + 7, y + 43), "#3b4048")
        px(draw, (offset + 20, y + 72, offset + 27, y + 79), "#262a30")
    y += 136
    for i, color in enumerate(["#555a62", "#6a7078", "#383c42"]):
        top = y + i * 64
        px(draw, (0, top, 191, top + 63), color)
        px(draw, (0, top, 191, top + 7), "#858b94" if i == 1 else "#6a7078")
        px(draw, (0, top + 56, 191, top + 63), "#22262a")
        if i == 2:
            px(draw, (0, top, 7, top + 63), "#22262a")
    y += 200
    px(draw, (0, y, 79, y + 79), "#2b2e33")
    px(draw, (4, y + 4, 75, y + 75), "#555a62")
    px(draw, (12, y + 12, 67, y + 67), "#22252a")
    y += 88
    px(draw, (0, y, 383, y + 47), "#24272c")
    px(draw, (0, y, 383, y + 3), "#676d76")
    px(draw, (0, y + 44, 383, y + 47), "#14161a")
    y += 48
    px(draw, (0, y, 383, y + 47), "#b91e2a")
    px(draw, (0, y, 383, y + 7), "#ef4b55")
    px(draw, (0, y + 40, 383, y + 47), "#7f1520")
    y += 56
    px(draw, (0, y + 4, 63, y + 11), "#22252a")
    px(draw, (0, y, 63, y + 3), "#6a7078")
    y += 24
    px(draw, (0, y, 127, y + 63), "#282b31")
    px(draw, (0, y, 127, y + 11), "#4d525a")
    for offset in range(12, 120, 24):
        px(draw, (offset, y + 24, offset + 7, y + 31), "#343941")
    y += 72
    px(draw, (20, y + 20, 43, y + 43), "#ffd34d")
    for x0, y0 in [(30, 4), (30, 54), (4, 30), (54, 30), (12, 12), (48, 48), (48, 12), (12, 48)]:
        px(draw, (x0, y + y0, x0 + 7, y + y0 + 7), "#ffd34d")
    px(draw, (88, y + 12, 115, y + 51), "#f0f1dd")
    px(draw, (100, y + 12, 119, y + 51), (0, 0, 0, 0))
    y += 72
    px(draw, (0, y, 207, y + 207), "#30343a")
    px(draw, (0, y, 207, y + 15), "#858b94")
    px(draw, (0, y, 15, y + 207), "#858b94")
    px(draw, (16, y + 16, 191, y + 191), "#202328")
    img.save(path)


def main():
    ensure_dirs()
    for name in ["player", "merchant", "slime", "skeleton", "chicken"]:
        character_sheet(f"assets/sprites/characters/{name}.png", name)
    breakable_environment("assets/sprites/environment/tree.png", (32, 48), "tree")
    breakable_environment("assets/sprites/environment/stone.png", (32, 24), "stone")
    static_environment("assets/sprites/environment/grass.png", (16, 16), "grass")
    breakable_environment("assets/sprites/environment/berry_bush.png", (32, 32), "berry_bush")
    static_environment("assets/sprites/environment/dead_tree.png", (24, 48), "dead_tree")
    static_environment("assets/sprites/environment/mushroom.png", (16, 24), "mushroom")
    for name, size in [
        ("workbench", (48, 48)), ("storage_chest", (48, 48)), ("cooking_pot", (48, 48)),
        ("farm_plot", (48, 48)), ("trading_post", (64, 64)),
    ]:
        building(f"assets/sprites/buildings/{name}.png", size, name)
    item_icons("assets/sprites/items/icons.png")
    ui_sheet("assets/sprites/ui/ui_sheet.png")


if __name__ == "__main__":
    main()
