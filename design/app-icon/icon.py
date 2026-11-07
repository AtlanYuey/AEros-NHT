"""Builds the AEros-NHT app icon and writes it into both apps.

The icon: a big N lit pink from its top right by a bat wing (nhentai's
#ED2553) set a little apart from it, and a white HT on the N's baseline,
on a dark gradient. Flat.

    python3 design/app-icon/icon.py

Needs Playwright (node) for the lettering (Inter Black, FONT below) and
Pillow + numpy. wing.png is the right wing of the previous icon.
Writes:
- apple/.../AppIcon.appiconset: AppIcon.png (any), -Dark.png, -Tinted.png
- apple/.../AboutIcon.imageset/AboutIcon.png
- android-native/.../mipmap-*/ic_launcher_{background,foreground,monochrome}.png
- android-native/.../drawable-nodpi/about_icon.png
"""
import json
import os
import subprocess
import tempfile

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
FONT = "/usr/share/fonts/opentype/inter/Inter-Black.otf"
PINK = (237, 37, 83)  # nhentai #ED2553

# Layout from the mock-up (1254 px wide), scaled to the icon.
MOCK = 1254
N_BOX = (215, 415, 655, 875)          # left, top, right, bottom
WING_BOX = (676, 300, 1112, 612)
HT_LEFT, HT_BOTTOM, HT_CAP = 708, 875, 175
GLOW = {"origin": (700, 430), "radius": 360, "strength": 0.7, "power": 1.4}
OFFSET = (26, 8)                      # optical centering, in 1024 px

BACKGROUND = ("radial-gradient(120% 90% at 22% 8%, #4A4A52 0%, rgba(74,74,82,0) 55%), "
              "linear-gradient(#2E2E33, #141416)")


def render_parts(tmp):
    pages = {
        "n": f'<div style="font-size:640px;color:#fff">N</div>',
        "ht": f'<div style="font-size:330px;color:#fff">HT</div>',
        "bg": "",
    }
    for name, body in pages.items():
        bg = f"background:{BACKGROUND};" if name == "bg" else "background:transparent;"
        html = (f"<html><head><style>@font-face{{font-family:Icon;src:url(file://{FONT});font-weight:900}}"
                f"html,body{{margin:0;width:1024px;height:1024px;{bg}}}"
                "div{position:absolute;left:60px;top:60px;font-family:Icon;font-weight:900;line-height:1;letter-spacing:-4px}"
                f"</style></head><body>{body}</body></html>")
        open(os.path.join(tmp, f"{name}.html"), "w").write(html)
    subprocess.run(["node", os.path.join(HERE, "render_html.js"), tmp, "n", "ht", "bg"], check=True)
    crop = lambda im: im.crop(im.getbbox())
    return (crop(Image.open(os.path.join(tmp, "n.png")).convert("RGBA")),
            crop(Image.open(os.path.join(tmp, "ht.png")).convert("RGBA")),
            Image.open(os.path.join(tmp, "bg.png")).convert("RGBA"))


def solid(alpha, color):
    out = Image.new("RGBA", alpha.size, color + (255,))
    out.putalpha(alpha)
    return out


def lit(alpha, origin, radius, strength, power, base=(255, 255, 255), light=PINK):
    """[alpha] filled white, turning toward the wing's pink near [origin]."""
    h, w = alpha.size[1], alpha.size[0]
    ys, xs = np.mgrid[0:h, 0:w]
    a = np.clip(1 - np.hypot(xs - origin[0], ys - origin[1]) / radius, 0, 1) ** power * strength
    rgba = np.zeros((h, w, 4), dtype=np.uint8)
    for i in range(3):
        rgba[..., i] = (base[i] * (1 - a) + light[i] * a).astype(np.uint8)
    rgba[..., 3] = np.array(alpha)
    return Image.fromarray(rgba, "RGBA")


def emblem(n, ht, scale=4, mono=None, tinted=False):
    """The N, the wing and HT, centered on a transparent (1024 * scale) square."""
    S = 1024 * scale
    k = 1024 / MOCK * scale
    n_alpha = n.resize((int((N_BOX[2] - N_BOX[0]) * k), int((N_BOX[3] - N_BOX[1]) * k)), Image.LANCZOS).split()[3]
    ht_size = (int(ht.width * HT_CAP * k / ht.height), int(HT_CAP * k))
    ht_alpha = ht.resize(ht_size, Image.LANCZOS).split()[3]
    wing_alpha = Image.open(os.path.join(HERE, "wing.png")).convert("L").resize(
        (int((WING_BOX[2] - WING_BOX[0]) * k), int((WING_BOX[3] - WING_BOX[1]) * k)), Image.LANCZOS)

    nx, ny = int(N_BOX[0] * k), int(N_BOX[1] * k)
    if mono:
        n_img, wing_img, ht_img = (solid(a, mono) for a in (n_alpha, wing_alpha, ht_alpha))
    elif tinted:
        n_img, wing_img, ht_img = solid(n_alpha, (255, 255, 255)), solid(wing_alpha, (190, 190, 190)), solid(ht_alpha, (255, 255, 255))
    else:
        ox, oy = GLOW["origin"]
        n_img = lit(n_alpha, (ox * k - nx, oy * k - ny), GLOW["radius"] * k, GLOW["strength"], GLOW["power"])
        wing_img, ht_img = solid(wing_alpha, PINK), solid(ht_alpha, (255, 255, 255))

    canvas = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    canvas.alpha_composite(n_img, (nx, ny))
    canvas.alpha_composite(wing_img, (int(WING_BOX[0] * k), int(WING_BOX[1] * k)))
    canvas.alpha_composite(ht_img, (int(HT_LEFT * k), int(HT_BOTTOM * k) - ht_alpha.height))
    return canvas.crop(canvas.getbbox())


def place(group, size, width, offset=(0, 0)):
    """[group] [width] px wide, centered (plus [offset]) on a transparent [size] square."""
    g = group.resize((width, int(group.height * width / group.width)), Image.LANCZOS)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.alpha_composite(g, ((size - g.width) // 2 + offset[0], (size - g.height) // 2 + offset[1]))
    return out


def main():
    with tempfile.TemporaryDirectory() as tmp:
        n, ht, bg = render_parts(tmp)
    group = emblem(n, ht)
    width = int(group.width / 4)          # the emblem's width on the 1024 icon

    icon = bg.copy()
    icon.alpha_composite(place(group, 1024, width, OFFSET))
    tinted = Image.new("RGBA", (1024, 1024), (0, 0, 0, 255))
    tinted.alpha_composite(place(emblem(n, ht, tinted=True), 1024, width, OFFSET))

    ios = os.path.join(ROOT, "apple/ErosN/Resources/Assets.xcassets")
    icon.convert("RGB").save(os.path.join(ios, "AppIcon.appiconset/AppIcon.png"), optimize=True)
    icon.convert("RGB").save(os.path.join(ios, "AppIcon.appiconset/AppIcon-Dark.png"), optimize=True)
    tinted.convert("L").convert("RGB").save(os.path.join(ios, "AppIcon.appiconset/AppIcon-Tinted.png"), optimize=True)
    json.dump({
        "images": [
            {"filename": "AppIcon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"},
            {"appearances": [{"appearance": "luminosity", "value": "dark"}], "filename": "AppIcon-Dark.png",
             "idiom": "universal", "platform": "ios", "size": "1024x1024"},
            {"appearances": [{"appearance": "luminosity", "value": "tinted"}], "filename": "AppIcon-Tinted.png",
             "idiom": "universal", "platform": "ios", "size": "1024x1024"},
        ],
        "info": {"author": "xcode", "version": 1},
    }, open(os.path.join(ios, "AppIcon.appiconset/Contents.json"), "w"), indent=2)
    about = icon.convert("RGB").resize((264, 264), Image.LANCZOS)
    about.save(os.path.join(ios, "AboutIcon.imageset/AboutIcon.png"), optimize=True)

    # Android adaptive icon: 108 dp layers; the emblem fits the 66 dp safe circle.
    res = os.path.join(ROOT, "android-native/app/src/main/res")
    fg_width = int(1024 * 60 / 108 / ((1 + (group.height / group.width) ** 2) ** 0.5))
    fg_offset = tuple(int(v * fg_width / width) for v in OFFSET)
    layers = {
        "ic_launcher_background": bg,
        "ic_launcher_foreground": place(group, 1024, fg_width, fg_offset),
        "ic_launcher_monochrome": place(emblem(n, ht, mono=(255, 255, 255)), 1024, fg_width, fg_offset),
    }
    for density, px in {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}.items():
        for name, image in layers.items():
            out = image.resize((px, px), Image.LANCZOS)
            if name == "ic_launcher_background":
                out = out.convert("RGB")
            out.save(os.path.join(res, f"mipmap-{density}/{name}.png"), optimize=True)
    about.save(os.path.join(res, "drawable-nodpi/about_icon.png"), optimize=True)
    print("icon written")


if __name__ == "__main__":
    main()
