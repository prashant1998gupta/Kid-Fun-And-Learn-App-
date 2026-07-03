"""Generates KidVerse's branded Android launcher icon + splash mark with Pillow.

Design: a rounded violet->pink gradient tile with a gold star and a sparkle —
friendly and readable at small sizes. Produces:
  - legacy square icons  -> mipmap-*/ic_launcher.png
  - adaptive foreground  -> mipmap-*/ic_launcher_foreground.png (star on transparent)
  - splash mark          -> drawable*/splash_logo.png

Run:  python tool/make_icons.py
"""
import math
import os
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "android", "app", "src", "main", "res")

VIOLET = (108, 92, 231)
PINK = (253, 121, 168)
GOLD = (255, 192, 72)
WHITE = (255, 255, 255)

# Legacy icon densities (px) and adaptive foreground densities (108dp canvas).
LEGACY = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
FOREGROUND = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}


def star_points(cx, cy, outer, inner, n=5, rot=-math.pi / 2):
    pts = []
    for i in range(2 * n):
        r = outer if i % 2 == 0 else inner
        a = rot + i * math.pi / n
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    return pts


def gradient(size, c1, c2):
    base = Image.new("RGB", (size, size), c1)
    top = Image.new("RGB", (size, size), c2)
    mask = Image.new("L", (size, size))
    px = mask.load()
    for y in range(size):
        for x in range(size):
            px[x, y] = int(255 * ((x + y) / (2 * size)))
    base.paste(top, (0, 0), mask)
    return base.convert("RGBA")


def draw_star(draw, cx, cy, outer, fill, outline=WHITE, ow=None):
    inner = outer * 0.42
    pts = star_points(cx, cy, outer, inner)
    draw.polygon(pts, fill=fill, outline=outline, width=ow or max(2, int(outer * 0.06)))


def legacy_icon(size):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    grad = gradient(size, VIOLET, PINK)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, size - 1, size - 1], radius=int(size * 0.23), fill=255
    )
    img.paste(grad, (0, 0), mask)
    d = ImageDraw.Draw(img)
    draw_star(d, size / 2, size * 0.52, size * 0.30, GOLD)
    # little sparkle
    draw_star(d, size * 0.74, size * 0.26, size * 0.08, WHITE, outline=None)
    return img


def foreground_icon(size):
    # Adaptive foreground: content lives in the centered ~66% safe zone.
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    draw_star(d, size / 2, size / 2, size * 0.22, GOLD)
    draw_star(d, size * 0.66, size * 0.36, size * 0.06, WHITE, outline=None)
    return img


def splash_mark(size=384):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    draw_star(d, size / 2, size / 2, size * 0.34, GOLD)
    draw_star(d, size * 0.72, size * 0.3, size * 0.1, WHITE, outline=None)
    return img


def main():
    for dens, px in LEGACY.items():
        d = os.path.join(RES, f"mipmap-{dens}")
        os.makedirs(d, exist_ok=True)
        legacy_icon(px).save(os.path.join(d, "ic_launcher.png"))
        foreground_icon(FOREGROUND[dens]).save(
            os.path.join(d, "ic_launcher_foreground.png")
        )
    # Splash mark (single drawable, density-independent enough for a logo).
    for sub in ("drawable", "drawable-v21"):
        d = os.path.join(RES, sub)
        os.makedirs(d, exist_ok=True)
        splash_mark().save(os.path.join(d, "splash_logo.png"))
    print("icons written")


if __name__ == "__main__":
    main()
