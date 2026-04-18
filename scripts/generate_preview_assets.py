#!/usr/bin/env python3
"""
Generate polished preview assets for the CAD portfolio without relying on
OpenSCAD/CadQuery runtime rendering. These images are intended as portfolio
cover shots and README visuals.
"""

from __future__ import annotations

from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "assets" / "previews"

BG = "#f5f0e6"
INK = "#17202d"
MUTED = "#5d6774"
ACCENT = "#f97316"
COOL = "#2563eb"
PANEL = "#ffffff"
LINE = "#d5cec0"


def load_font(path: str, size: int):
    try:
        return ImageFont.truetype(path, size=size)
    except OSError:
        return ImageFont.load_default()


TITLE_FONT = load_font("/System/Library/Fonts/NewYork.ttf", 88)
SUB_FONT = load_font("/System/Library/Fonts/Avenir.ttc", 34)
BODY_FONT = load_font("/System/Library/Fonts/Avenir.ttc", 27)
LABEL_FONT = load_font("/System/Library/Fonts/SFNSMono.ttf", 24)


def rounded(draw: ImageDraw.ImageDraw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def base_canvas(accent_color: str) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    img = Image.new("RGBA", (1600, 1000), BG)
    draw = ImageDraw.Draw(img)

    for y in range(1000):
        t = y / 999
        color = tuple(
            round((1 - t) * a + t * b)
            for a, b in zip((247, 241, 231), (241, 236, 226))
        )
        draw.line((0, y, 1600, y), fill=color)

    for x in range(0, 1600, 44):
        draw.line((x, 0, x, 1000), fill="#ece4d7", width=1)
    for y in range(0, 1000, 44):
        draw.line((0, y, 1600, y), fill="#ece4d7", width=1)

    accent = Image.new("RGBA", (1600, 1000), (0, 0, 0, 0))
    accent_draw = ImageDraw.Draw(accent)
    accent_draw.ellipse((-140, -220, 540, 460), fill=_hex_rgba(accent_color, 46))
    accent_draw.ellipse((1040, -120, 1560, 360), fill=_hex_rgba(COOL, 34))
    accent = accent.filter(ImageFilter.GaussianBlur(46))
    img.alpha_composite(accent)

    draw = ImageDraw.Draw(img)
    rounded(draw, (72, 64, 1528, 936), 34, fill=(255, 252, 245, 214), outline=LINE, width=2)
    return img, draw


def _hex_rgba(hex_color: str, alpha: int):
    hex_color = hex_color.lstrip("#")
    return tuple(int(hex_color[i:i + 2], 16) for i in (0, 2, 4)) + (alpha,)


def add_header(draw: ImageDraw.ImageDraw, eyebrow: str, title: str, subtitle: str):
    draw.text((122, 112), eyebrow.upper(), font=LABEL_FONT, fill=ACCENT)
    draw.text((118, 152), title, font=TITLE_FONT, fill=INK)
    draw.text((122, 252), subtitle, font=SUB_FONT, fill=MUTED)


def chip(draw: ImageDraw.ImageDraw, xy, text: str, fill="#fff7ec", outline="#efc79b", text_fill=INK):
    x, y = xy
    bbox = draw.textbbox((0, 0), text, font=BODY_FONT)
    w = bbox[2] - bbox[0] + 34
    h = 54
    rounded(draw, (x, y, x + w, y + h), 27, fill=fill, outline=outline, width=2)
    draw.text((x + 17, y + 11), text, font=BODY_FONT, fill=text_fill)
    return w


def draw_gear_scene(draw: ImageDraw.ImageDraw):
    def gear_points(cx, cy, teeth, r_outer, r_inner):
        pts = []
        steps = teeth * 2
        for i in range(steps):
            angle = (i / steps) * 6.28318530718
            r = r_outer if i % 2 == 0 else r_inner
            pts.append((cx + r * __import__("math").cos(angle), cy + r * __import__("math").sin(angle)))
        return pts

    draw.polygon(gear_points(470, 620, 24, 150, 128), fill="#f7dcc6", outline=INK)
    draw.polygon(gear_points(760, 620, 36, 112, 94), fill="#dbe8ff", outline=COOL)
    draw.ellipse((420, 570, 520, 670), fill=BG, outline=INK, width=4)
    draw.ellipse((724, 584, 796, 656), fill=BG, outline=COOL, width=4)
    draw.line((470, 620, 760, 620), fill=ACCENT, width=4)
    draw.line((470, 454, 470, 786), fill="#73808f", width=2)
    draw.line((760, 494, 760, 746), fill="#73808f", width=2)
    draw.text((533, 586), "Centre distance 60 mm", font=BODY_FONT, fill=ACCENT)
    draw.text((380, 796), "24T / m2 / 20 deg", font=BODY_FONT, fill=INK)
    draw.text((664, 758), "36T / m2 / ratio 1.50", font=BODY_FONT, fill=COOL)


def draw_enclosure_scene(draw: ImageDraw.ImageDraw):
    lid = [(980, 416), (1262, 364), (1408, 444), (1126, 496)]
    base_top = [(924, 548), (1206, 496), (1352, 576), (1070, 628)]
    base_front = [(924, 548), (924, 714), (1070, 794), (1070, 628)]
    base_side = [(1070, 628), (1070, 794), (1352, 742), (1352, 576)]

    draw.polygon(lid, fill="#e9eefb", outline=COOL)
    draw.polygon(base_top, fill="#f7dcc6", outline=INK)
    draw.polygon(base_front, fill="#edc9aa", outline=INK)
    draw.polygon(base_side, fill="#e2b791", outline=INK)

    for px, py in ((1015, 568), (1170, 540), (1108, 665), (1265, 638)):
        draw.ellipse((px - 10, py - 10, px + 10, py + 10), fill=ACCENT, outline=INK)

    draw.rounded_rectangle((1048, 517, 1118, 547), radius=8, outline=COOL, width=3)
    draw.ellipse((1218, 520, 1244, 546), outline=COOL, width=3)
    draw.rounded_rectangle((919, 604, 931, 648), radius=6, outline=COOL, width=3)

    draw.text((932, 818), "PCB hole pattern", font=BODY_FONT, fill=INK)
    draw.text((1160, 338), "screw lid + gasket groove", font=BODY_FONT, fill=COOL)
    draw.text((1104, 706), "USB-C / round / slot cutouts", font=BODY_FONT, fill=ACCENT)


def draw_sheet_scene(draw: ImageDraw.ImageDraw):
    rounded(draw, (910, 360, 1440, 790), 18, fill="#fffdf8", outline=INK, width=2)
    draw.rectangle((944, 394, 1280, 612), outline=INK, width=3)
    draw.rectangle((1296, 628, 1414, 760), outline="#9aa5b2", width=2)

    draw.ellipse((986, 454, 1046, 514), outline=COOL, width=3)
    draw.ellipse((1168, 454, 1228, 514), outline=COOL, width=3)
    draw.ellipse((986, 526, 1046, 586), outline=COOL, width=3)
    draw.ellipse((1168, 526, 1228, 586), outline=COOL, width=3)
    draw.line((1016, 410, 1016, 590), fill="#7a8796", width=2)
    draw.line((1198, 410, 1198, 590), fill="#7a8796", width=2)
    draw.line((956, 484, 1258, 484), fill="#7a8796", width=2)
    draw.line((956, 556, 1258, 556), fill="#7a8796", width=2)

    draw.text((950, 638), "PART: STRUCTURAL BRACKET", font=BODY_FONT, fill=INK)
    draw.text((950, 678), "DWG: BRK-100-060", font=BODY_FONT, fill=MUTED)
    draw.text((950, 718), "TOP / FRONT / RIGHT VIEWS", font=BODY_FONT, fill=MUTED)
    draw.text((1000, 325), "Manufacturing handoff sheet", font=SUB_FONT, fill=ACCENT)


def draw_bracket_scene(draw: ImageDraw.ImageDraw):
    bracket = [(972, 700), (1248, 700), (1248, 540), (1288, 540), (1288, 700), (1328, 700), (1328, 500), (1288, 500), (1288, 460), (972, 460)]
    draw.polygon(bracket, fill="#d9e5fb", outline=INK)
    draw.polygon([(1004, 700), (1146, 560), (1178, 560), (1036, 700)], fill="#f7dcc6", outline=ACCENT)
    draw.polygon([(1166, 700), (1288, 578), (1308, 578), (1186, 700)], fill="#f7dcc6", outline=ACCENT)

    draw.rounded_rectangle((1010, 650, 1080, 682), radius=14, outline=COOL, width=3)
    draw.rounded_rectangle((1184, 650, 1254, 682), radius=14, outline=COOL, width=3)

    for cx, cy in ((1088, 552), (1222, 552), (1088, 620), (1222, 620)):
        draw.ellipse((cx - 11, cy - 11, cx + 11, cy + 11), outline=ACCENT, width=3)

    draw.text((954, 388), "Structural bracket family", font=SUB_FONT, fill=ACCENT)
    draw.text((970, 734), "slot base holes", font=BODY_FONT, fill=COOL)
    draw.text((1128, 520), "R4 bend", font=BODY_FONT, fill=INK)
    draw.text((1144, 768), "250 N tip-load screen", font=BODY_FONT, fill=MUTED)


def save_cover(name: str, eyebrow: str, title: str, subtitle: str, chips: Iterable[str], scene_fn):
    img, draw = base_canvas(ACCENT)
    add_header(draw, eyebrow, title, subtitle)

    x = 122
    for item in chips:
        w = chip(draw, (x, 326), item)
        x += w + 14

    rounded(draw, (92, 392, 1508, 888), 28, fill="#fffaf1", outline=LINE, width=2)
    scene_fn(draw)
    path = OUT_DIR / name
    img.save(path)
    return path


def generate_overview(paths: list[Path]):
    board = Image.new("RGBA", (1800, 1360), BG)
    draw = ImageDraw.Draw(board)
    draw.text((90, 70), "CAD Portfolio Preview Set", font=TITLE_FONT, fill=INK)
    draw.text((94, 166), "Ready-to-upload cover assets generated from project metadata and portfolio presets.", font=SUB_FONT, fill=MUTED)

    card_w, card_h = 760, 430
    positions = [(90, 270), (950, 270), (90, 760), (950, 760)]

    for path, (x, y) in zip(paths, positions):
        img = Image.open(path).convert("RGBA").resize((card_w, card_h))
        rounded(draw, (x - 10, y - 10, x + card_w + 10, y + card_h + 10), 22, fill="#fffaf2", outline=LINE, width=2)
        board.alpha_composite(img, (x, y))

    board.save(OUT_DIR / "portfolio-overview.png")


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    paths = [
        save_cover(
            "transmission-generator-cover.png",
            "OpenSCAD / Project 01",
            "Parametric Transmission Generator",
            "Matched gear-pair concept with ratio, centre-distance, and manufacturability cues.",
            ["24T / 36T", "ratio 1.50", "module 2", "mesh preview"],
            draw_gear_scene,
        ),
        save_cover(
            "pcb-enclosure-cover.png",
            "OpenSCAD / Project 02",
            "PCB-Driven Enclosure Generator",
            "Packaging-focused enclosure concept with board anchors, cutouts, and screw-lid logic.",
            ["PCB anchors", "screw closure", "USB-C cutout", "gasket groove"],
            draw_enclosure_scene,
        ),
        save_cover(
            "bracket-handoff-cover.png",
            "DXF / Project 03",
            "Bracket Manufacturing Handoff",
            "Orthographic sheet aligned to the structural bracket family and title-blocked for review.",
            ["top/front/right", "R2000 DXF", "callouts", "title block"],
            draw_sheet_scene,
        ),
        save_cover(
            "structural-bracket-cover.png",
            "CadQuery / Project 04",
            "Structural Bracket Family",
            "Reusable bracket family with slot/round fixing, real bend geometry, and load screening.",
            ["slot holes", "inner R4", "250 N load", "STEP / STL / DXF"],
            draw_bracket_scene,
        ),
    ]

    generate_overview(paths)
    print(f"Generated {len(paths) + 1} preview assets in {OUT_DIR}")


if __name__ == "__main__":
    main()
