"""Рамки интерфейса (9-slice), иконки HUD, фон главного меню."""
import math, random
from PIL import Image, ImageDraw
from pix import hx

def _px(im, x, y, c): im.putpixel((x, y), hx(c) if isinstance(c, str) else c)

def panel():
    im = Image.new('RGBA', (32, 32), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.rounded_rectangle([0, 0, 31, 31], 3, fill=hx('#3b1d1a'))
    d.rounded_rectangle([1, 1, 30, 30], 2, fill=hx('#995a30'))
    d.line([2, 1, 29, 1], fill=hx('#e0a964')); d.line([1, 2, 1, 29], fill=hx('#bf7e45'))
    d.line([2, 30, 29, 30], fill=hx('#6b3824')); d.line([30, 2, 30, 29], fill=hx('#6b3824'))
    d.rectangle([4, 4, 27, 27], fill=hx('#6b3824'))
    d.rectangle([5, 5, 26, 26], fill=hx('#f7e3b5'))
    d.line([5, 5, 26, 5], fill=hx('#e6c88e')); d.line([5, 5, 5, 26], fill=hx('#e6c88e'))
    for x, y in ((2, 3), (28, 3), (2, 28), (28, 28)): _px(im, x, y, '#e0a964')  # заклёпки
    return im

def slot(sel=False):
    im = Image.new('RGBA', (18, 18), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.rectangle([0, 0, 17, 17], fill=hx('#c42c34' if sel else '#995a30'))
    if sel: d.rectangle([1, 1, 16, 16], fill=hx('#ffd36a'))
    d.rectangle([2 if sel else 1, 2 if sel else 1, 15 if sel else 16, 15 if sel else 16], fill=hx('#fae6a8' if sel else '#f0d6a0'))
    o = 2 if sel else 1
    d.line([o, o, 17 - o, o], fill=hx('#c9a36a')); d.line([o, o, o, 17 - o], fill=hx('#c9a36a'))
    return im

def button(state):
    fill = {'normal': '#c08a4e', 'hover': '#dcae6c', 'pressed': '#946036', 'disabled': '#9a8a80'}[state]
    hi = {'normal': '#e8c080', 'hover': '#f6dca0', 'pressed': '#b07a44', 'disabled': '#b8aca4'}[state]
    lo = {'normal': '#6b3824', 'hover': '#8a5030', 'pressed': '#5a2c1a', 'disabled': '#6e6260'}[state]
    im = Image.new('RGBA', (24, 16), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.rounded_rectangle([0, 0, 23, 15], 2, fill=hx('#3b1d1a'))
    d.rectangle([1, 1, 22, 14], fill=hx(fill))
    d.line([2, 1, 21, 1], fill=hx(hi)); d.line([1, 2, 1, 13], fill=hx(hi))
    d.line([2, 14, 21, 14], fill=hx(lo)); d.line([22, 2, 22, 13], fill=hx(lo)); d.line([2, 13, 21, 13], fill=hx(lo))
    return im

def tooltip():
    im = Image.new('RGBA', (16, 16), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    d.rounded_rectangle([0, 0, 15, 15], 2, fill=hx('#3b1d1a')); d.rectangle([1, 1, 14, 14], fill=hx('#fbecc4'))
    d.line([1, 14, 14, 14], fill=hx('#d6b47a')); return im

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
    W, H = 480, 270; im = Image.new('RGBA', (W, H)); d = ImageDraw.Draw(im)
    sky = ['#3a4a8a', '#4e5c9c', '#6a6cae', '#8a78b4', '#b486b0', '#dc96a0', '#f4ac94', '#fcc890', '#fde4a8']
    bh = 150 // len(sky)
    for i, c in enumerate(sky): d.rectangle([0, i * bh, W, (i + 1) * bh + 2], fill=hx(c))
    for i in range(3):  # дизеринг между полосами
        pass
    d.ellipse([300, 110, 360, 170], fill=hx('#fff4c0')); d.ellipse([306, 116, 354, 164], fill=hx('#fffbe4'))
    r = random.Random(2)
    for _ in range(40): x, y = r.randrange(W), r.randrange(60); d.point((x, y), fill=hx('#e8e4ff'))
    for cx, cy, w in ((80, 50, 60), (200, 30, 40), (420, 60, 50)):  # облака
        for k in range(4): d.ellipse([cx + k * w // 4 - 12, cy - 6 - (k % 2) * 4, cx + k * w // 4 + 16, cy + 8], fill=hx('#f6c8c0'))
        d.rectangle([cx - 10, cy + 2, cx + w + 10, cy + 8], fill=hx('#f6c8c0'))
    def hill(col, base, amp, f, ph):
        pts = [(0, H)] + [(x, base + amp * math.sin(x * f + ph) + amp * .4 * math.sin(x * f * 2.7 + ph * 2)) for x in range(0, W + 4, 4)] + [(W, H)]
        d.polygon(pts, fill=hx(col))
    hill('#5a6aa0', 150, 10, .012, 1); hill('#4a7a6a', 165, 8, .018, 2); hill('#4e9a48', 185, 9, .015, 4)
    for x in range(0, W, 26):  # ели вдали
        h = 14 + (x * 7) % 9; y = 160 + int(8 * math.sin(x * .018 + 2))
        d.polygon([(x, y), (x + 6, y - h), (x + 12, y)], fill=hx('#2e5a4a'))
    hill('#64aa40', 205, 6, .01, 0)
    for i, y in enumerate(range(215, 270, 7)):  # грядки
        d.rectangle([0, y, W, y + 3], fill=hx('#84583a' if i % 2 else '#5e3c26'))
        for x in range(8 + (i % 2) * 9, W, 18): d.ellipse([x, y - 3, x + 6, y + 2], fill=hx('#4e9c48'))
    # домик
    d.rectangle([60, 176, 112, 206], fill=hx('#c08a4e')); d.polygon([(54, 178), (86, 152), (118, 178)], fill=hx('#ac2a30'))
    d.rectangle([80, 188, 90, 206], fill=hx('#47231a')); d.rectangle([66, 184, 74, 192], fill=hx('#fde4a8')); d.rectangle([98, 184, 106, 192], fill=hx('#fde4a8'))
    # мельница
    d.polygon([(380, 206), (386, 150), (404, 150), (410, 206)], fill=hx('#e2d8c8')); d.polygon([(380, 152), (395, 136), (410, 152)], fill=hx('#664028'))
    for a in range(4):
        ang = a * math.pi / 2 + .4
        d.line([395, 146, 395 + 34 * math.cos(ang), 146 + 34 * math.sin(ang)], fill=hx('#6b3824'), width=3)
    return im
