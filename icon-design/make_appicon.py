#!/usr/bin/env python3
"""生成 ClickBoom 的 macOS 应用图标。

极简黑白：近黑底 + 居中的白色指针 + 一道围绕指针扩散的白色圆环。

用法：
    python3 icon-design/make_appicon.py
"""

import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

M = 1024          # 设计坐标空间
SS = 4            # 超采样倍数
S = M * SS        # 渲染尺寸

ICON_W = 824      # macOS 图标内容区
SQ_N = 5.0        # squircle 超椭圆指数
CX = CY = 512.0

TIP = (448.0, 399.0)   # 指针尖端 = 点击点
ARROW_H = 272.0
ARROW_W = ARROW_H * 0.60
TILT = -14.0           # 指针倾角（负值 = 向左倾，贴近系统指针）

RING_R = 252.0
RING_W = 15.0
RING_GAP = None            # 需要缺口时填 (start, end)

WHITE = (255, 255, 255)

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
APPICON = os.path.join(ROOT, "clickBoom", "Assets.xcassets", "AppIcon.appiconset")


def P(v):
    return v * SS


# ---------------------------------------------------------------- 底
def build_background():
    n = 512
    xs = np.linspace(0.0, 1.0, n, dtype=np.float32)
    t = (xs[:, None] + xs[None, :]) * 0.5

    top = np.array((30, 30, 34), np.float32)
    bottom = np.array((6, 6, 8), np.float32)
    arr = top * (1.0 - t[..., None]) + bottom * t[..., None]

    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32) / (n - 1)

    # 点击点附近轻微提亮，避免整块死黑
    gx, gy = TIP[0] / M, TIP[1] / M
    spot = np.exp(-(((xx - gx) ** 2 + (yy - gy) ** 2) / 0.055))
    arr += (spot * 12.0)[..., None]

    # 左上角极轻的斜面光
    gloss = np.exp(-(((xx - 0.30) ** 2) / 0.30 + ((yy - 0.02) ** 2) / 0.20))
    arr += (gloss * 10.0)[..., None]

    img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
    return img.resize((S, S), Image.BICUBIC)


def squircle_alpha():
    a = ICON_W / 2.0 * SS
    u = (np.abs(np.arange(S, dtype=np.float32) - S / 2.0) / a) ** SQ_N
    out = np.empty((S, S), np.float32)
    for y0 in range(0, S, 256):
        y1 = min(y0 + 256, S)
        d = (u[None, :] + u[y0:y1, None]) ** (1.0 / SQ_N)
        out[y0:y1] = np.clip((1.0 - d) * a / 1.6 + 0.5, 0.0, 1.0)
    return Image.fromarray((out * 255).astype(np.uint8))


# ---------------------------------------------------------------- 指针
def arrow_points():
    pts = [(0.0, 0.0), (0.0, 0.76), (0.175, 0.585), (0.285, 0.90),
           (0.40, 0.855), (0.30, 0.545), (0.585, 0.545)]
    a = math.radians(TILT)
    ca, sa = math.cos(a), math.sin(a)
    out = []
    for x, y in pts:
        dx, dy = x * ARROW_W, y * ARROW_H
        out.append((TIP[0] + dx * ca - dy * sa, TIP[1] + dx * sa + dy * ca))
    return out


# ---------------------------------------------------------------- 圆环
def ring_mask():
    """白色圆环，透明度沿右下方向衰减，看起来像向外扩散的波。"""
    lay = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(lay)
    box = [P(CX - RING_R), P(CY - RING_R), P(CX + RING_R), P(CY + RING_R)]
    if RING_GAP:
        d.arc(box, RING_GAP[1], RING_GAP[0] + 360, fill=255, width=int(P(RING_W)))
    else:
        d.ellipse(box, outline=255, width=int(P(RING_W)))

    halo = lay.filter(ImageFilter.GaussianBlur(P(30)))
    lay = ImageChops.lighter(lay, halo.point(lambda v: int(v * 0.45)))

    grad = Image.linear_gradient("L").rotate(45, resample=Image.BICUBIC)
    grad = grad.resize((S, S)).point(lambda v: int(104 + v * 0.58))
    return ImageChops.multiply(lay, grad)


# ---------------------------------------------------------------- 组装
def build_icon():
    icon = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    icon.paste(build_background(), (0, 0), squircle_alpha())

    ring = Image.new("RGBA", (S, S), WHITE + (0,))
    ring.putalpha(ring_mask())
    icon = Image.alpha_composite(icon, ring)

    # 指针外发光：把白色从黑底上托起来
    sh = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(sh).polygon([(P(x), P(y)) for x, y in arrow_points()], fill=(0, 0, 0, 160))
    sh = sh.filter(ImageFilter.GaussianBlur(P(12)))
    glow = Image.new("RGBA", (S, S), WHITE + (0,))
    glow.putalpha(sh.getchannel("A").point(lambda v: int(v * 0.12)))
    icon = Image.alpha_composite(icon, glow)

    cur = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(cur).polygon([(P(x), P(y)) for x, y in arrow_points()], fill=WHITE + (255,))
    icon = Image.alpha_composite(icon, cur)

    return add_rim(icon.resize((M, M), Image.LANCZOS))


def add_rim(icon):
    mask = squircle_alpha().resize((M, M), Image.LANCZOS)
    edge = ImageChops.subtract(mask, mask.filter(ImageFilter.MinFilter(7)))
    grad = Image.new("L", (1, M))
    for y in range(M):
        t = y / (M - 1)
        grad.putpixel((0, y), int(70 * (1.0 - t) ** 2 + 8))
    rim = Image.new("RGBA", (M, M), WHITE + (0,))
    rim.putalpha(ImageChops.multiply(edge, grad.resize((M, M))))
    return Image.alpha_composite(icon, rim)


# ---------------------------------------------------------------- 导出
SPECS = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]

CONTENTS = {
    "images": [
        {"filename": f, "idiom": "mac", "scale": sc, "size": sz}
        for f, sz, sc in [
            ("icon_16x16.png", "16x16", "1x"), ("icon_16x16@2x.png", "16x16", "2x"),
            ("icon_32x32.png", "32x32", "1x"), ("icon_32x32@2x.png", "32x32", "2x"),
            ("icon_128x128.png", "128x128", "1x"), ("icon_128x128@2x.png", "128x128", "2x"),
            ("icon_256x256.png", "256x256", "1x"), ("icon_256x256@2x.png", "256x256", "2x"),
            ("icon_512x512.png", "512x512", "1x"), ("icon_512x512@2x.png", "512x512", "2x"),
        ]
    ],
    "info": {"author": "xcode", "version": 1},
}


def preview(icon):
    sizes = [256, 128, 64, 32, 16]
    pad = 34
    w = pad * 2 + sum(sizes) + 26 * (len(sizes) - 1)
    h = pad * 2 + 256
    sheet = Image.new("RGB", (w, h * 2), "#ececee")
    d = ImageDraw.Draw(sheet)
    d.rectangle([0, h, w, h * 2], fill="#141416")
    x = pad
    for s in sizes:
        one = icon.resize((s, s), Image.LANCZOS)
        sheet.paste(one, (x, pad + (256 - s) // 2), one)
        sheet.paste(one, (x, h + pad + (256 - s) // 2), one)
        x += s + 26
    sheet.save(os.path.join(HERE, "preview.png"))


def main():
    icon = build_icon()
    os.makedirs(APPICON, exist_ok=True)
    for name, size in SPECS:
        icon.resize((size, size), Image.LANCZOS).save(os.path.join(APPICON, name))
    with open(os.path.join(APPICON, "Contents.json"), "w") as f:
        json.dump(CONTENTS, f, indent=2, ensure_ascii=False)
        f.write("\n")
    icon.save(os.path.join(HERE, "AppIcon-1024.png"))
    preview(icon)
    print("wrote", APPICON)


if __name__ == "__main__":
    sys.exit(main())
