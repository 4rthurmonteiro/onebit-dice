#!/usr/bin/env python3
"""Compose the 1024x500 Play Store feature graphic in the 1-bit aesthetic.

Black ink on white paper: a pixel die (the splash die) on the left and the
"1-BIT DICE" wordmark + tagline on the right, framed like a Mac window.
The result is thresholded to pure black/white (no anti-aliased grays) and
saved as a 24-bit PNG without an alpha channel.
"""
from PIL import Image, ImageDraw, ImageFont

W, H = 1024, 500
INK, PAPER = 0, 255  # 1-bit: foreground / background

FONT = "assets/fonts/PressStart2P-Regular.ttf"

# The splash die (12x12) — a D6 showing the 6-pip face.
DIE = [
    [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1],
    [1, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1],
    [1, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1],
    [1, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
]

img = Image.new("L", (W, H), PAPER)
d = ImageDraw.Draw(img)

# Outer frame (Mac-window vibe): 6px black border inset 16px.
inset, bw = 16, 6
d.rectangle([inset, inset, W - 1 - inset, H - 1 - inset], outline=INK, width=bw)


def draw_matrix(matrix, x0, y0, cell):
    for r, row in enumerate(matrix):
        for c, on in enumerate(row):
            if on:
                x, y = x0 + c * cell, y0 + r * cell
                d.rectangle([x, y, x + cell - 1, y + cell - 1], fill=INK)


def spaced(text, size, tracking):
    """Render text char-by-char with extra tracking; return (img, w, h)."""
    font = ImageFont.truetype(FONT, size)
    widths, h = [], 0
    for ch in text:
        l, t, r, b = font.getbbox(ch)
        widths.append(r)
        h = max(h, b)
    total = sum(widths) + tracking * (len(text) - 1)
    layer = Image.new("L", (total + 4, size + size // 2), PAPER)
    ld = ImageDraw.Draw(layer)
    x = 0
    for ch, w in zip(text, widths):
        ld.text((x, 0), ch, font=font, fill=INK)
        x += w + tracking
    return layer, total, size


# Pixel die on the left.
cell = 22
die_px = 12 * cell  # 264
die_x = 70
die_y = (H - die_px) // 2
draw_matrix(DIE, die_x, die_y, cell)

# Wordmark "1-BIT" / "DICE" stacked to the right of the die.
text_x = die_x + die_px + 74
line1, w1, h1 = spaced("1-BIT", 70, 10)
line2, w2, h2 = spaced("DICE", 70, 10)
y1 = 150
img.paste(line1, (text_x, y1))
img.paste(line2, (text_x, y1 + 96))

# Divider + tagline.
div_y = y1 + 96 + 96
div_w = max(w1, w2)
d.rectangle([text_x, div_y, text_x + div_w, div_y + 6], fill=INK)
tagline, tw, th = spaced("DICE FOR EVERY GAME", 18, 6)
img.paste(tagline, (text_x, div_y + 26))

# Enforce strict 1-bit: threshold away any anti-aliased grays, then RGB no-alpha.
img = img.point(lambda p: 0 if p < 128 else 255)
img.convert("RGB").save("docs/store/android/feature-graphic.png")
print("wrote docs/store/android/feature-graphic.png")
