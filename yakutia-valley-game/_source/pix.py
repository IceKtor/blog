"""Мини-движок пиксель-арта: части с объёмной светотенью, цветной контур.
Только Pillow + numpy. Свет сверху-слева, 5 тонов на материал (0 — контур)."""
import numpy as np
from PIL import Image, ImageDraw

def hx(s):
    s = s.lstrip('#'); return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), 255)

P = {k: [hx(c) for c in v.split()] for k, v in {
 'wood':  '#3b1d1a #6b3824 #995a30 #bf7e45 #e0a964',
 'dwood': '#26120f #47231a #673722 #86502f #a56c40',
 'burl':  '#3b2216 #7a4a26 #b07a3e #d4a462 #f0cc8a',
 'metal': '#22263a #475068 #7a8598 #aeb8c6 #eef3f8',
 'cream': '#6e5c62 #b9a99c #e2d8c8 #f6f0e4 #ffffff',
 'berry': '#3a0a22 #7c1232 #b91f38 #e2463c #ff9a7c',
 'leaf':  '#132e22 #1f5638 #38803c #64aa40 #a8d45a',
 'gold':  '#46240f #8a541a #c28a2a #e6b84a #fae694',
 'silver':'#252a42 #525e7e #8b99b2 #c0cddc #f2f7fc',
 'fur':   '#2a1710 #4e2c1c #7a4a2e #a06a44 #c89466',
 'wfur':  '#5c5668 #a8a0aa #d6d0cc #efebe4 #ffffff',
 'ice':   '#1d3c6c #3d7cb2 #6cb6dc #a4def2 #ecfcff',
 'clay':  '#4a2c22 #87603e #b58c5c #d6b27a #eed49e',
 'wclay': '#5c5260 #a89c98 #d8d0c4 #eee8dc #fffdf4',
 'sod':   '#2c1c14 #4c3220 #6c4a2e #8a6640 #a88454',
 'birch': '#4c4040 #988a7a #d2c4a6 #eee2c6 #fffaea',
 'fire':  '#5a1408 #c0381a #f27c1e #ffc43a #fff4a8',
 'coat':  '#3a3036 #6e6260 #a59a8c #cdc3b2 #eee7d8',
 'mane':  '#1c1412 #382820 #58402e #7a5a3e #9c7a56',
 'skin':  '#4a2a26 #8a5440 #c08060 #e0a880 #f6d0a8',
 'cloth': '#1e1a3a #2e3a6e #3462b4 #5a8ad0 #9cc0ec',
 'rcloth':'#3a0a1a #7a1426 #c42c34 #e05a4a #f8a080',
 'stone': '#2a2838 #4c4a5c #74708a #9c9ab0 #cccadc',
 'water': '#1d3c6c #24548e #3d7cb2 #5a9ccc #a4def2',
}.items()}
RED, BLUE, YEL = hx('#c42c34'), hx('#3462b4'), hx('#e2b232')

def _mask(w, h, fn):
    im = Image.new('L', (w, h), 0); fn(ImageDraw.Draw(im)); return np.array(im) > 0

def ell(cx, cy, rx, ry):   return ('e', cx, cy, rx, ry)
def rect(x0, y0, x1, y1):  return ('r', x0, y0, x1, y1)   # включительно
def poly(*pts):            return ('p', pts)
def line(*pts, wd=1):      return ('l', pts, wd)

def shape_mask(w, h, shapes):
    def fn(d):
        for s in shapes:
            if s[0] == 'e':
                _, cx, cy, rx, ry = s; d.ellipse([cx-rx, cy-ry, cx+rx, cy+ry], fill=255)
            elif s[0] == 'r':
                d.rectangle(list(s[1:]), fill=255)
            elif s[0] == 'p':
                d.polygon(list(s[1]), fill=255)
            elif s[0] == 'l':
                d.line(list(s[1]), fill=255, width=s[2])
    return _mask(w, h, fn)

def erode(m):
    e = m.copy()
    e[1:, :] &= m[:-1, :]; e[:-1, :] &= m[1:, :]
    e[:, 1:] &= m[:, :-1]; e[:, :-1] &= m[:, 1:]
    e[0, :] = e[-1, :] = False; e[:, 0] = e[:, -1] = False
    return e

def depth(m, cap=4):
    d = np.zeros(m.shape, int); cur = m.copy()
    for _ in range(cap):
        d += cur; cur = erode(cur)
    return d

class Spr:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.img = np.zeros((h, w, 4), np.uint8)
        self.pid = np.zeros((h, w), int)
        self.mats = [None]
        self.noline = np.zeros((h, w), bool)

    def tones(self, m, mode, bias):
        ys, xs = np.nonzero(m)
        t = np.zeros(m.shape, float)
        if len(xs) == 0: return t.astype(int)
        x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
        bw, bh = max(1, x1-x0), max(1, y1-y0)
        Y, X = np.mgrid[0:self.h, 0:self.w]
        u = (X-x0)/bw; v = (Y-y0)/bh
        d = depth(m, 3)
        if mode == 'round':
            val = 1.0 - (0.55*u + 0.45*v)
            val = val*0.8 + 0.2*(d/3.0)
            hl = (np.hypot(u-0.3, v-0.28) < 0.17) & (d >= 2)
            val[hl] = 1.0
        elif mode == 'cyl':
            val = 1.0 - np.clip(np.abs(u-0.32)*1.5, 0, 1)
            val = val*0.85 + 0.15*(1-v)
        elif mode == 'glow':
            val = 1.0 - np.clip(np.hypot(u-0.5, (v-0.6)*1.2)*1.6, 0, 1)
        else:  # flat
            val = np.full(m.shape, 0.5)
            # блик на верх/лево, тень на низ/право
            up = np.zeros_like(m); up[1:, :] = m[:-1, :]
            lf = np.zeros_like(m); lf[:, 1:] = m[:, :-1]
            dn = np.zeros_like(m); dn[:-1, :] = m[1:, :]
            rt = np.zeros_like(m); rt[:, :-1] = m[:, 1:]
            val[m & (~up | ~lf)] = 0.8
            val[m & (~dn | ~rt)] = 0.25
        val = val + bias
        return np.clip(1 + np.floor(val*3.999), 1, 4).astype(int)

    def add(self, mat, *shapes, mode='round', sep=True, bias=0.0, on=None):
        m = shape_mask(self.w, self.h, shapes)
        if on is not None: m &= self.pid == on
        pal = P[mat] if isinstance(mat, str) else mat
        t = self.tones(m, mode, bias)
        if sep:  # внутренняя линия на границе с уже нарисованным
            occ = (self.pid > 0) & ~m
            nb = np.zeros_like(m)
            nb[1:, :] |= occ[:-1, :]; nb[:-1, :] |= occ[1:, :]
            nb[:, 1:] |= occ[:, :-1]; nb[:, :-1] |= occ[:, 1:]
            # линия только снизу/справа от более светлых соседей — на обеих сторонах слишком жирно
            t[m & nb] = np.maximum(1, t[m & nb] - 2)
        self.mats.append(pal)
        idx = len(self.mats) - 1
        for k in range(5):
            sel = m & (t == k)
            self.img[sel] = pal[k]
        self.pid[m] = idx
        self.noline[m] = False
        return idx

    def px(self, x, y, c, on=None):
        if 0 <= x < self.w and 0 <= y < self.h:
            if on is None or self.pid[y, x] == on:
                if isinstance(c, str): c = hx(c)
                self.img[y, x] = c
                if self.pid[y, x] == 0: self.pid[y, x] = -1
                self.noline[y, x] = True

    def pts(self, c, points, on=None):
        for x, y in points: self.px(x, y, c, on)

    def dt(self, c, *shapes, on=None):
        m = shape_mask(self.w, self.h, shapes)
        for y, x in zip(*np.nonzero(m)): self.px(int(x), int(y), c, on)

    def cut(self, *shapes):
        m = shape_mask(self.w, self.h, shapes)
        self.img[m] = 0; self.pid[m] = 0

    def render(self, outline=True):
        out = self.img.copy()
        if outline:
            filled = self.img[:, :, 3] > 0
            e = np.zeros_like(filled)
            pad = np.pad(filled, 1)
            e = filled & ~(pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:])
            for y, x in zip(*np.nonzero(e)):
                p = self.pid[y, x]
                if p > 0: out[y, x] = self.mats[p][0]
        return Image.fromarray(out, 'RGBA')

def sheet(cells, cw, ch, cols):
    rows = (len(cells) + cols - 1)//cols
    im = Image.new('RGBA', (cw*cols, ch*rows), (0, 0, 0, 0))
    for i, c in enumerate(cells):
        im.paste(c, ((i % cols)*cw, (i//cols)*ch))
    return im
