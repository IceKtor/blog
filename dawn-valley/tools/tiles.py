"""Тайлы 16x16 по сезонам + наложения краёв (вода, грядки, тропинки)."""
import math, random
import numpy as np
from PIL import Image
from pix import P, hx

SEASONS = ['spring', 'summer', 'fall', 'winter']
GRASS = {
 'spring': [hx(c) for c in '#2a5a34 #3c8040 #5aa848 #88c858 #bce47c'.split()],
 'summer': [hx(c) for c in '#1c4628 #2a6a30 #46923a #70b640 #a8d850'.split()],
 'fall':   [hx(c) for c in '#4a3a1c #7a6428 #a08a34 #c4a844 #e2cc6a'.split()],
 'winter': [hx(c) for c in '#56648a #8a9cc4 #bccbe6 #e2eaf6 #ffffff'.split()],
}
FLOWERS = {'spring': ['#f4b4c8', '#fff0f4', '#e88aa0'], 'summer': ['#fff08a', '#ffffff', '#ecc840'],
           'fall': ['#ec8a2a', '#c8561a', '#fac25a'], 'winter': ['#bccbe6', '#ffffff', '#8a9cc4']}

def new(c=(0, 0, 0, 0)):
    a = np.zeros((16, 16, 4), np.uint8); a[:, :] = c; return a

def put(a, x, y, c):
    if isinstance(c, str): c = hx(c)
    a[y % 16, x % 16] = c

def img(a): return Image.fromarray(a, 'RGBA')

def grass(season, seed, flowers=False, base_tone=2, dense=14):
    g = GRASS[season]; a = new(g[base_tone]); r = random.Random(seed)
    for _ in range(dense // 2):  # просто несколько тёмных точек
        x, y = r.randrange(16), r.randrange(16)
        put(a, x, y, g[base_tone - 1]); put(a, x + 1, y, g[base_tone - 1])
    if flowers:
        for c in FLOWERS[season][:2]:
            put(a, r.randrange(16), r.randrange(16), c)
    return a

def dirt_path(season, seed=3):
    d = P['dirt']; a = new(d[3]); r = random.Random(seed)
    for _ in range(22): put(a, r.randrange(16), r.randrange(16), d[2])
    for _ in range(8): put(a, r.randrange(16), r.randrange(16), d[4])
    for _ in range(4):
        x, y = r.randrange(16), r.randrange(16)
        put(a, x, y, P['stone'][3]); put(a, x+1, y, P['stone'][2]); put(a, x, y+1, d[1])
    if season == 'winter':
        for _ in range(14): put(a, r.randrange(16), r.randrange(16), P['snow'][3])
    return a

def tilled(wet):
    d = P['dirt']
    if wet:
        pal = [hx('#24161a'), hx('#3a2622'), hx('#4e3428'), hx('#664632'), hx('#7a5a44')]
    else:
        pal = [d[1], d[2], d[3], d[4], hx('#dcb888')]
    a = new(pal[2]); r = random.Random(9)
    for y in (3, 7, 11, 15):
        for x in range(16):
            if (x * 3 + y) % 7 != 0:
                put(a, x, y, pal[1]); put(a, x, y-1, pal[3])
    for _ in range(7): put(a, r.randrange(16), r.randrange(16), pal[4] if not wet else pal[0])
    if wet:
        for x, y in ((3, 5), (11, 9), (6, 13), (13, 1)): put(a, x, y, hx('#5a6a8a'))
    return a

def sand():
    s = P['sand']; a = new(s[3]); r = random.Random(4)
    for _ in range(20): put(a, r.randrange(16), r.randrange(16), s[2])
    for _ in range(8): put(a, r.randrange(16), r.randrange(16), s[4])
    for _ in range(2):
        x, y = r.randrange(16), r.randrange(16); put(a, x, y, hx('#f4d0c0')); put(a, x+1, y, s[1])
    return a

def planks(pal, vertical=False):
    w = P[pal]; a = new(w[2])
    for i in range(16):
        for k in (0, 5, 10, 15):
            if vertical: put(a, k, i, w[1])
            else: put(a, i, k, w[1])
        for k in (1, 6, 11):
            if vertical: put(a, k, i, w[3])
            else: put(a, i, k, w[3])
    for x, y in ((3, 3), (12, 8), (7, 13), (13, 2)):
        if vertical: put(a, y, x, w[1])
        else: put(a, x, y, w[1]); put(a, x+1, y, w[1])
    return a

def wall():
    a = new(hx('#d8c8a8')); w = P['wood']
    for y in range(16):
        for x in range(0, 16, 4): put(a, x, y, hx('#c4b090'))
    for x in range(16):
        for y in (12, 13, 14, 15): put(a, x, y, w[2] if y > 12 else w[3])
        put(a, x, 15, w[0])
    return a

def cave_floor(seed):
    s = P['stone']; d = P['dirt']; a = new(hx('#6a5a50')); r = random.Random(seed)
    for _ in range(26): put(a, r.randrange(16), r.randrange(16), r.choice([hx('#5a4a44'), hx('#7a6a5e')]))
    for _ in range(3):
        x, y = r.randrange(16), r.randrange(16); put(a, x, y, s[3]); put(a, x+1, y+1, s[1])
    return a

def cave_wall():
    s = P['stone']; a = new(s[1]); r = random.Random(12)
    for y in range(16):
        for x in range(16):
            v = math.sin(x*1.3 + y*0.4) + math.sin(y*0.9 - x*0.6)
            if v > 1.0: put(a, x, y, s[2])
            elif v < -1.2: put(a, x, y, s[0])
    for y in (5, 11):
        for x in range(16): put(a, x, y, s[0])
    for x in range(16): put(a, x, 15, hx('#14121c'))
    return a

def plaza():
    """Брусчатка: скруглённые камни разного размера, бесшовно."""
    st = P['stone']; a = new(st[1])
    stones = [(3, 3, 3, 2), (10, 2, 3, 2), (14, 6, 2, 2), (6, 8, 3, 2), (1, 9, 2, 2), (12, 11, 3, 2), (4, 13, 3, 2), (9, 14, 2, 1)]
    for cx, cy, rx, ry in stones:
        for y in range(-ry, ry + 1):
            for x in range(-rx, rx + 1):
                if (x / (rx + .5)) ** 2 + (y / (ry + .5)) ** 2 <= 1:
                    c = st[3]
                    if y == -ry or x == -rx: c = st[4]
                    elif y == ry or x == rx: c = st[2]
                    put(a, cx + x, cy + y, c)
    return a

def void(): return new(hx('#0e0c14'))

# ---------- наложения ----------
def water_edges(season):
    g = GRASS[season]; d = P['dirt']; w = P['water']; out = []
    def n_edge():
        a = new()
        for x in range(16):
            h = 3 + (1 if (x * 7) % 5 == 0 else 0)
            put(a, x, 0, g[2]); put(a, x, 1, g[1])
            for y in range(2, h + 1): put(a, x, y, d[2] if y < h else d[1])
            put(a, x, h + 1, w[0]); put(a, x, h + 2, w[1])
        return a
    def s_edge():
        a = new()
        for x in range(16):
            put(a, x, 15, d[3]); put(a, x, 14, w[4] if x % 3 else w[3])
        return a
    def w_edge():
        a = new()
        for y in range(16):
            put(a, 0, y, d[2]); put(a, 1, y, d[1]); put(a, 2, y, w[1] if y % 4 else w[4])
        return a
    n = n_edge(); s = s_edge(); wv = w_edge(); e = np.ascontiguousarray(wv[:, ::-1])
    out += [n, e, s, wv]
    # внутренние углы: суша по диагонали
    def corner(cx, cy):
        a = new()
        for y in range(4):
            for x in range(4):
                if x + y <= 3:
                    xx = x if cx == 0 else 15 - x; yy = y if cy == 0 else 15 - y
                    put(a, xx, yy, d[2] if x + y < 3 else w[4])
        return a
    out += [corner(1, 0), corner(0, 0), corner(1, 1), corner(0, 1)]  # NE, NW, SE, SW
    return out

def soil_rims():
    d = P['dirt']; out = []
    a = new(); [put(a, x, 0, d[0]) for x in range(16)]; [put(a, x, 1, d[1]) for x in range(16)]; out.append(a)
    a = new(); [put(a, 15, y, d[1]) for y in range(16)]; out.append(a)
    a = new(); [put(a, x, 15, d[4]) for x in range(16)]; out.append(a)
    a = new(); [put(a, 0, y, d[0]) for y in range(16)]; [put(a, 1, y, d[1]) for y in range(16)]; out.append(a)
    return out

def path_fringe(season):
    g = GRASS[season]; out = []; r = random.Random(5)
    base = new()
    for x in range(16):
        h = r.choice([1, 1, 2, 2, 3])
        for y in range(h): put(base, x, y, g[2] if y < h - 1 else g[1])
        if h >= 2 and r.random() < .4: put(base, x, h, g[0])
    n = base
    out = [n, np.ascontiguousarray(np.rot90(n, -1)), np.ascontiguousarray(np.rot90(n, 2)), np.ascontiguousarray(np.rot90(n, 1))]
    return out

def season_sheet(season):
    row0 = [grass(season, 1), grass(season, 2, dense=20), grass(season, 3, flowers=True), dirt_path(season),
            tilled(False), tilled(True), sand(), planks('lwood'), wall(), cave_floor(1), cave_floor(2),
            cave_wall(), planks('wood', True), grass(season, 7, base_tone=1, dense=18), plaza(), void()]
    row1 = water_edges(season) + soil_rims() + path_fringe(season)
    im = Image.new('RGBA', (256, 32))
    for i, t in enumerate(row0): im.paste(img(t), (i * 16, 0))
    for i, t in enumerate(row1): im.paste(img(t), (i * 16, 16))
    return im

def _unused_water_frames(n=8):
    """Гладкая анимированная вода: бесшовный шум из синусоид с целыми частотами."""
    w = P['water']; frames = []
    waves = [(1, 0, 1.0, 0.0, 1), (0, 1, 0.8, 1.3, 1), (1, 1, 0.7, 2.1, -1), (2, -1, 0.45, 0.4, 1), (-1, 2, 0.4, 3.3, -1)]
    for f in range(n):
        t = f / n * 2 * math.pi
        a = new(w[2])
        for y in range(16):
            for x in range(16):
                v = sum(amp * math.sin(2 * math.pi * (kx * x + ky * y) / 16 + ph + sp * t) for kx, ky, amp, ph, sp in waves)
                if v > 2.05: put(a, x, y, w[4])
                elif v > 1.2: put(a, x, y, w[3])
                elif v < -1.6: put(a, x, y, w[1])
        frames.append(img(a))
    im = Image.new('RGBA', (16 * n, 16))
    for i, fr in enumerate(frames): im.paste(fr, (i * 16, 0))
    return im
