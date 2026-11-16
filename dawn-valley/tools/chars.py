"""Персонажи 16x32 (4 направления × 4 кадра ходьбы + поза действия) и портреты 64x64."""
from pix import Spr, P, ell, rect, poly, line, hx

INK = hx('#1c1418')
EYEW = hx('#ffffff')

CHARS = {
 'player':  dict(hair='hbrown', style='short', shirt='teal', pants='denim', shoes='rbrown'),
 'timofey': dict(hair='hgrey', style='bald', beard=True, shirt='white', pants='rbrown', shoes='dwood', apron='apron'),
 'marfa':   dict(hair='hgrey', style='scarf', scarf='red', shirt='rbrown', dress=True, shoes='dwood', apron='white'),
 'ilya':    dict(hair='hbrown', style='beanie', hat='red', beard=True, shirt='yellow', pants='denim', shoes='dwood'),
 'anna':    dict(hair='hblond', style='long', shirt='purple', dress=True, shoes='rbrown', glasses=True),
}

def person(c, d, f):
    """d: 0 вниз, 1 влево, 2 вправо, 3 вверх. f: 0..3 ходьба, 4 — действие."""
    flip = d == 2
    if flip: d = 1
    s = Spr(16, 32)
    step = [0, 1, 0, -1, 0][f]
    bob = 1 if f in (1, 3) else 0
    act = f == 4
    hp = P[c['hair']]
    # длинные волосы сзади
    if c['style'] == 'long' and d != 3:
        s.add(c['hair'], rect(3 if d == 0 else 6, 7 + bob, 13 if d == 0 else 12, 19 + bob), mode='round')
    # ноги
    if c.get('dress'):
        s.add(c['shirt'], poly((4, 21 + bob), (12, 21 + bob), (13, 28), (3, 28)), mode='round')
        if d in (0, 3):
            s.add(c['shoes'], rect(4, 28 - (step > 0), 6, 30 - (step > 0)), mode='flat')
            s.add(c['shoes'], rect(10, 28 - (step < 0), 12, 30 - (step < 0)), mode='flat')
        else:
            s.add(c['shoes'], rect(5 + step, 28, 8 + step, 30), mode='flat'); s.add(c['shoes'], rect(8 - step, 28, 11 - step, 30), mode='flat', bias=-.2)
    else:
        if d in (0, 3):
            for x, up in ((4, step > 0), (9, step < 0)):
                s.add(c['pants'], rect(x, 22, x + 2, 28 - up), mode='cyl')
                s.add(c['shoes'], rect(x, 28 - up, x + 2, 30 - up), mode='flat')
        else:
            for x, b in ((6 - step * 2, -.2), (7 + step * 2, 0)):
                s.add(c['pants'], rect(x, 22, x + 2, 28), mode='cyl', bias=b)
                s.add(c['shoes'], rect(x - 1, 28, x + 2, 30), mode='flat', bias=b)
    # туловище
    y0 = 14 + bob
    if d in (0, 3):
        s.add(c['shirt'], poly((4, y0 + 1), (12, y0 + 1), (12, y0 + 9), (4, y0 + 9)), mode='round')
        if c.get('apron') and d == 0:
            s.add(c['apron'], rect(5, y0 + 3, 11, y0 + 12), mode='flat')
        if c['pants'] == 'denim' if not c.get('dress') else False:
            if d == 0: s.add('denim', rect(5, y0 + 5, 11, y0 + 9), mode='flat'); s.px(6, y0 + 3, P['denim'][3]); s.px(10, y0 + 3, P['denim'][3])
    else:
        s.add(c['shirt'], poly((5, y0 + 1), (11, y0 + 1), (11, y0 + 9), (5, y0 + 9)), mode='round')
        if c.get('apron'): s.add(c['apron'], rect(5, y0 + 3, 7, y0 + 12), mode='flat')
    # руки
    sw = 0 if act else step
    if d in (0, 3):
        if act and d == 0:
            s.add(c['shirt'], rect(3, y0 + 2, 5, y0 + 7), mode='cyl'); s.add(c['shirt'], rect(11, y0 + 2, 13, y0 + 7), mode='cyl')
            s.add('skin', rect(5, y0 + 7, 11, y0 + 8), mode='flat')
        else:
            s.add(c['shirt'], rect(2, y0 + 2 + sw, 4, y0 + 8 + sw), mode='cyl'); s.add(c['shirt'], rect(12, y0 + 2 - sw, 14, y0 + 8 - sw), mode='cyl')
            if d == 0 or True:
                s.add('skin', rect(2, y0 + 9 + sw, 4, y0 + 9 + sw), mode='flat'); s.add('skin', rect(12, y0 + 9 - sw, 14, y0 + 9 - sw), mode='flat')
    else:
        if act:
            s.add(c['shirt'], rect(2, y0 + 3, 8, y0 + 5), mode='cyl'); s.add('skin', rect(1, y0 + 3, 2, y0 + 5), mode='flat')
        else:
            s.add(c['shirt'], poly((7 - sw, y0 + 2), (9 - sw, y0 + 2), (9 - sw * 2, y0 + 8), (7 - sw * 2, y0 + 8)), mode='cyl')
            s.add('skin', rect(7 - sw * 2, y0 + 9, 9 - sw * 2, y0 + 9), mode='flat')
    # голова
    hy = 8 + bob
    s.add('skin', ell(8, hy + 1, 5, 5), mode='round', bias=.05)
    if d == 1: s.px(2, hy + 2, P['skin'][3]); s.px(2, hy + 3, P['skin'][2])  # нос
    st = c['style']
    if st in ('short', 'long', 'bald'):
        if st == 'bald':
            s.add(c['hair'], ell(8, hy - 1, 5, 2), mode='round', bias=.15) if False else None
            s.add(c['hair'], rect(3, hy, 4, hy + 3), mode='flat'); s.add(c['hair'], rect(12, hy, 13, hy + 3), mode='flat')
            if d == 1: s.add(c['hair'], rect(8, hy - 1, 13, hy + 4), mode='round')
            if d == 3: s.add(c['hair'], rect(3, hy + 1, 13, hy + 5), mode='round')
        else:
            if d == 0:
                s.add(c['hair'], poly((3, hy + 3), (3, hy - 2), (6, hy - 4), (11, hy - 4), (13, hy - 2), (13, hy + 3), (11, hy - 1), (7, hy), (5, hy - 1)), mode='round')
            elif d == 1:
                s.add(c['hair'], poly((4, hy - 1), (6, hy - 4), (11, hy - 4), (13, hy - 2), (13, hy + 5), (9, hy + 5), (8, hy), (5, hy)), mode='round')
            else:
                s.add(c['hair'], poly((3, hy + 5), (3, hy - 2), (6, hy - 4), (11, hy - 4), (13, hy - 2), (13, hy + 5)), mode='round')
                if st == 'long': s.add(c['hair'], rect(4, hy + 4, 12, hy + 11), mode='round')
    elif st == 'scarf':
        sc = c['scarf']
        s.add(c['hair'], rect(4, hy - 2, 12, hy - 1), mode='round')
        if d == 0: s.add(sc, poly((3, hy + 4), (3, hy - 2), (6, hy - 4), (10, hy - 4), (13, hy - 2), (13, hy + 4), (12, hy), (4, hy)), mode='round')
        elif d == 1: s.add(sc, poly((4, hy), (5, hy - 3), (10, hy - 4), (13, hy - 1), (14, hy + 6), (9, hy + 5), (9, hy)), mode='round')
        else: s.add(sc, poly((3, hy + 6), (3, hy - 2), (6, hy - 4), (10, hy - 4), (13, hy - 2), (13, hy + 6), (8, hy + 8)), mode='round')
        for x in range(4, 13, 3): s.px(x, hy - 1, P['yellow'][4])
    elif st == 'beanie':
        s.add(c['hair'], rect(3, hy, 13, hy + 3) if d != 1 else rect(8, hy, 13, hy + 4), mode='round')
        s.add(c['hat'], poly((3, hy + 1), (4, hy - 3), (8, hy - 5), (12, hy - 3), (13, hy + 1)), mode='round')
        s.add(c['hat'], rect(3, hy, 13, hy + 1), mode='flat', bias=-.2); s.add('white', ell(8, hy - 5, 1, 1), mode='round')
    # лицо
    if d == 0:
        s.pts(INK, [(6, hy + 1), (6, hy + 2), (10, hy + 1), (10, hy + 2)])
        s.px(5, hy + 3, P['pink'][3]); s.px(11, hy + 3, P['pink'][3])
        if c.get('glasses'): s.dt(P['iron'][1], line((5, hy), (7, hy)), line((9, hy), (11, hy))); s.px(8, hy + 1, P['iron'][1])
    elif d == 1:
        s.pts(INK, [(4, hy + 1), (4, hy + 2)]); s.px(5, hy + 3, P['pink'][3])
        if c.get('glasses'): s.dt(P['iron'][1], line((3, hy), (5, hy)))
        s.px(9, hy + 2, P['skin'][1])  # ухо
    if c.get('beard') and d != 3:
        bp = c['hair']
        if d == 0: s.add(bp, poly((4, hy + 3), (12, hy + 3), (11, hy + 6), (8, hy + 8), (5, hy + 6)), mode='round'); s.px(8, hy + 4, P['skin'][1])
        else: s.add(bp, poly((3, hy + 3), (9, hy + 3), (8, hy + 7), (4, hy + 7)), mode='round')
    im = s.render()
    return im.transpose(0) if flip else im

def sheet(c):
    from PIL import Image
    im = Image.new('RGBA', (16 * 5, 32 * 4))
    for d in range(4):
        for f in range(5): im.paste(person(c, d, f), (f * 16, d * 32))
    return im

def portrait(c):
    s = Spr(64, 64)
    hp = c['hair']; st = c['style']
    if st == 'long': s.add(hp, poly((14, 64), (12, 24), (20, 10), (44, 10), (52, 24), (50, 64)), mode='round')
    # плечи и одежда
    s.add(c['shirt'], poly((4, 64), (8, 50), (20, 44), (44, 44), (56, 50), (60, 64)), mode='round')
    if c.get('apron'): s.add(c['apron'], poly((20, 64), (22, 50), (42, 50), (44, 64)), mode='flat')
    if c.get('pants') == 'denim' and not c.get('dress') and not c.get('beard'):
        s.add('denim', poly((16, 64), (18, 54), (46, 54), (48, 64)), mode='flat'); s.add('gold', ell(22, 57, 1, 1), mode='round'); s.add('gold', ell(42, 57, 1, 1), mode='round')
    s.add('skin', rect(27, 38, 37, 46), mode='cyl', bias=-.15)  # шея
    s.add('skin', ell(32, 28, 14, 16), mode='round', bias=.05)
    s.add('skin', ell(18, 30, 2, 3), mode='round'); s.add('skin', ell(46, 30, 2, 3), mode='round')  # уши
    if st == 'short':
        s.add(hp, poly((16, 30), (15, 16), (22, 9), (34, 7), (44, 10), (49, 18), (48, 30), (45, 22), (38, 17), (30, 20), (22, 18), (19, 24)), mode='round')
    elif st == 'long':
        s.add(hp, poly((17, 34), (16, 16), (24, 9), (40, 9), (48, 16), (47, 34), (44, 22), (32, 16), (20, 22)), mode='round')
    elif st == 'bald':
        s.add(hp, poly((17, 32), (17, 22), (21, 20), (21, 32)), mode='round'); s.add(hp, poly((47, 32), (47, 22), (43, 20), (43, 32)), mode='round')
        s.dt(P['skin'][4], line((26, 15), (32, 13)))
    elif st == 'scarf':
        s.add(hp, poly((18, 26), (22, 16), (42, 16), (46, 26), (40, 20), (24, 20)), mode='round')
        s.add(c['scarf'], poly((14, 40), (14, 18), (22, 8), (42, 8), (50, 18), (50, 40), (46, 24), (40, 16), (24, 16), (18, 24)), mode='round')
        for x, y in ((22, 12), (30, 10), (38, 11), (46, 18), (17, 22)): s.add('yellow', ell(x, y, 1, 1), mode='round', sep=False)
    elif st == 'beanie':
        s.add(hp, poly((17, 30), (17, 20), (47, 20), (47, 30), (44, 24), (20, 24)), mode='round')
        s.add(c['hat'], poly((16, 22), (18, 10), (26, 4), (38, 4), (46, 10), (48, 22)), mode='round')
        s.add(c['hat'], rect(16, 18, 48, 23), mode='flat', bias=-.15)
        for x in range(18, 48, 3): s.dt(P[c['hat']][1], line((x, 18), (x, 23)))
        s.add('white', ell(32, 3, 3, 3), mode='round')
    # глаза
    for ex in (25, 39):
        s.add([EYEW] * 5, rect(ex - 2, 27, ex + 2, 31), mode='flat', sep=False)
        s.dt(P['hblack'][2] if c['hair'] != 'hblond' else P['teal'][1], rect(ex - 1, 27, ex + 1, 31))
        s.px(ex, 29, INK); s.px(ex - 1, 28, EYEW)
        s.dt(P[hp][0] if hp != 'hgrey' else P['hgrey'][1], line((ex - 3, 24), (ex + 2, 23) if ex < 32 else (ex + 3, 24)))
    if c.get('glasses'):
        for ex in (25, 39): s.dt(P['iron'][0], rect(ex - 4, 25, ex + 4, 25), rect(ex - 4, 33, ex + 4, 33), rect(ex - 4, 25, ex - 4, 33), rect(ex + 4, 25, ex + 4, 33))
        s.dt(P['iron'][0], line((29, 28), (35, 28)))
    s.dt(P['skin'][1], line((32, 31), (33, 35)), line((31, 36), (33, 36)))  # нос
    s.dt(P['pink'][2], line((20, 35), (22, 35)), line((42, 35), (44, 35)))
    if c.get('beard'):
        s.add(hp, poly((18, 32), (22, 40), (28, 38), (36, 38), (42, 40), (46, 32), (46, 40), (40, 50), (32, 53), (24, 50), (18, 40)), mode='round')
        s.dt(P['red'][1], line((29, 41), (35, 41)))
    else:
        s.dt(P['red'][2], line((29, 40), (35, 40))); s.px(28, 39, P['red'][2]); s.px(36, 39, P['red'][2])
    return s.render()
