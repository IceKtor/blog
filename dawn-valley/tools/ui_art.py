"""Рамки интерфейса (9-slice), иконки HUD, фон главного меню."""
import math, random
from PIL import Image, ImageDraw
from pix import hx

def _px(im, x, y, c): im.putpixel((x, y), hx(c) if isinstance(c, str) else c)

# Простой плоский стиль: тёмно-синие панели с белой рамкой.
BG, BORDER, LINE = '#25304a', '#e8ecf4', '#141a2a'

def panel():
    im = Image.new('RGBA', (32, 32), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 31, 31], fill=hx(LINE))
    d.rectangle([1, 1, 30, 30], fill=hx(BORDER))
    d.rectangle([2, 2, 29, 29], fill=hx(BG))
    return im

def slot(sel=False):
    im = Image.new('RGBA', (18, 18), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 17, 17], fill=hx('#ffd23c' if sel else '#5a6680'))
    d.rectangle([1, 1, 16, 16], fill=hx('#3a4766' if sel else '#1a2234'))
    return im

def button(state):
    fill = {'normal': '#3d5a8c', 'hover': '#5476b0', 'pressed': '#2b4068', 'disabled': '#4a4f5a'}[state]
    im = Image.new('RGBA', (24, 16), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 23, 15], fill=hx(LINE)); d.rectangle([1, 1, 22, 14], fill=hx(fill))
    return im

def tooltip():
    im = Image.new('RGBA', (16, 16), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 15, 15], fill=hx(BORDER)); d.rectangle([1, 1, 14, 14], fill=hx('#1a2234'))
    return im

def heart(full):
    im = Image.new('RGBA', (9, 8)); rows = ['.##...##.', '#ooo.ooo#', '#ooooooo#', '#ooooooo#', '.#ooooo#.', '..#ooo#..', '...#o#...', '....#....']
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch == '#': _px(im, x, y, '#3a0a14')
            elif ch == 'o': _px(im, x, y, ('#e2463c' if (x + y) > 4 else '#ff9a7c') if full else '#8a7a72')
    return im

def coin_icon():
    im = Image.new('RGBA', (9, 9)); d = ImageDraw.Draw(im)
    d.ellipse([0, 0, 8, 8], fill=hx('#8a541a')); d.ellipse([1, 1, 7, 7], fill=hx('#e6b84a')); d.ellipse([3, 3, 5, 5], fill=hx('#c28a2a'))
    _px(im, 2, 2, '#fae694'); return im

def bolt():
    im = Image.new('RGBA', (8, 9)); rows = ['....##..', '...#y#..', '..#yy#..', '.#yyyy#.', '#yyyyy#.', '.#yy#...', '..#y#...', '..##....', '........']
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch == '#': _px(im, x, y, '#4a3010')
            elif ch == 'y': _px(im, x, y, '#ecc840')
    return im

def ui_sheet():
    im = Image.new('RGBA', (128, 64), (0, 0, 0, 0))
    im.paste(panel(), (0, 0)); im.paste(slot(), (32, 0)); im.paste(slot(True), (50, 0))
    im.paste(heart(True), (72, 0)); im.paste(heart(False), (81, 0)); im.paste(coin_icon(), (90, 0)); im.paste(bolt(), (99, 0))
    for i, st in enumerate(['normal', 'hover', 'pressed', 'disabled']): im.paste(button(st), (i * 24, 32))
    im.paste(tooltip(), (0, 48))
    return im

def title_bg():
    W, H = 480, 270; im = Image.new('RGBA', (W, H), hx('#7ec8f0')); d = ImageDraw.Draw(im)
    d.rectangle([0, 0, W, 60], fill=hx('#6ab8e8'))
    d.ellipse([360, 30, 410, 80], fill=hx('#ffe35a'), outline=hx('#1e1e2a'))
    for cx, cy in ((80, 50), (230, 35)):
        d.ellipse([cx, cy, cx + 50, cy + 20], fill=hx('#ffffff'), outline=hx('#1e1e2a'))
    d.polygon([(0, 190), (120, 150), (260, 175), (380, 145), (480, 170), (480, 270), (0, 270)], fill=hx('#4caf50'), outline=hx('#1e1e2a'))
    d.rectangle([0, 215, W, 270], fill=hx('#8d5a34'))
    for y in range(222, 270, 12): d.line([0, y, W, y], fill=hx('#6b4226'), width=2)
    d.rectangle([60, 160, 120, 205], fill=hx('#e0b070'), outline=hx('#1e1e2a'))
    d.polygon([(52, 162), (90, 130), (128, 162)], fill=hx('#d64545'), outline=hx('#1e1e2a'))
    d.rectangle([84, 180, 96, 205], fill=hx('#6b4226'), outline=hx('#1e1e2a'))
    d.rectangle([370, 140, 400, 205], fill=hx('#dddddd'), outline=hx('#1e1e2a'))
    d.line([385, 140, 360, 115], fill=hx('#1e1e2a'), width=3); d.line([385, 140, 410, 115], fill=hx('#1e1e2a'), width=3)
    d.line([385, 140, 360, 165], fill=hx('#1e1e2a'), width=3); d.line([385, 140, 410, 165], fill=hx('#1e1e2a'), width=3)
    return im
