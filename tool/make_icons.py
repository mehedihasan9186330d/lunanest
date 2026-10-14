#!/usr/bin/env python3
"""Generates LunaNest launcher icons and notification artwork (needs Pillow + numpy).

Output (committed, so CI does not need Pillow):
  tool/branding/android/res/...    adaptive icon layers, legacy icons, monochrome, notification icon
  tool/branding/ios/ios_<px>.png   iOS app icon sizes
  assets/branding/media_art.png    artwork for the media notification / lock screen
tool/patch_platforms.py copies these into the generated android/ and ios/ projects.
"""
import math
import os

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SS = 2  # supersampling factor over the 1024 design grid
N = 1024 * SS

NAVY = (11, 16, 48)
VIOLET = (42, 27, 94)
GLOW_VIOLET = (106, 63, 208)
MOON_LIGHT = (244, 240, 255)
MOON_DARK = (184, 169, 255)


def lin_grad(c1, c2, diagonal=False):
    y, x = np.mgrid[0:N, 0:N].astype(np.float32) / (N - 1)
    t = (x + y) / 2 if diagonal else y
    arr = np.zeros((N, N, 3), np.float32)
    for i in range(3):
        arr[..., i] = c1[i] + (c2[i] - c1[i]) * t
    return arr


def background():
    arr = lin_grad(NAVY, VIOLET)
    y, x = np.mgrid[0:N, 0:N].astype(np.float32) / (N - 1)
    d = np.sqrt((x - 0.5) ** 2 + (y - 0.40) ** 2)
    a = np.clip(1 - d / 0.65, 0, 1) ** 2 * 0.45
    for i in range(3):
        arr[..., i] = arr[..., i] * (1 - a) + GLOW_VIOLET[i] * a
    return Image.fromarray(arr.astype(np.uint8), "RGB")


def tf(scale):
    def f(x, y):
        return ((512 + (x - 512) * scale) * SS, (512 + (y - 512) * scale) * SS)
    return f


def moon_mask(scale=1.0):
    f = tf(scale)
    m = Image.new("L", (N, N), 0)
    d = ImageDraw.Draw(m)
    cx, cy, r = 470, 535, 192
    x0, y0 = f(cx - r, cy - r)
    x1, y1 = f(cx + r, cy + r)
    d.ellipse([x0, y0, x1, y1], fill=255)
    bx, by, br = 575, 478, 166
    x0, y0 = f(bx - br * 0.0 - br, by - br)
    x1, y1 = f(bx + br, by + br)
    d.ellipse([x0, y0, x1, y1], fill=0)
    return m


def star_mask(scale=1.0, stars=((612, 404, 58), (700, 530, 34), (548, 322, 26))):
    f = tf(scale)
    m = Image.new("L", (N, N), 0)
    d = ImageDraw.Draw(m)
    for cx, cy, r in stars:
        pts = []
        for k in range(8):
            ang = math.radians(90 + 45 * k)
            rr = r if k % 2 == 0 else r * 0.30
            pts.append(f(cx + rr * math.cos(ang), cy - rr * math.sin(ang)))
        d.polygon(pts, fill=255)
    return m


def moon_fill():
    return Image.fromarray(lin_grad(MOON_LIGHT, MOON_DARK, diagonal=True).astype(np.uint8), "RGB")


def foreground(scale=1.0):
    """RGBA: glowing crescent + sparkles on transparent."""
    mm, sm = moon_mask(scale), star_mask(scale)
    glow = mm.filter(ImageFilter.GaussianBlur(70 * SS * scale)).point(lambda v: int(v * 0.35))
    out = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    out.paste(Image.new("RGBA", (N, N), MOON_DARK + (255,)), mask=glow)
    out.paste(moon_fill().convert("RGBA"), mask=mm)
    out.paste(Image.new("RGBA", (N, N), (255, 255, 255, 255)), mask=sm)
    return out


def mono(scale=1.0):
    m = ImageChops.lighter(moon_mask(scale), star_mask(scale))
    out = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    out.paste(Image.new("RGBA", (N, N), (0, 0, 0, 255)), mask=m)
    return out


def white_silhouette(stars):
    m = ImageChops.lighter(moon_mask(1.25), star_mask(1.25, stars))
    out = Image.new("RGBA", (N, N), (255, 255, 255, 0))
    out.paste(Image.new("RGBA", (N, N), (255, 255, 255, 255)), mask=m)
    return out


def rounded(img, radius_frac):
    m = Image.new("L", img.size, 0)
    r = int(img.size[0] * radius_frac)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, img.size[0] - 1, img.size[1] - 1], r, fill=255)
    out = img.convert("RGBA")
    out.putalpha(m)
    return out


def save(img, path, px):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.resize((px, px), Image.LANCZOS).save(path, optimize=True)


def main():
    bg = background().convert("RGBA")
    fg = foreground(1.15)
    mn = mono(1.15)
    res = os.path.join(ROOT, "tool", "branding", "android", "res")

    legacy_full = Image.alpha_composite(bg, foreground(1.3))
    legacy = rounded(legacy_full, 0.22)

    dens = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
    for d, k in dens.items():
        save(legacy, f"{res}/mipmap-{d}/ic_launcher.png", int(48 * k))
        save(fg, f"{res}/mipmap-{d}/ic_launcher_foreground.png", int(108 * k))
        save(bg, f"{res}/mipmap-{d}/ic_launcher_background.png", int(108 * k))
        save(mn, f"{res}/mipmap-{d}/ic_launcher_monochrome.png", int(108 * k))

    notif = white_silhouette(((650, 330, 70),))
    for d, px in {"mdpi": 24, "hdpi": 36, "xhdpi": 48, "xxhdpi": 72, "xxxhdpi": 96}.items():
        save(notif, f"{res}/drawable-{d}/ic_stat_luna.png", px)

    os.makedirs(f"{res}/mipmap-anydpi-v26", exist_ok=True)
    os.makedirs(f"{res}/mipmap-anydpi-v33", exist_ok=True)
    with open(f"{res}/mipmap-anydpi-v26/ic_launcher.xml", "w") as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
                '    <background android:drawable="@mipmap/ic_launcher_background"/>\n'
                '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n</adaptive-icon>\n')
    with open(f"{res}/mipmap-anydpi-v33/ic_launcher.xml", "w") as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
                '    <background android:drawable="@mipmap/ic_launcher_background"/>\n'
                '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
                '    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>\n</adaptive-icon>\n')

    # iOS (square, no alpha) + media artwork
    ios_full = Image.alpha_composite(bg, foreground(1.3)).convert("RGB")
    for px in (20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024):
        save(ios_full, os.path.join(ROOT, "tool", "branding", "ios", f"ios_{px}.png"), px)
    save(ios_full, os.path.join(ROOT, "assets", "branding", "media_art.png"), 512)

    # preview sheet for human inspection (not shipped)
    prev = Image.new("RGBA", (1200, 420), (30, 30, 40, 255))
    circle = Image.new("L", (360, 360), 0)
    ImageDraw.Draw(circle).ellipse([0, 0, 359, 359], fill=255)
    adaptive = Image.alpha_composite(bg, fg).resize((360, 360), Image.LANCZOS)
    prev.paste(adaptive, (20, 30), circle)
    prev.paste(legacy.resize((360, 360), Image.LANCZOS), (410, 30))
    small = Image.alpha_composite(bg, fg).resize((48, 48), Image.LANCZOS)
    sm_c = Image.new("L", (48, 48), 0)
    ImageDraw.Draw(sm_c).ellipse([0, 0, 47, 47], fill=255)
    prev.paste(small, (800, 30), sm_c)
    n = notif.resize((96, 96), Image.LANCZOS)
    prev.paste(Image.new("RGBA", (120, 120), (90, 90, 100, 255)), (800, 120))
    prev.paste(n, (812, 132), n)
    prev.paste(mn.resize((160, 160), Image.LANCZOS), (960, 30), mn.resize((160, 160), Image.LANCZOS))
    prev.save("/tmp/icon_preview.png")
    print("icons generated")


if __name__ == "__main__":
    main()
