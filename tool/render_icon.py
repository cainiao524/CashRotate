"""Renders the app icon to PNG (legacy launcher sizes, the 512 px store
icon and the README logo) from the same geometry as the adaptive-icon
vectors in app/android/app/src/main/res/drawable/ic_launcher_*.xml.

Run from the repository root:  python tool/render_icon.py
"""
import math
import os

from PIL import Image, ImageDraw

SS = 2048  # supersampled canvas for the 72-unit visible area
UNIT = SS / 72.0
OFFSET = 18  # the adaptive icon shows units 18..90 of 108
# The mark sits 4 units left and 3 down of centre so it looks centred (the
# arrow weighs on the top right); the vectors use the same coordinates.
DX, DY = -4, 3

BG_STOPS = [(0.0, (0x1A, 0x1A, 0x1D)), (0.55, (0x2A, 0x2A, 0x2F)), (1.0, (0x1F, 0x1E, 0x23))]
PEARL = (0xF2, 0xF2, 0xF0, 255)
INK = (0x11, 0x11, 0x11, 255)


def p(x, y):
    return ((x + DX - OFFSET) * UNIT, (y + DY - OFFSET) * UNIT)


def background():
    img = Image.new('RGB', (SS, SS))
    px = img.load()
    for y in range(SS):
        for x in range(SS):
            t = (x + y) / (2 * (SS - 1))
            for (a, ca), (b, cb) in zip(BG_STOPS, BG_STOPS[1:]):
                if a <= t <= b:
                    k = (t - a) / (b - a)
                    px[x, y] = tuple(round(ca[i] + (cb[i] - ca[i]) * k) for i in range(3))
                    break
    return img.convert('RGBA')


def arc(draw, cx, cy, r, start, end, width, color):
    """Stroked arc with round caps; angles in degrees, clockwise from 3 o'clock."""
    w = width * UNIT
    x0, y0 = p(cx - r, cy - r)
    x1, y1 = p(cx + r, cy + r)
    pad = w / 2
    draw.arc((x0 - pad, y0 - pad, x1 + pad, y1 + pad), start, end, fill=color, width=round(w))
    for ang in (start, end):
        ex, ey = p(cx + r * math.cos(math.radians(ang)), cy + r * math.sin(math.radians(ang)))
        draw.ellipse((ex - w / 2, ey - w / 2, ex + w / 2, ey + w / 2), fill=color)


def line(draw, pts, width, color):
    w = width * UNIT
    xy = [p(x, y) for x, y in pts]
    draw.line(xy, fill=color, width=round(w), joint='curve')
    for ex, ey in (xy[0], xy[-1]):
        draw.ellipse((ex - w / 2, ey - w / 2, ex + w / 2, ey + w / 2), fill=color)


def mark(img):
    d = ImageDraw.Draw(img)
    x0, y0 = p(35, 35)
    x1, y1 = p(73, 73)
    d.ellipse((x0, y0, x1, y1), fill=PEARL)  # the coin
    # The C: an arc of radius 9.2 open to the right (from -45° round to 45°).
    arc(d, 54, 54, 9.2, 45, 315, 5, INK)
    # The turning arrow: from 12 o'clock to 3 o'clock, radius 27.
    arc(d, 54, 54, 27, 270, 360, 4.5, PEARL)
    line(d, [(76, 49), (81, 54.5), (86, 49)], 4.5, PEARL)
    return img


def main():
    full = mark(background())
    out = 'app/android/app/src/main/res'
    for folder, size in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
        icon = full.resize((size, size), Image.LANCZOS)
        mask = Image.new('L', (size * 4, size * 4), 0)
        ImageDraw.Draw(mask).ellipse((0, 0, size * 4 - 1, size * 4 - 1), fill=255)
        icon.putalpha(mask.resize((size, size), Image.LANCZOS))
        icon.save(os.path.join(out, f'mipmap-{folder}', 'ic_launcher.png'))
    full.resize((512, 512), Image.LANCZOS).convert('RGB').save('docs/icon-512.png')
    logo = full.resize((256, 256), Image.LANCZOS)
    mask = Image.new('L', (1024, 1024), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, 1023, 1023), radius=230, fill=255)
    logo.putalpha(mask.resize((256, 256), Image.LANCZOS))
    logo.save('docs/icon.png')


if __name__ == '__main__':
    main()
