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


def poly(draw, points, fill):
    draw.polygon(points, fill=fill)


def iso_cube(draw, cx, top_y, w, d, h, top, left, right, edge="#244018", seed=0, detail="grass"):
    hw = w // 2
    hd = d // 2
    top_pts = [(cx, top_y), (cx + hw, top_y + hd), (cx, top_y + d), (cx - hw, top_y + hd)]
    left_pts = [(cx - hw, top_y + hd), (cx, top_y + d), (cx, top_y + d + h), (cx - hw, top_y + hd + h)]
    right_pts = [(cx + hw, top_y + hd), (cx, top_y + d), (cx, top_y + d + h), (cx + hw, top_y + hd + h)]
    poly(draw, left_pts, left)
    poly(draw, right_pts, right)
    poly(draw, top_pts, top)
    draw.line(top_pts + [top_pts[0]], fill=edge, width=1)
    draw.line([left_pts[0], left_pts[3], left_pts[2]], fill=edge, width=1)
    draw.line([right_pts[0], right_pts[3], right_pts[2]], fill=edge, width=1)

    min_x = cx - hw + 1
    max_x = cx + hw - 1
    min_y = top_y + 1
    max_y = top_y + d + h - 1
    if detail == "grass":
        colors = ["#b6ef24", "#77c414", "#31931f", "#d6f64a"]
    elif detail == "leaf":
        colors = ["#59ca2e", "#159323", "#0a6819", "#9be039"]
    elif detail == "stone":
        colors = ["#c8cbca", "#8b9091", "#5f6465", "#e0e0dc"]
    elif detail == "wood":
        colors = ["#b87934", "#6e421f", "#3f2412", "#d29a4a"]
    elif detail == "soil":
        colors = ["#93602e", "#57321d", "#2f1e13", "#b47a3a"]
    elif detail == "sand":
        colors = ["#ffe39a", "#d9b85d", "#b98f3b", "#fff0b8"]
    elif detail == "water":
        colors = ["#35a8ee", "#0879c9", "#0b5fa4", "#79d7ff"]
    else:
        colors = ["#ffffff"]
    for y in range(min_y, max_y, 4):
        for x in range(min_x + ((y + seed) % 4), max_x + 1, 4):
            idx = (x * 7 + y * 3 + seed) % len(colors)
            px(draw, (x, y, x + 1, y + 1), colors[idx])


def iso_column(draw, cx, base_y, w, d, h, palette, seed=0, detail="grass"):
    top_y = base_y - d - h
    iso_cube(
        draw,
        cx,
        top_y,
        w,
        d,
        h,
        palette["top"],
        palette["left"],
        palette["right"],
        palette.get("edge", "#244018"),
        seed,
        detail,
    )


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
    wood = {"top": "#b97831", "left": "#7a451f", "right": "#573116", "edge": "#3b2412"}
    leaf = {"top": "#46b51d", "left": "#158021", "right": "#0b5f18", "edge": "#073f13"}
    leaf_light = {"top": "#8fcf18", "left": "#3f9b19", "right": "#1d7514", "edge": "#345d0d"}
    leaf_dark = {"top": "#218f21", "left": "#116d1b", "right": "#064e14", "edge": "#063a10"}

    iso_column(draw, 16, oy + 47, 10, 6, 27, wood, oy, "wood")
    px(draw, (13, oy + 24, 15, oy + 45), "#c58a3e")
    px(draw, (18, oy + 25, 19, oy + 46), "#4a2a14")

    if damage < 2:
        iso_cube(draw, 10, oy + 17, 18, 10, 10, leaf_dark["top"], leaf_dark["left"], leaf_dark["right"], leaf_dark["edge"], oy, "leaf")
        iso_cube(draw, 22, oy + 17, 18, 10, 10, leaf["top"], leaf["left"], leaf["right"], leaf["edge"], oy + 1, "leaf")
        iso_cube(draw, 16, oy + 10, 20, 11, 11, leaf_light["top"], leaf_light["left"], leaf_light["right"], leaf_light["edge"], oy + 2, "leaf")
        iso_cube(draw, 17, oy + 2, 16, 9, 9, leaf["top"], leaf["left"], leaf["right"], leaf["edge"], oy + 3, "leaf")
        iso_cube(draw, 6, oy + 25, 13, 8, 7, leaf["top"], leaf["left"], leaf["right"], leaf["edge"], oy + 4, "leaf")
        iso_cube(draw, 26, oy + 25, 13, 8, 7, leaf_dark["top"], leaf_dark["left"], leaf_dark["right"], leaf_dark["edge"], oy + 5, "leaf")
    else:
        iso_cube(draw, 13, oy + 20, 15, 9, 7, "#6f8f1d", "#4d6619", "#344d13", "#28390f", oy, "leaf")
        iso_cube(draw, 22, oy + 19, 13, 8, 6, "#5d751b", "#3f5516", "#2c3e12", "#24320f", oy + 1, "leaf")

    if damage:
        px(draw, (13, oy + 30, 16, oy + 34), "#2d1d10")
        px(draw, (18, oy + 37, 20, oy + 41), "#2d1d10")
    if damage == 2:
        px(draw, (3, oy + 1, 9, oy + 8), (0, 0, 0, 0))


def breakable_environment(path, size, kind):
    w, h = size
    img = Image.new("RGBA", (w, h * 3), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    for row in range(3):
        oy = row * h
        if kind == "tree":
            draw_tree_state(draw, oy, row)
        elif kind == "stone":
            stone = {"top": "#aaaead", "left": "#777d7e", "right": "#565b5d", "edge": "#3e4243"}
            stone_dark = {"top": "#858a8b", "left": "#626667", "right": "#464a4b", "edge": "#333637"}
            iso_column(draw, 15, oy + 23, 18, 9, 10, stone, oy, "stone")
            iso_column(draw, 23, oy + 18, 13, 7, 9, stone_dark, oy + 2, "stone")
            iso_column(draw, 9, oy + 20, 10, 6, 7, stone_dark, oy + 4, "stone")
            if row:
                px(draw, (13, oy + 10, 16, oy + 12), "#3d4045")
                px(draw, (20, oy + 13, 24, oy + 15), "#3d4045")
            if row == 2:
                px(draw, (5, oy + 8, 12, oy + 14), (0, 0, 0, 0))
                px(draw, (23, oy + 13, 29, oy + 21), (0, 0, 0, 0))
        elif kind == "berry_bush":
            bush = {"top": "#45b72b", "left": "#1d8727", "right": "#0f681e", "edge": "#0a4a16"}
            iso_column(draw, 16, oy + 31, 24, 12, 12, bush, oy, "leaf")
            iso_column(draw, 16, oy + 22, 17, 9, 7, bush, oy + 3, "leaf")
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
        grass = {"top": "#79c817", "left": "#3f8f1d", "right": "#2a6917", "edge": "#285014"}
        iso_column(draw, 8, 15, 14, 7, 5, grass, 4, "grass")
        px(draw, (3, 4, 5, 13), "#8ed831")
        px(draw, (8, 2, 10, 14), "#6fc926")
        px(draw, (12, 5, 14, 15), "#2f8d20")
    elif kind == "dead_tree":
        wood = {"top": "#8d8060", "left": "#62533e", "right": "#45392d", "edge": "#332a22"}
        iso_column(draw, 13, 47, 8, 5, 30, wood, 8, "wood")
        px(draw, (4, 23, 12, 27), "#665842")
        px(draw, (15, 18, 23, 22), "#544839")
    elif kind == "mushroom":
        stem = {"top": "#fff4db", "left": "#e0d2b6", "right": "#bba98c", "edge": "#8f7f66"}
        cap = {"top": "#d53a32", "left": "#a22727", "right": "#761c1c", "edge": "#531414"}
        iso_column(draw, 8, 23, 6, 4, 9, stem, 2, "sand")
        iso_column(draw, 8, 13, 14, 8, 5, cap, 1, "soil")
        px(draw, (5, 6, 6, 7), "#f2d6c8")
        px(draw, (10, 8, 11, 9), "#f2d6c8")
    save_scaled(img, path)


def building(path, size, kind):
    w, h = size
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    if kind == "workbench":
        wood = {"top": "#c98b35", "left": "#8a5629", "right": "#633919", "edge": "#3c2412"}
        iso_column(draw, 24, 44, 32, 18, 15, wood, 1, "wood")
        px(draw, (9, 27, 39, 29), "#5f3518")
        px(draw, (24, 27, 24, 43), "#d19548")
        for x in [13, 24, 33]:
            px(draw, (x, 16, x + 2, 20), "#4e3018")
    elif kind == "storage_chest":
        chest = {"top": "#be7a35", "left": "#8a4e24", "right": "#5d3319", "edge": "#332010"}
        iso_column(draw, 24, 43, 34, 18, 14, chest, 3, "wood")
        px(draw, (9, 29, 39, 32), "#4d2b15")
        px(draw, (22, 27, 26, 35), "#d9c46b")
    elif kind == "cooking_pot":
        stone = {"top": "#9b9f9d", "left": "#666b6b", "right": "#45494b", "edge": "#303435"}
        iso_column(draw, 24, 45, 32, 16, 17, stone, 5, "stone")
        px(draw, (13, 29, 35, 41), "#303235")
        textured_rect(draw, (18, 31, 30, 40), "#f08a1a", ["#ffd35a", "#b64217"], 3, 5)
    elif kind == "farm_plot":
        soil = {"top": "#754823", "left": "#523018", "right": "#3a2314", "edge": "#24160e"}
        iso_column(draw, 24, 43, 38, 19, 6, soil, 9, "soil")
        for y in [24, 29, 34]:
            px(draw, (10, y, 38, y + 1), "#2b1a10")
    elif kind == "trading_post":
        wood = {"top": "#b97832", "left": "#845021", "right": "#5b3518", "edge": "#35200f"}
        roof = {"top": "#c1843a", "left": "#8f5826", "right": "#653819", "edge": "#3c2412"}
        iso_column(draw, 32, 60, 44, 22, 24, wood, 5, "wood")
        iso_column(draw, 32, 29, 52, 24, 10, roof, 8, "wood")
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


def tile_noise_color(base, variants, x, y, seed):
    idx = (x * 37 + y * 19 + seed * 11) % (len(variants) + 3)
    if idx < len(variants):
        return variants[idx]
    return base


def draw_tile(draw, ox, base, variants, seed):
    for y in range(16):
        for x in range(16):
            color = tile_noise_color(base, variants, x, y, seed)
            px(draw, (ox + x, y, ox + x, y), color)


def draw_ground_tiles(path):
    img = Image.new("RGB", (64, 16), "#000000")
    draw = ImageDraw.Draw(img)

    draw_tile(draw, 0, "#67b51d", ["#83cd22", "#4d981b", "#9bdd2c", "#347b18"], 1)
    for x, y in [(2, 5), (6, 11), (11, 3), (13, 9)]:
        px(draw, (x, y, x, y + 2), "#b8ee37")
        px(draw, (x + 1, y + 1, x + 1, y + 2), "#3b8d18")

    draw_tile(draw, 16, "#d2ad63", ["#f0ce7e", "#b98b42", "#e1bd6d", "#9f7536"], 2)
    for x, y in [(18, 4), (23, 11), (27, 6), (30, 13)]:
        px(draw, (x, y, x + 1, y), "#8a6330")
    px(draw, (20, 8, 25, 8), "#e7c477")
    px(draw, (26, 2, 30, 2), "#ba8840")

    draw_tile(draw, 32, "#5a321c", ["#754421", "#3a2215", "#8a572c", "#2b1a11"], 3)
    for y in [3, 7, 11, 15]:
        px(draw, (32, y, 47, y), "#2b1a10")
    for y in [5, 9, 13]:
        px(draw, (33, y, 46, y), "#7d4b27")

    draw_tile(draw, 48, "#8d9291", ["#b4b8b6", "#686e70", "#cdd0cc", "#54595b"], 4)
    for line in [((50, 4), (54, 4), (54, 6)), ((58, 10), (62, 10)), ((51, 13), (55, 12))]:
        pts = [(x, y) for x, y in line]
        draw.line(pts, fill="#45494a", width=1)

    img.save(path)


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
    draw_ground_tiles("assets/sprites/environment/ground_tiles.png")
    ui_sheet("assets/sprites/ui/ui_sheet.png")


if __name__ == "__main__":
    main()
