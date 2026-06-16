#!/usr/bin/env python3
"""
App Store スクリーンショット生成スクリプト
- 上部: キャッチコピー（青帯 + 白テキスト）。sub を指定すると2行表示
- 下部: アプリ画面（角丸付き、両脇に小さなマージン）
"""
from PIL import Image, ImageDraw, ImageFont
import os

BASE = os.path.dirname(os.path.abspath(__file__))
OUT  = os.path.join(BASE, "ForAppStore")
os.makedirs(OUT, exist_ok=True)

CANVAS_W  = 1320
CANVAS_H  = 2868
HEADER_H  = 300       # デフォルトのヘッダー高さ（cfg で個別上書き可）
CORNER    = 100       # 角丸半径
HEADER_BG = "#007AFF"
HEADER_FG = "#FFFFFF"

FONT_W6 = "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc"
FONT_W3 = "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc"

CONFIGS = [
    dict(src="home.png",   out="01_home.png",   bg="#FFFFFF",
         text="全部、ひと目でわかる。",
         sub="URL・画像・動画・PDF・テキストを一元管理",
         header_h=420),
    dict(src="radial.png", out="02_radial.png", bg="#FFFFFF",
         text="URL・画像・動画・PDF・テキスト。"),
    dict(src="search.png", out="03_search.png", bg="#FFFFFF",
         text="タグとキーワードで一発検索。"),
    dict(src="detail.png", out="04_detail.png", bg="#FFFFFF",
         text="URLはサムネイル自動取得。"),
    dict(src="pin.png",    out="05_pin.png",    bg="#F2F2F7",
         text="フォトライブラリから直接保存。"),
    dict(src="dark.png",   out="06_dark.png",   bg="#1C1C1E",
         text="ダークモード完全対応。"),
]


def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))


def rounded_mask(size, radius):
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, size[0]-1, size[1]-1], radius=radius, fill=255)
    return mask


def fit_font(draw, text, font_path, max_w, size_max=88, size_min=40, step=4):
    for size in range(size_max, size_min - 1, -step):
        try:
            f = ImageFont.truetype(font_path, size)
        except Exception:
            return ImageFont.load_default(), size_min
        bbox = draw.textbbox((0, 0), text, font=f)
        if (bbox[2] - bbox[0]) <= max_w:
            return f, size
    return ImageFont.load_default(), size_min


def draw_centered(draw, text, font, y_center, canvas_w, fg):
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = (canvas_w - tw) // 2 - bbox[0]
    ty = y_center - th // 2 - bbox[1]
    draw.text((tx, ty), text, font=font, fill=fg)
    return th


def make(cfg):
    src_path = os.path.join(BASE, cfg["src"])
    out_path = os.path.join(OUT, cfg["out"])

    header_h = cfg.get("header_h", HEADER_H)
    app_h    = CANVAS_H - header_h

    app_img = Image.open(src_path).convert("RGBA")
    scale   = min(CANVAS_W / app_img.width, app_h / app_img.height)
    new_w   = int(app_img.width  * scale)
    new_h   = int(app_img.height * scale)
    app_img = app_img.resize((new_w, new_h), Image.LANCZOS)
    app_img.putalpha(rounded_mask((new_w, new_h), CORNER))

    canvas = Image.new("RGBA", (CANVAS_W, CANVAS_H), hex_rgb(cfg["bg"]) + (255,))
    draw   = ImageDraw.Draw(canvas)

    draw.rectangle([0, 0, CANVAS_W - 1, header_h - 1], fill=hex_rgb(HEADER_BG) + (255,))

    x = (CANVAS_W - new_w) // 2
    y = header_h + (app_h - new_h) // 2
    canvas.alpha_composite(app_img, dest=(x, y))

    draw = ImageDraw.Draw(canvas)
    fg   = hex_rgb(HEADER_FG) + (255,)
    text = cfg["text"]
    sub  = cfg.get("sub", "")
    max_w = int(CANVAS_W * 0.88)

    main_font, main_size = fit_font(draw, text, FONT_W6, max_w)

    if sub:
        sub_font, _ = fit_font(draw, sub, FONT_W3, max_w,
                               size_max=max(int(main_size * 0.60), 40),
                               size_min=36, step=2)
        main_bbox = draw.textbbox((0, 0), text, font=main_font)
        sub_bbox  = draw.textbbox((0, 0), sub,  font=sub_font)
        main_h = main_bbox[3] - main_bbox[1]
        sub_h  = sub_bbox[3]  - sub_bbox[1]
        gap    = main_size // 5
        total  = main_h + gap + sub_h
        base_y = (header_h - total) // 2

        main_x = (CANVAS_W - (main_bbox[2] - main_bbox[0])) // 2 - main_bbox[0]
        draw.text((main_x, base_y - main_bbox[1]), text, font=main_font, fill=fg)

        sub_x = (CANVAS_W - (sub_bbox[2] - sub_bbox[0])) // 2 - sub_bbox[0]
        draw.text((sub_x, base_y + main_h + gap - sub_bbox[1]), sub, font=sub_font, fill=fg)
    else:
        bbox = draw.textbbox((0, 0), text, font=main_font)
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
        draw.text(((CANVAS_W - tw) // 2 - bbox[0], (header_h - th) // 2 - bbox[1]),
                  text, font=main_font, fill=fg)

    result = Image.new("RGB", (CANVAS_W, CANVAS_H), hex_rgb(cfg["bg"]))
    result.paste(canvas, mask=canvas.split()[3])
    result.save(out_path, "PNG")
    print(f"  -> {cfg['out']}  ({new_w}x{new_h})")


print("App Store スクリーンショット生成中...")
for cfg in CONFIGS:
    make(cfg)
print("完了！ screenshots/ForAppStore/ に出力しました。")
