"""Деревья, мелкие объекты, постройки, мебель."""
import random
from pix import Spr, P, ell, rect, poly, line, hx, RED, BLUE, YEL

LEAF = {'spring': 'leaf', 'summer': 'green', 'fall': 'fall', 'winter': None}

def oak(season):
    s = Spr(32, 48)
    s.add('dwood', poly((13, 46), (14, 28), (18, 28), (19, 46), (21, 47), (11, 47)), mode='cyl')
    s.dt(P['dwood'][1], line((15, 34), (15, 44)), line((17, 31), (17, 38)))
    if season == 'winter':
        for pts in (((16, 30), (9, 18), (6, 12)), ((16, 30), (22, 17), (26, 10)), ((16, 28), (16, 14), (14, 6)),
                    ((11, 21), (7, 20)), ((20, 22), (25, 21))):
            s.add('dwood', line(*pts, wd=2), mode='flat', sep=False)
        for x, y in ((6, 11), (14, 5), (26, 9), (9, 17), (22, 16)):
            s.add('snow', ell(x, y, 2, 1), mode='round', sep=False)
        return s.render()
    pal = LEAF[season]
    for cx, cy, rx, ry, b in ((16, 16, 13, 11, 0), (8, 22, 7, 6, -.1), (24, 21, 7, 6, -.15), (16, 9, 9, 7, .1)):
        s.add(pal, ell(cx, cy, rx, ry), mode='round', bias=b)
    r = random.Random(4)
    for _ in range(14):  # кластеры листьев: блики и тени
        x, y = r.randrange(6, 27), r.randrange(4, 26)
        s.px(x, y, P[pal][4] if y < 14 else P[pal][1], on=None)
    if season == 'spring':
        for x, y in ((10, 10), (20, 8), (25, 17), (7, 19), (15, 22), (18, 14)):
            s.px(x, y, P['bloss'][3]); s.px(x+1, y, P['bloss'][4])
    if season == 'summer':
        for x, y in ((9, 16), (22, 12), (17, 20)): s.px(x, y, RED); s.px(x, y-1, P['red'][4])
    return s.render()

def pine(season):
    s = Spr(32, 48)
    s.add('dwood', rect(14, 36, 17, 46), mode='cyl')
    pal = 'pine'
    for i, (cy, rx) in enumerate(((36, 13), (28, 11), (20, 9), (12, 6))):
        s.add(pal, poly((16-rx, cy+4), (16, cy-9), (16+rx, cy+4)), mode='round', bias=-.1+i*.05)
        if season == 'winter':
            s.add('snow', poly((16-rx+3, cy+1), (16, cy-9), (16+rx-4, cy+1)), mode='round', sep=False, bias=.2)
    s.add(pal, poly((14, 5), (16, 0), (18, 5)), mode='flat')
    return s.render()

def bush(season, berries=False):
    s = Spr(16, 16); pal = LEAF[season] or 'pine'
    s.add(pal, ell(8, 10, 7, 5), mode='round', bias=-.05)
    s.add(pal, ell(5, 8, 4, 3), mode='round'); s.add(pal, ell(11, 7, 4, 3), mode='round')
    if season == 'winter': s.add('snow', ell(8, 5, 5, 2), mode='round', sep=False)
    return s.render()

def weed(season):
    s = Spr(16, 16); pal = {'spring': 'lime', 'summer': 'green', 'fall': 'fall', 'winter': 'snow'}[season]
    for pts in (((8, 14), (4, 6)), ((8, 14), (8, 4)), ((8, 14), (12, 6)), ((8, 14), (2, 10)), ((8, 14), (14, 10))):
        s.add(pal, line(*pts, wd=2), mode='flat', sep=False)
    s.add(pal, ell(8, 13, 4, 2), mode='round')
    return s.render()

def stone_small():
    s = Spr(16, 16); s.add('stone', ell(8, 11, 6, 4), mode='round'); s.add('stone', ell(6, 9, 3, 3), mode='round', bias=.15)
    return s.render()

def twig():
    s = Spr(16, 16)
    s.add('wood', line((2, 12), (13, 8), wd=2), mode='cyl'); s.add('wood', line((8, 10), (11, 13), wd=1), mode='flat', sep=False)
    s.add('wood', line((5, 11), (4, 7), wd=1), mode='flat', sep=False)
    return s.render()

def stump():
    s = Spr(16, 16)
    s.add('dwood', poly((2, 14), (3, 6), (13, 6), (14, 14)), mode='cyl')
    s.add('lwood', ell(8, 6, 5, 2), mode='flat')
    s.dt(P['lwood'][1], ell(8, 6, 2, 1)); s.px(8, 6, P['lwood'][3])
    return s.render()

def mine_rock(kind):
    s = Spr(16, 16)
    s.add('stone', poly((2, 14), (3, 7), (7, 3), (12, 4), (14, 9), (14, 14)), mode='round', bias=-.05)
    spots = {'rock': None, 'rock2': None, 'copper': 'copper', 'iron': 'iron', 'gold': 'goldore', 'coal': None}[kind]
    if kind == 'rock2': s.add('stone', ell(9, 8, 3, 3), mode='round', bias=.15)
    if spots:
        for x, y in ((5, 8), (10, 6), (8, 11), (11, 11)):
            s.add(spots, ell(x, y, 1, 1), mode='round', sep=False, bias=.2)
            s.px(x, y-1, P[spots][4])
    return s.render()

def ladder():
    s = Spr(16, 16)
    s.add(['#0e0c14'] * 5 and [hx('#0e0c14')] * 5, ell(8, 8, 7, 6), mode='flat', sep=False)
    for x in (4, 11): s.add('wood', rect(x, 1, x+1, 14), mode='cyl')
    for y in range(3, 14, 3): s.add('lwood', rect(4, y, 12, y), mode='flat', sep=False)
    return s.render(False)

def fence():
    s = Spr(16, 16)
    s.add('wood', rect(6, 2, 9, 15), mode='cyl'); s.add('wood', poly((6, 2), (7, 0), (8, 0), (9, 2)), mode='flat')
    s.add('wood', rect(0, 5, 15, 6), mode='flat', sep=False); s.add('wood', rect(0, 10, 15, 11), mode='flat', sep=False)
    return s.render()

def sprinkler():
    s = Spr(16, 16)
    s.add('copper', ell(8, 11, 5, 3), mode='round'); s.add('iron', rect(7, 4, 9, 10), mode='cyl')
    s.add('iron', ell(8, 4, 3, 1), mode='flat'); s.px(5, 3, P['water'][4]); s.px(11, 3, P['water'][4])
    return s.render()

def path_stone():
    s = Spr(16, 16)
    for cx, cy in ((5, 5), (11, 6), (6, 11), (12, 12)): s.add('stone', ell(cx, cy, 3, 2), mode='round')
    return s.render()

def chest(open_=False):
    s = Spr(16, 32)
    s.add('wood', rect(1, 18, 14, 30), mode='flat')
    s.add('wood', poly((1, 18), (2, 13), (13, 13), (14, 18)), mode='round', bias=.1)
    for y in (22, 26): s.dt(P['wood'][1], line((2, y), (13, y)))
    s.add('gold', rect(1, 17, 14, 18), mode='flat'); s.add('gold', rect(6, 17, 9, 21), mode='round')
    s.px(7, 19, P['gold'][0]); s.add('gold', rect(1, 13, 2, 30), mode='flat', sep=False); s.add('gold', rect(13, 13, 14, 30), mode='flat', sep=False)
    return s.render()

def shipping_bin():
    s = Spr(32, 32)
    s.add('wood', poly((1, 12), (31, 12), (30, 30), (2, 30)), mode='flat')
    for y in (17, 22, 27): s.dt(P['wood'][1], line((2, y), (30, y)))
    s.add('lwood', poly((0, 13), (2, 5), (30, 5), (32, 13)), mode='round', bias=.1)
    s.dt(P['lwood'][1], line((2, 9), (30, 9)))
    s.add('metal', rect(13, 11, 18, 15), mode='round')
    s.add('rgreen', rect(5, 20, 11, 24), mode='flat'); s.px(8, 22, P['gold'][4])
    return s.render()

def bed():
    s = Spr(32, 32)
    s.add('wood', rect(1, 1, 30, 9), mode='round')
    s.add('wood', rect(1, 8, 30, 31), mode='flat')
    s.add('white', rect(4, 9, 27, 15), mode='round')
    s.add('rblue', rect(3, 15, 28, 30), mode='round')
    for x in range(5, 28, 4): s.dt(P['rblue'][1], line((x, 16), (x, 29)))
    s.dt(P['rblue'][4], line((4, 16), (27, 16)))
    return s.render()

def table():
    s = Spr(32, 32)
    s.add('lwood', rect(2, 8, 29, 19), mode='round', bias=.1)
    s.add('wood', rect(2, 19, 29, 22), mode='flat')
    for x in (3, 26): s.add('wood', rect(x, 22, x+2, 30), mode='cyl')
    s.add('white', ell(10, 12, 4, 2), mode='round'); s.add('red', ell(21, 12, 3, 3), mode='round')
    s.add('green', ell(21, 9, 2, 1), mode='flat')
    return s.render()

def stove():
    s = Spr(16, 32)
    s.add('iron', rect(1, 10, 14, 30), mode='round', bias=-.1)
    s.add('metal', rect(1, 8, 14, 11), mode='flat')
    s.add('orange', rect(4, 18, 11, 24), mode='flat'); s.dt(P['yellow'][4], line((6, 22), (9, 20)))
    s.add('iron', rect(10, 0, 12, 8), mode='cyl')
    return s.render()

def lift():
    s = Spr(16, 32)
    s.add('wood', rect(1, 4, 14, 31), mode='flat'); s.add('dwood', rect(3, 8, 12, 29), mode='flat')
    s.add('metal', rect(6, 0, 9, 6), mode='cyl'); s.add('gold', ell(8, 18, 2, 2), mode='round')
    return s.render()

# --------------------- постройки (вид 3/4 как у фермерских домов) ---------------------
def _roof(s, x0, x1, y0, y1, pal, over=2):
    r = s.add(pal, poly((x0 - over, y1), (x0 + 4, y0), (x1 - 4, y0), (x1 + over, y1)), mode='flat')
    for y in (range(y0 + 3, y1, 3) if False else range(y0 + 8, y1, 8)):  # пара линий вместо черепицы
        s.dt(P[pal][1], line((x0 - over, y), (x1 + over, y)), on=r)
    s.dt(P[pal][4], line((x0 + 4, y0 + 1), (x1 - 4, y0 + 1)), on=r)
    s.add(pal, rect(x0 - over, y1, x1 + over, y1 + 2), mode='flat', bias=-.3)

def _window(s, x, y, w=8, h=8, frame='white', shutters=None):
    s.add(frame, rect(x - 1, y - 1, x + w, y + h), mode='flat')
    s.add('water', rect(x, y, x + w - 1, y + h - 1), mode='round', bias=.2)
    s.dt(P[frame][3], line((x + w // 2, y), (x + w // 2, y + h - 1)), line((x, y + h // 2), (x + w - 1, y + h // 2)))
    s.px(x + 1, y + 1, P['water'][4]); s.px(x + 2, y + 1, P['water'][4])
    if shutters:
        s.add(shutters, rect(x - 4, y - 1, x - 2, y + h), mode='flat'); s.add(shutters, rect(x + w + 1, y - 1, x + w + 3, y + h), mode='flat')

def _door(s, x, y, w=10, h=14, pal='dwood'):
    s.add(pal, rect(x, y, x + w, y + h), mode='flat')
    for k in range(x + 2, x + w, 3): s.dt(P[pal][1], line((k, y + 1), (k, y + h - 1)))
    s.px(x + w - 2, y + h // 2, P['gold'][3])

def _plank_wall(s, x0, y0, x1, y1, pal):
    i = s.add(pal, rect(x0, y0, x1, y1), mode='flat')
    for y in range(y0 + 3, y1, 4): s.dt(P[pal][1], line((x0, y), (x1, y)), on=i)
    return i

def farmhouse():
    s = Spr(80, 80)
    s.add('stone', rect(4, 66, 75, 79), mode='flat')  # фундамент
    _plank_wall(s, 6, 40, 73, 70, 'lwood')
    s.add('brick', rect(58, 2, 66, 24), mode='cyl'); s.add('brick', rect(57, 0, 67, 3), mode='flat')
    _roof(s, 6, 73, 6, 38, 'rred', 4)
    _window(s, 13, 48, 10, 9, 'white', 'rgreen'); _window(s, 56, 48, 10, 9, 'white', 'rgreen')
    _door(s, 34, 52, 12, 18)
    s.add('wood', rect(30, 70, 50, 74), mode='flat')  # крыльцо
    s.add('lwood', rect(28, 47, 52, 49), mode='flat')
    s.add('green', ell(10, 70, 5, 3), mode='round'); s.add('green', ell(70, 70, 5, 3), mode='round')
    for x, c in ((8, 'pink'), (12, 'yellow'), (68, 'pink'), (72, 'yellow')): s.px(x, 68, P[c][3]); s.px(x, 69, P[c][4])
    return s.render()

def shop():
    s = Spr(96, 80)
    s.add('stone', rect(4, 64, 91, 79), mode='flat')
    _plank_wall(s, 6, 38, 89, 68, 'lwood')
    _roof(s, 6, 89, 6, 36, 'rgreen', 4)
    s.add('wood', rect(30, 26, 66, 36), mode='flat')  # вывеска
    s.add('lwood', rect(31, 27, 65, 35), mode='round', bias=.1)
    s.add('yellow', ell(40, 31, 3, 3), mode='round'); s.add('red', ell(48, 31, 3, 3), mode='round'); s.add('lime', ell(56, 31, 3, 3), mode='round')
    # навес в полоску
    s.add('white', poly((10, 42), (86, 42), (90, 50), (6, 50)), mode='flat')
    for x in range(8, 90, 8): s.add('red', poly((x, 42), (x + 4, 42), (x + 5, 50), (x + 1, 50)), mode='flat', sep=False)
    _window(s, 12, 53, 16, 10, 'white'); _window(s, 68, 53, 16, 10, 'white')
    _door(s, 42, 54, 12, 14, 'rgreen')
    for x, c in ((14, 'orange'), (22, 'red'), (74, 'lime'), (82, 'yellow')):  # ящики с товаром
        s.add('wood', rect(x - 3, 70, x + 3, 77), mode='flat'); s.add(c, ell(x, 70, 3, 2), mode='round')
    return s.render()

def house(roof='rblue', wallp='lwood', variant=0):
    s = Spr(80, 80)
    s.add('stone', rect(4, 66, 75, 79), mode='flat')
    if variant == 1:
        i = s.add('brick', rect(6, 40, 73, 70), mode='flat')
        for y in range(43, 70, 4):
            s.dt(P['brick'][1], line((6, y), (73, y)), on=i)
            for x in range(6 + (y % 8), 73, 8): s.px(x, y - 1, P['brick'][1], on=i); s.px(x, y - 2, P['brick'][1], on=i)
    else:
        _plank_wall(s, 6, 40, 73, 70, wallp)
    _roof(s, 6, 73, 8, 38, roof, 4)
    s.add('stone', rect(14, 0, 21, 20), mode='cyl')
    _window(s, 12, 48, 10, 9, 'white', 'rbrown'); _window(s, 58, 48, 10, 9, 'white', 'rbrown')
    _door(s, 34, 52, 12, 18, 'rbrown')
    s.add('wood', rect(30, 70, 50, 74), mode='flat')
    return s.render()

def school():
    s = Spr(96, 96)
    s.add('stone', rect(4, 80, 91, 95), mode='flat')
    i = s.add('brick', rect(6, 54, 89, 86), mode='flat')
    for y in range(57, 86, 4): s.dt(P['brick'][1], line((6, y), (89, y)), on=i)
    _roof(s, 6, 89, 24, 52, 'rbrown', 4)
    s.add('white', rect(40, 4, 56, 30), mode='flat')  # башенка с колоколом
    s.add('rbrown', poly((37, 8), (48, 0), (59, 8)), mode='flat')
    s.add('dwood', rect(44, 12, 52, 22), mode='flat'); s.add('gold', poly((46, 20), (48, 14), (50, 20)), mode='round')
    for x in (12, 30, 58, 76): _window(s, x, 62, 9, 11, 'white')
    _door(s, 42, 66, 12, 20, 'rred')
    s.add('wood', rect(36, 86, 60, 90), mode='flat')
    return s.render()

def mill(fixed):
    s = Spr(80, 112)
    s.add('stone', rect(18, 98, 61, 111), mode='flat')
    body = s.add('stone' if not fixed else 'cream', poly((20, 102), (24, 40), (56, 40), (60, 102)), mode='cyl')
    if not fixed:
        for x, y in ((28, 60), (46, 76), (34, 88)): s.add('dirt', ell(x, y, 3, 2), mode='flat', sep=False)
    for y in range(48, 100, 8): s.dt(P['stone'][2] if not fixed else P['cream'][1], line((22, y), (58, y)), on=body)
    s.add('rbrown' if fixed else 'dwood', poly((16, 42), (40, 14), (64, 42)), mode='round')
    if not fixed: s.cut(poly((44, 22), (52, 30), (46, 34)))
    _window(s, 36, 52, 8, 10, 'wood')
    _door(s, 34, 84, 12, 18, 'wood')
    if not fixed: s.add('wood', line((32, 86), (48, 98), wd=2), mode='flat', sep=False); s.add('wood', line((48, 86), (32, 98), wd=2), mode='flat', sep=False)
    # крылья
    hub = (40, 34)
    blades = [((40, 34), (40, 0)), ((40, 34), (74, 34)), ((40, 34), (40, 68)), ((40, 34), (6, 34))] if fixed else \
             [((40, 34), (44, 6)), ((40, 34), (66, 46))]
    for a, b in blades:
        s.add('wood', line(a, b, wd=2), mode='flat', sep=False)
        if fixed:
            dx, dy = (b[0] - a[0]) / 34, (b[1] - a[1]) / 34
            nx, ny = -dy, dx
            p = [(a[0] + dx * k + nx * o, a[1] + dy * k + ny * o) for k, o in ((8, 1), (33, 1), (33, 8), (8, 8))]
            s.add('cream', poly(*p), mode='flat')
            for k in (14, 20, 26): s.dt(P['wood'][1], line((a[0] + dx * k + nx, a[1] + dy * k + ny), (a[0] + dx * k + nx * 8, a[1] + dy * k + ny * 8)))
    s.add('dwood', ell(hub[0], hub[1], 3, 3), mode='round')
    return s.render()

def mine_entrance():
    s = Spr(64, 64)
    s.add('stone', poly((0, 63), (2, 20), (14, 6), (32, 2), (50, 6), (62, 20), (63, 63)), mode='round', bias=-.05)
    for x, y in ((12, 20), (50, 22), (30, 10), (8, 42), (56, 44)): s.add('stone', ell(x, y, 5, 4), mode='round', bias=.1)
    s.add([hx('#0e0c14')] * 5, poly((18, 63), (18, 34), (24, 26), (40, 26), (46, 34), (46, 63)), mode='flat', sep=False)
    s.add('wood', rect(16, 26, 20, 63), mode='cyl'); s.add('wood', rect(44, 26, 48, 63), mode='cyl')
    s.add('wood', rect(14, 23, 50, 27), mode='flat')
    s.add('lwood', rect(24, 14, 40, 20), mode='flat'); s.dt(P['dwood'][1], line((27, 17), (37, 17)))
    return s.render()

def dock_post():
    s = Spr(16, 16); s.add('dwood', rect(6, 2, 9, 15), mode='cyl'); s.add('lwood', ell(7, 2, 2, 1), mode='flat')
    return s.render()

def lamp():
    s = Spr(16, 32)
    s.add('iron', rect(7, 8, 8, 31), mode='cyl'); s.add('iron', rect(4, 29, 11, 31), mode='flat')
    s.add('iron', poly((4, 3), (11, 3), (10, 10), (5, 10)), mode='flat'); s.add('yellow', rect(5, 4, 10, 9), mode='glow', sep=False)
    return s.render()

def well():
    s = Spr(32, 48)
    s.add('stone', ell(16, 38, 13, 7), mode='round'); s.add([hx('#0e0c14')] * 5, ell(16, 36, 9, 4), mode='flat', sep=False)
    for x in (4, 26): s.add('wood', rect(x, 12, x + 2, 38), mode='cyl')
    s.add('rred', poly((0, 16), (16, 2), (32, 16)), mode='flat'); s.add('dwood', rect(6, 20, 26, 21), mode='flat', sep=False)
    s.add('wood', rect(14, 22, 18, 28), mode='flat')
    return s.render()

def bench():
    s = Spr(32, 16)
    s.add('wood', rect(1, 3, 30, 6), mode='flat'); s.add('wood', rect(1, 8, 30, 11), mode='flat')
    for x in (3, 27): s.add('iron', rect(x, 6, x + 2, 15), mode='flat')
    return s.render()

def flowerbed(season):
    s = Spr(32, 16)
    s.add('wood', rect(0, 6, 31, 15), mode='flat'); s.add('dirt', rect(2, 6, 29, 9), mode='flat')
    if season != 'winter':
        for i, x in enumerate(range(4, 29, 4)):
            c = ['red', 'yellow', 'pink', 'purple'][i % 4] if season != 'fall' else ['orange', 'fall', 'yellow', 'red'][i % 4]
            s.add('green', line((x, 7), (x, 3)), mode='flat', sep=False); s.add(c, ell(x, 3, 1, 1), mode='round', sep=False)
    else:
        s.add('snow', rect(1, 4, 30, 7), mode='round')
    return s.render()
