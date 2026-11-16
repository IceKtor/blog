"""Мини-движок пиксель-арта: части с объёмной светотенью, цветной контур.
Только Pillow + numpy. Свет сверху-слева, 5 тонов на материал (0 — контур)."""
import numpy as np
from PIL import Image, ImageDraw

def hx(s):
    s = s.lstrip('#'); return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), 255)

P = {k: [hx(c) for c in v.split()] for k, v in {
 'wood':   '#3b1d1a #6b3824 #995a30 #bf7e45 #e0a964',
 'dwood':  '#26120f #47231a #673722 #86502f #a56c40',
 'lwood':  '#5a3420 #946036 #c08a4e #dcae6c #f2d494',
 'metal':  '#22263a #475068 #7a8598 #aeb8c6 #eef3f8',
 'cream':  '#6e5c62 #b9a99c #e2d8c8 #f6f0e4 #ffffff',
 'berry':  '#3a0a22 #7c1232 #b91f38 #e2463c #ff9a7c',
 'leaf':   '#132e22 #1f5638 #38803c #64aa40 #a8d45a',
 'gold':   '#46240f #8a541a #c28a2a #e6b84a #fae694',
 'stone':  '#2a2838 #4c4a5c #74708a #9c9ab0 #cccadc',
 'dirt':   '#3a2418 #5e3c26 #84583a #a87a50 #c89e6c',
 'sand':   '#7a5a3a #b08a5a #d6b47a #ecd29a #fbecc0',
 'skin':   '#4a2a26 #8a5440 #c88a68 #eab48c #fcd8b4',
 'hbrown': '#26140e #4a2a1a #73432a #9a6438 #c08a50',
 'hblack': '#121018 #22202e #34324a #4c4a66 #706e8a',
 'hgrey':  '#3a3640 #6e6870 #a29ca2 #cfcace #f2eff0',
 'hblond': '#6a4418 #a8702a #d8a440 #f0cc6a #fff0a8',
 'hred':   '#3a1210 #6e2418 #a43a20 #d05a2c #f08a4a',
 'teal':   '#102a34 #1a4a56 #24727a #3a9c98 #6cc8b4',
 'denim':  '#141a3a #22305e #34508e #5076b4 #84a6d8',
 'red':    '#3a0a14 #701624 #ac2a30 #d84a3c #f8865c',
 'purple': '#200e30 #3e1e56 #623a84 #8a5cae #b88ed6',
 'yellow': '#4a3010 #8a6418 #c89a22 #ecc840 #fff08a',
 'white':  '#5a5468 #9a94a4 #cac6cc #ecebec #ffffff',
 'green':  '#122a1a #1e4a2a #2e723a #4e9c48 #86c864',
 'apron':  '#2e1e14 #523a26 #7c5a3a #a07a52 #c8a476',
 'rred':   '#2a0a10 #5a1418 #8e2422 #c03a2a #e46a44',
 'rgreen': '#0e2420 #1a3e32 #2a5e44 #3e8250 #6aa868',
 'rblue':  '#141634 #24305a #344c86 #4a6eae #7a9ed4',
 'rbrown': '#24140e #44281a #664028 #8a5a36 #b07c4a',
 'brick':  '#2e1414 #5a2620 #8a3c2c #b05a3c #d0825a',
 'copper': '#3a1a10 #7a3a1c #b45a2a #e08a44 #f8be7a',
 'iron':   '#2a2a34 #545462 #84849a #b4b6c8 #e4e8f0',
 'goldore':'#4a2a08 #8a5a10 #d09a18 #f4d03a #fff4a0',
 'water':  '#1c3466 #24508c #2e6aa8 #4a8cc4 #8cc4e8',
 'orange': '#4a1a08 #8a3410 #c85a18 #ec8a2a #fcc060',
 'pink':   '#4a1a32 #8a3058 #c45478 #e88aa0 #fcc4cc',
 'lime':   '#1e3a10 #386a1a #5a9a24 #8ac834 #c4ec6a',
 'beet':   '#2a0a2a #521640 #842458 #b04070 #d8749a',
 'snow':   '#4c5a7e #8a9cc4 #bccbe6 #e2eaf6 #ffffff',
 'pine':   '#0c1e1c #143a30 #1e5a40 #2e7a4a #4e9e58',
 'fall':   '#4a1a0a #8e3412 #c8561a #ec8a2a #fac25a',
 'bloss':  '#5a2a3e #a85278 #dc84a4 #f4b4c8 #fff0f4',
}.items()}
RED, BLUE, YEL = hx('#c42c34'), hx('#3462b4'), hx('#e2b232')
INK = hx('#1c1418')

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
