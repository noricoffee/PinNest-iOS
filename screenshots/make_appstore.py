#!/usr/bin/env python3
"""
App Store スクリーンショット生成スクリプト
- 上部15%: キャッチコピー（背景はアプリ画面の上端色に合わせる）
- 下部85%: アプリ画面（角丸付き、両脇に小さなマージン）
"""
from PIL import Image, ImageDraw, ImageFont
import os

BASE = os.path.dirname(os.path.abspath(__file__))
OUT  = os.path.join(BASE, "ForAppStore")
os.makedirs(OUT, exist_ok=True)

CANVAS_W = 1320
CANVAS_H = 2868
HEADER_H = 300       # 上部テキスト領域
APP_H    = CANVAS_H - HEADER_H   # 2568
CORNER   = 100       # 角丸半径（スクリーンショットに付与）

# W3 = Regular, W6 = SemiBold
FONT_W6 = "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc"
FONT_W3 = "/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc"

CONFIGS = [
    dict(src="home.png",   out="01_home.png",   text="何でも、ここに。",     bg="#FFFFFF", fg="#1C1C1E"),
    dict(src="share.png",  out="02_share.png",  text="2タップで保存。",      bg="#F2F2F7", fg="#1C1C1E"),
    dict(src="search.png", out="03_search.png", text="すぐ見つかる。",        bg="#FFFFFF", fg="#1C1C1E"),
    dict(src="detail.png", out="04_detail.png", text="5種類を一元管理。",     bg="#FFFFFF", fg="#1C1C1E"),
    dict(src="pin.png",    out="05_pin.png",    text="かんたんに保存。",      bg="#F2F2F7", fg="#1C1C1E"),
    dict(src="dark.png",   out="06_dark.png",   text="ダークも、もちろん。", bg="#1C1C1E", fg="#FFFFFF"),
]


def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))


def rounded_mask(size, radius):
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, size[0]-1, size[1]-1], radius=radius, fill=255)
    return mask


def make(cfg):
    src_path = os.path.join(BASE, cfg["src"])
    out_path = os.path.join(OUT, cfg["out"])

    app_img = Image.open(src_path).convert("RGBA")

    # --- アプリ画面をスケール（幅1320に合わせた後、APP_Hに収める） ---
    scale = min(CANVAS_W / app_img.width, APP_H / app_img.height)
    new_w = int(app_img.width  * scale)
    new_h = int(app_img.height * scale)
    app_img = app_img.resize((new_w, new_h), Image.LANCZOS)

    # 角丸マスク適用
    mask = rounded_mask((new_w, new_h), CORNER)
    app_img.putalpha(mask)

    # --- キャンバス作成 ---
    bg = hex_rgb(cfg["bg"]) + (255,)
    canvas = Image.new("RGBA", (CANVAS_W, CANVAS_H), bg)

    # アプリ画面を中央揃えで貼り付け
    x = (CANVAS_W - new_w) // 2
    y = HEADER_H + (APP_H - new_h) // 2
    canvas.alpha_composite(app_img, dest=(x, y))

    # --- キャッチコピーを描画 ---
    draw = ImageDraw.Draw(canvas)
    text = cfg["text"]
    fg   = hex_rgb(cfg["fg"]) + (255,)

    font_size = 88
    try:
        font = ImageFont.truetype(FONT_W6, font_size)
    except Exception:
        font = ImageFont.load_default()

    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = (CANVAS_W - tw) // 2 - bbox[0]
    ty = (HEADER_H - th) // 2 - bbox[1]

    draw.text((tx, ty), text, font=font, fill=fg)

    # --- 保存 ---
    result = Image.new("RGB", (CANVAS_W, CANVAS_H), hex_rgb(cfg["bg"]))
    result.paste(canvas, mask=canvas.split()[3])
    result.save(out_path, "PNG")
    print(f"  -> {cfg['out']}  ({new_w}x{new_h})")


print("App Store スクリーンショット生成中...")
for cfg in CONFIGS:
    make(cfg)
print("完了！ screenshots/ForAppStore/ に出力しました。")
