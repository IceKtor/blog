"""Иконки предметов 16x16 и культуры 16x32 (6 стадий)."""
from pix import Spr, P, ell, rect, poly, line, hx, RED

def tool_hoe():
    s = Spr(16, 16); s.add('wood', line((2, 14), (11, 4), wd=2), mode='cyl')
    s.add('iron', poly((9, 2), (14, 3), (15, 7), (13, 7), (11, 5)), mode='round'); return s.render()
def tool_can():
    s = Spr(16, 16); s.add('copper', rect(3, 6, 11, 13), mode='cyl'); s.add('copper', poly((11, 8), (15, 4), (15, 6), (11, 11)), mode='flat')
    s.add('copper', line((4, 6), (7, 2), (10, 6)), mode='flat', sep=False); s.dt(P['water'][3], line((4, 7), (10, 7))); return s.render()
def tool_axe():
    s = Spr(16, 16); s.add('wood', line((3, 14), (11, 3), wd=2), mode='cyl')
    s.add('iron', poly((8, 2), (13, 1), (15, 6), (12, 8), (10, 5)), mode='round'); s.dt(P['iron'][4], line((14, 3), (14, 5))); return s.render()
def tool_pick():
    s = Spr(16, 16); s.add('wood', line((3, 14), (10, 5), wd=2), mode='cyl')
    s.add('iron', poly((2, 5), (6, 2), (10, 1), (14, 2), (15, 5), (12, 4), (9, 4), (5, 5)), mode='round'); return s.render()
def tool_rod():
    s = Spr(16, 16); s.add('lwood', line((2, 14), (13, 2), wd=2), mode='cyl'); s.add('dwood', ell(5, 11, 2, 2), mode='round')
    s.dt(hx('#eef3f8'), line((13, 2), (14, 9))); s.px(14, 10, RED); return s.render()

CROP_PAL = {'radish': 'pink', 'potato': 'sand', 'strawberry': 'red', 'corn': 'yellow', 'tomato': 'red',
            'melon': 'lime', 'cabbage': 'lime', 'beet': 'beet', 'pumpkin': 'orange'}

def seed(kind):
    s = Spr(16, 16)
    s.add('cream', poly((3, 2), (13, 2), (13, 14), (3, 14)), mode='round', bias=.1)
    s.add(CROP_PAL[kind], rect(3, 2, 13, 5), mode='flat')
    s.add(CROP_PAL[kind], ell(8, 10, 3, 3), mode='round')
    s.add('leaf', ell(8, 7, 2, 1), mode='flat', sep=False)
    s.dt(P['cream'][1], line((4, 14), (12, 14))); return s.render()

def produce(kind):
    s = Spr(16, 16)
    if kind == 'radish':
        s.add('leaf', poly((6, 1), (8, 6), (10, 1), (13, 3), (9, 7), (7, 7), (3, 3)), mode='round')
        s.add('pink', ell(8, 10, 4, 4), mode='round'); s.add('white', line((8, 14), (8, 15)), mode='flat', sep=False)
    elif kind == 'potato':
        s.add('sand', ell(8, 9, 6, 5), mode='round')
        for x, y in ((5, 8), (10, 10), (8, 12), (11, 7)): s.px(x, y, P['sand'][1])
    elif kind == 'strawberry':
        s.add('red', poly((3, 5), (13, 5), (8, 15)), mode='round'); s.add('leaf', poly((4, 5), (8, 2), (12, 5), (8, 6)), mode='flat')
        for x, y in ((6, 7), (9, 8), (7, 10), (10, 6), (8, 12)): s.px(x, y, P['yellow'][4])
    elif kind == 'corn':
        s.add('leaf', poly((3, 15), (6, 6), (8, 14)), mode='flat'); s.add('yellow', ell(9, 7, 3, 6), mode='round')
        for y in range(3, 12, 2): s.dt(P['yellow'][1], line((7, y), (11, y)))
        s.add('leaf', poly((13, 15), (11, 6), (9, 14)), mode='flat')
    elif kind == 'tomato':
        s.add('red', ell(8, 9, 6, 5), mode='round'); s.add('leaf', poly((5, 4), (8, 2), (11, 4), (8, 5)), mode='flat')
    elif kind == 'melon':
        s.add('lime', ell(8, 9, 7, 6), mode='round')
        for x in (4, 8, 12): s.dt(P['green'][1], line((x, 4), (x - 1, 14)))
    elif kind == 'cabbage':
        s.add('lime', ell(8, 9, 7, 6), mode='round'); s.add('lime', ell(8, 8, 4, 4), mode='round', bias=.15)
        s.dt(P['lime'][1], line((8, 5), (8, 12)))
    elif kind == 'beet':
        s.add('leaf', poly((5, 1), (8, 6), (11, 1), (12, 4), (9, 7), (7, 7), (4, 4)), mode='round')
        s.dt(P['red'][2], line((8, 3), (8, 7))); s.add('beet', ell(8, 10, 5, 4), mode='round'); s.px(8, 15, P['beet'][1])
    elif kind == 'pumpkin':
        s.add('orange', ell(8, 10, 7, 5), mode='round')
        for x in (5, 8, 11): s.dt(P['orange'][1], line((x, 6), (x, 14)))
        s.add('dwood', rect(7, 2, 9, 5), mode='flat')
    return s.render()

def fish(body, fin, slim=False, spots=None, whisk=False, flat=False):
    s = Spr(16, 16); ry = 3 if slim else (5 if flat else 4)
    s.add(fin, poly((1, 4), (4, 8), (1, 12)), mode='flat')
    s.add(body, ell(8, 8, 6, ry), mode='round')
    s.add(fin, poly((6, 8 - ry), (9, 8 - ry - 2), (11, 8 - ry + 1)), mode='flat')
    for x in range(5, 12, 2):
        for y in range(8 - ry + 2, 8 + ry - 1, 2): s.px(x, y, P[body][1])
    if spots:
        for x, y in ((6, 7), (9, 9), (10, 6), (5, 10)): s.px(x, y, P[spots][2])
    s.px(12, 7, hx('#1a1a20')); s.px(12, 6, P[body][4])
    if whisk: s.dt(P['hgrey'][1], line((13, 9), (15, 11)), line((13, 10), (14, 13)))
    return s.render()

def wood():
    s = Spr(16, 16)
    for cy in (11, 6):
        s.add('wood', rect(2, cy - 2, 12, cy + 2), mode='cyl'); s.add('lwood', ell(13, cy, 2, 2), mode='flat'); s.px(13, cy, P['lwood'][1])
    return s.render()
def stone():
    s = Spr(16, 16); s.add('stone', ell(8, 9, 6, 5), mode='round'); return s.render()
def fiber():
    s = Spr(16, 16)
    for x0 in (4, 7, 10): s.add('lime', line((x0, 14), (x0 + 2, 2), wd=1), mode='flat', sep=False)
    s.add('wood', rect(4, 8, 12, 9), mode='flat'); return s.render()
def ore(pal):
    s = Spr(16, 16); s.add('stone', poly((2, 13), (3, 6), (8, 3), (13, 5), (14, 12)), mode='round')
    for x, y in ((6, 7), (10, 6), (8, 10), (11, 10)): s.add(pal, ell(x, y, 1, 1), mode='round', sep=False, bias=.2)
    return s.render()

def forage(kind):
    s = Spr(16, 16)
    if kind == 'wild_onion':
        s.add('white', ell(8, 11, 3, 3), mode='round')
        for x in (6, 8, 10): s.add('lime', line((8, 9), (x, 1)), mode='flat', sep=False)
    elif kind == 'daffodil':
        s.add('green', line((8, 15), (8, 7)), mode='flat', sep=False)
        for a in ((8, 3), (5, 6), (11, 6), (6, 9), (10, 9)): s.add('yellow', ell(a[0], a[1], 2, 2), mode='round')
        s.add('orange', ell(8, 6, 1, 1), mode='round')
    elif kind == 'blackberry':
        s.add('leaf', ell(5, 4, 3, 2), mode='round')
        for x, y in ((7, 8), (10, 8), (8, 11), (11, 11), (6, 11), (9, 13)): s.add('purple', ell(x, y, 2, 2), mode='round')
    elif kind == 'chamomile':
        s.add('green', line((8, 15), (8, 8)), mode='flat', sep=False)
        for a in ((8, 3), (4, 6), (12, 6), (5, 10), (11, 10)): s.add('white', ell(a[0], a[1], 2, 2), mode='round')
        s.add('yellow', ell(8, 6, 2, 2), mode='round')
    elif kind == 'mushroom':
        s.add('cream', rect(6, 8, 10, 14), mode='cyl'); s.add('rbrown', poly((1, 9), (4, 3), (8, 2), (12, 3), (15, 9)), mode='round')
    elif kind == 'hazelnut':
        s.add('rbrown', ell(8, 10, 5, 5), mode='round'); s.add('leaf', poly((3, 6), (8, 2), (13, 6), (8, 7)), mode='round')
    elif kind == 'winter_root':
        s.add('beet', poly((4, 3), (12, 3), (9, 15), (7, 15)), mode='round')
        for y in (6, 9, 12): s.dt(P['beet'][1], line((6, y), (10, y)))
    elif kind == 'holly':
        s.add('green', poly((2, 7), (6, 3), (8, 7), (10, 3), (14, 7), (10, 11), (8, 9), (6, 11)), mode='round')
        for x, y in ((7, 10), (9, 11), (8, 12)): s.add('red', ell(x, y, 1, 1), mode='round')
    return s.render()

def food(kind):
    s = Spr(16, 16)
    s.add('white', ell(8, 11, 7, 3), mode='round')
    if kind == 'berry_snack':
        for x, y in ((6, 9), (9, 8), (10, 10), (7, 11), (8, 9)): s.add('purple', ell(x, y, 2, 2), mode='round')
    elif kind == 'mushroom_soup':
        s.add('rbrown', poly((2, 7), (14, 7), (12, 13), (4, 13)), mode='round'); s.add('sand', ell(8, 7, 6, 2), mode='flat')
        s.px(6, 7, P['rbrown'][1]); s.px(10, 7, P['rbrown'][1])
    elif kind == 'fish_soup':
        s.add('rblue', poly((2, 7), (14, 7), (12, 13), (4, 13)), mode='round'); s.add('yellow', ell(8, 7, 6, 2), mode='flat')
        s.px(6, 7, P['orange'][2]); s.px(10, 7, P['white'][4]); s.px(8, 6, P['green'][3])
    elif kind == 'veggie_stew':
        s.add('dwood', poly((2, 7), (14, 7), (12, 13), (4, 13)), mode='round'); s.add('orange', ell(8, 7, 6, 2), mode='flat')
        s.px(6, 7, P['red'][3]); s.px(10, 7, P['lime'][3]); s.px(8, 6, P['sand'][4])
    return s.render()

def coin():
    s = Spr(16, 16); s.add('gold', ell(8, 8, 6, 6), mode='round'); s.dt(P['gold'][1], ell(8, 8, 3, 3)); s.px(8, 8, P['gold'][4]); return s.render()

def scale_obj(im):
    """объект 16x32 → иконка 16x16"""
    from PIL import Image
    bb = im.getbbox(); c = im.crop(bb); w, h = c.size; k = min(14 / w, 14 / h, 1)
    c = c.resize((max(1, round(w * k)), max(1, round(h * k))), Image.NEAREST)
    o = Image.new('RGBA', (16, 16)); o.paste(c, ((16 - c.width) // 2, (16 - c.height) // 2)); return o

CROPS = ['radish', 'potato', 'strawberry', 'corn', 'tomato', 'melon', 'cabbage', 'beet', 'pumpkin']

def crop(kind, st):
    s = Spr(16, 32); b = 28
    if st == 0:
        s.add('dirt', ell(8, b, 4, 2), mode='round', bias=.15)
        for x, y in ((6, b - 1), (9, b - 1), (8, b + 1)): s.px(x, y, P['sand'][4]); s.px(x, y + 1, P['dirt'][1])
        return s.render()
    if st == 5:
        for pts in (((8, b), (5, b - 6)), ((8, b), (11, b - 5)), ((8, b), (8, b - 8))): s.add('rbrown', line(*pts), mode='flat', sep=False)
        return s.render()
    tall = kind in ('corn', 'tomato')
    if tall:
        h = [0, 5, 11, 17, 22][st]
        if kind == 'tomato' and st >= 2: s.add('wood', rect(12, b - h - 2, 13, b), mode='cyl')
        s.add('green', line((8, b), (8, b - h), wd=2), mode='flat', sep=False)
        for k in range(1, st + 1):
            y = b - k * h // (st + 1)
            s.add('green', ell(5, y, 3, 1), mode='round'); s.add('green', ell(11, y - 2, 3, 1), mode='round')
        if st == 4:
            if kind == 'corn':
                s.add('yellow', ell(10, b - 12, 2, 4), mode='round'); s.add('lime', poly((9, b - 8), (12, b - 8), (11, b - 14)), mode='flat')
                s.add('hblond', line((8, b - h), (6, b - h - 3)), mode='flat', sep=False)
            else:
                for x, y in ((5, b - 6), (10, b - 11), (6, b - 15), (10, b - 18)): s.add('red', ell(x, y, 2, 2), mode='round')
        return s.render()
    r = [0, 2, 4, 5, 6][st]
    pal = 'leaf' if kind not in ('cabbage',) else 'lime'
    if kind in ('melon', 'pumpkin') and st >= 2:
        s.add('green', ell(4, b - 2, 4, 2), mode='round'); s.add('green', ell(12, b - 3, 4, 2), mode='round')
    s.add(pal, ell(8, b - r, max(2, r), r), mode='round')
    if st >= 2 and kind not in ('cabbage',):
        s.add(pal, ell(5, b - r - 2, 2, 2), mode='round'); s.add(pal, ell(11, b - r - 1, 2, 2), mode='round')
    if st == 4:
        if kind == 'radish': s.add('pink', ell(8, b - 1, 3, 2), mode='round')
        elif kind == 'potato':
            for x in (5, 8, 11): s.px(x, b - 9, P['white'][4]); s.px(x, b - 10, P['yellow'][4])
        elif kind == 'strawberry':
            for x, y in ((4, b - 2), (9, b - 4), (12, b - 1)): s.add('red', ell(x, y, 1, 2), mode='round')
        elif kind == 'melon': s.add('lime', ell(8, b - 2, 6, 4), mode='round'); [s.dt(P['green'][1], line((x, b - 5), (x, b + 1))) for x in (5, 8, 11)]
        elif kind == 'cabbage': s.add('lime', ell(8, b - 4, 5, 4), mode='round', bias=.15)
        elif kind == 'beet': s.add('beet', ell(8, b - 1, 3, 2), mode='round')
        elif kind == 'pumpkin': s.add('orange', ell(8, b - 3, 6, 4), mode='round'); [s.dt(P['orange'][1], line((x, b - 6), (x, b))) for x in (5, 8, 11)]
    elif st == 3 and kind == 'cabbage':
        s.add('lime', ell(8, b - 4, 3, 3), mode='round', bias=.1)
    return s.render()
