"""Все спрайты игры. Запуск: python build_assets.py"""
import random
from pix import Spr, P, RED, BLUE, YEL, ell, rect, poly, line, hx

# ---------------- ТАЙЛЫ 16x16 ----------------
def _noise_tile(base, dots, seed):
    s = Spr(16, 16); s.add(base, rect(0, 0, 15, 15), mode='flat', sep=False)
    s.img[:, :] = P[base][2]
    r = random.Random(seed)
    for col, n in dots:
        for _ in range(n): s.px(r.randrange(16), r.randrange(16), col)
    return s

def t_grass(seed=1, flowers=False):
    s = _noise_tile('leaf', [], seed); r = random.Random(seed)
    g = P['leaf']
    for _ in range(10):  # травинки: тёмное основание + светлый кончик
        x, y = r.randrange(1, 15), r.randrange(2, 15)
        s.px(x, y, g[1]); s.px(x, y-1, g[3])
        if r.random() < .5: s.px(x+1, y-1, g[1]); s.px(x+1, y-2, g[4])
    if flowers:
        for c in (YEL, hx('#f6f0e4'), YEL):
            x, y = r.randrange(2, 14), r.randrange(2, 14)
            s.px(x, y, c); s.px(x, y+1, g[1])
    return s.render(False)

def t_taiga(seed=5):
    s = Spr(16, 16); s.img[:, :] = hx('#2a4a30'); r = random.Random(seed)
    for _ in range(14):
        x, y = r.randrange(16), r.randrange(16)
        s.px(x, y, r.choice([P['leaf'][1], P['sod'][2], P['leaf'][0]]))
    for _ in range(4):
        x, y = r.randrange(1, 15), r.randrange(1, 15); s.px(x, y, P['leaf'][3])
    return s.render(False)

def t_path(seed=2):
    s = Spr(16, 16); s.img[:, :] = P['clay'][3]; r = random.Random(seed)
    for _ in range(18):
        x, y = r.randrange(16), r.randrange(16); s.px(x, y, r.choice(P['clay'][1:3]))
    for _ in range(4):
        x, y = r.randrange(15), r.randrange(15)
        s.px(x, y, P['stone'][3]); s.px(x+1, y, P['stone'][2]); s.px(x, y+1, P['clay'][1])
    for _ in range(4):
        x, y = r.randrange(16), r.randrange(16); s.px(x, y, P['clay'][4])
    return s.render(False)

def t_soil(wet=False):
    pal = P['sod']
    s = Spr(16, 16); s.img[:, :] = pal[1] if wet else pal[2]
    for y in (3, 8, 13):  # борозды
        for x in range(1, 15):
            s.px(x, y, pal[0] if wet else pal[1]); s.px(x, y-1, pal[2] if wet else pal[3])
    r = random.Random(7)
    for _ in range(8):
        s.px(r.randrange(16), r.randrange(16), pal[0] if wet else pal[4])
    if wet:
        for x, y in ((3, 5), (10, 10), (12, 4)): s.px(x, y, hx('#5a6a8a'))
    return s.render(False)

def t_water(frame=0):
    s = Spr(16, 16); w = P['water']; s.img[:, :] = w[2]
    r = random.Random(11)
    for _ in range(6):
        x, y = r.randrange(14), r.randrange(16)
        x = (x + frame*2) % 14
        s.px(x, y, w[3]); s.px(x+1, y, w[3]); s.px(x+2, y, w[4] if r.random() < .4 else w[3])
    for _ in range(5): s.px(r.randrange(16), r.randrange(16), w[1])
    return s.render(False)

def t_shore():  # трава сверху, вода снизу — берег
    s = Spr(16, 16); w = P['water']; s.img[:, :] = w[2]
    for x in range(16):
        h = 5 + (x*7 % 3)
        for y in range(h): s.px(x, y, P['leaf'][2])
        s.px(x, h, P['clay'][3]); s.px(x, h+1, P['clay'][2]); s.px(x, h+2, w[1])
    s.px(4, 2, P['leaf'][3]); s.px(11, 1, P['leaf'][3]); s.px(8, 3, P['leaf'][1])
    return s.render(False)

def t_sand():
    s = Spr(16, 16); s.img[:, :] = P['clay'][4]; r = random.Random(3)
    for _ in range(16): s.px(r.randrange(16), r.randrange(16), r.choice(P['clay'][2:4]))
    return s.render(False)

def t_floor():  # пол балагана — тёсаные плахи
    s = Spr(16, 16); s.img[:, :] = P['wood'][2]
    for y in range(16):
        s.px(0, y, P['wood'][1]); s.px(8, y, P['wood'][1]); s.px(1, y, P['wood'][3]); s.px(9, y, P['wood'][3])
    for x, y in ((4, 3), (12, 9), (5, 12), (13, 2)):
        s.px(x, y, P['wood'][1]); s.px(x, y+1, P['wood'][1])
    return s.render(False)

def TILES():
    return [t_grass(1), t_grass(2, True), t_path(), t_soil(), t_soil(True),
            t_water(0), t_shore(), t_taiga(), t_sand(), t_water(1), t_floor(), t_grass(9)]

# ---------------- ПРЕДМЕТЫ 16x16 ----------------
def i_choron():
    s = Spr(16, 16)
    s.add('wood', poly((4, 4), (12, 4), (11, 11), (5, 11)), mode='cyl')
    s.add('wood', rect(4, 3, 12, 4), mode='flat')
    s.add('cream', ell(8, 3, 3, 1), mode='flat')
    for x, c in ((6, RED), (8, BLUE), (10, RED)): s.px(x, 7, c)
    s.dt(P['wood'][0], line((5, 6), (11, 6)))
    for x in (5, 7, 9, 11):  # три ножки
        pass
    s.add('wood', rect(5, 11, 6, 13), mode='flat'); s.add('wood', rect(10, 11, 11, 13), mode='flat')
    s.add('wood', rect(7, 11, 9, 12), mode='flat')
    return s.render()

def i_khomus():
    s = Spr(16, 16)
    s.add('metal', ell(6, 7, 4, 4), mode='round'); s.cut(ell(6, 7, 2, 2))
    s.add('metal', poly((8, 8), (14, 13), (13, 14), (7, 9)), mode='flat')
    s.dt(P['gold'][3], line((7, 8), (14, 14)))
    s.px(14, 14, P['gold'][4]); s.px(4, 4, P['metal'][4])
    return s.render()

def i_stroganina():
    s = Spr(16, 16)
    s.add('wclay', ell(8, 10, 7, 4), mode='round')
    for i, x in enumerate((4, 7, 10)):
        s.add('ice', poly((x, 4+i), (x+3, 3+i), (x+4, 11), (x+1, 12)), mode='round', bias=.2)
        s.add('cream', line((x+1, 5+i), (x+2, 10), wd=1), mode='flat', sep=False)
    return s.render()

def i_brusnika():
    s = Spr(16, 16)
    s.add('leaf', ell(5, 5, 3, 2), mode='round'); s.add('leaf', ell(11, 4, 3, 2), mode='round')
    for cx, cy in ((5, 10), (9, 9), (11, 12), (7, 13)):
        s.add('berry', ell(cx, cy, 2, 2), mode='round')
    s.dt(P['leaf'][0], line((8, 3), (8, 8)))
    return s.render()

def _fish(body, fin, slim=False):
    s = Spr(16, 16)
    ry = 3 if slim else 4
    s.add(fin, poly((1, 4), (4, 8), (1, 12)), mode='flat')
    s.add(body, ell(8, 8, 6, ry), mode='round')
    s.add(fin, poly((7, 8-ry), (10, 8-ry-2), (11, 8-ry+1)), mode='flat')
    for x in range(5, 12, 2):  # чешуя
        for y in range(8-ry+2, 8+ry-1, 2): s.px(x, y, s.mats[2][1] if False else P[body][1], on=2)
    s.px(12, 7, hx('#1a1a20')); s.px(12, 6, P[body][4])
    return s.render()

def i_karas(): return _fish('gold', 'berry')
def i_chir():  return _fish('silver', 'metal', True)

def i_kerchekh():
    s = Spr(16, 16)
    s.add('wood', poly((2, 8), (14, 8), (12, 14), (4, 14)), mode='round')
    s.add('cream', ell(8, 8, 6, 3), mode='round', bias=.3)
    for x, y in ((6, 7), (9, 6), (10, 8), (7, 9)): s.px(x, y, P['berry'][2]); s.px(x, y-1, P['berry'][4])
    s.dt(P['wood'][1], line((4, 11), (12, 11)))
    return s.render()

def i_alaadyi():
    s = Spr(16, 16)
    s.add('wclay', ell(8, 11, 7, 3), mode='round')
    for cy in (10, 8, 6):
        s.add('burl', ell(8, cy, 5, 2), mode='round')
    s.add('cream', ell(8, 5, 2, 1), mode='flat')
    return s.render()

def i_bivень():
    s = Spr(16, 16)
    s.add('cream', line((2, 13), (5, 9), (9, 6), (13, 5), (14, 2), wd=3), mode='cyl')
    s.add('cream', line((13, 5), (14, 2), wd=2), mode='flat', bias=.2)
    for x, y in ((5, 10), (8, 7), (11, 6)): s.px(x, y, P['clay'][1])
    return s.render()

def i_torbasa():
    s = Spr(16, 16)
    s.add('fur', poly((4, 2), (10, 2), (10, 10), (14, 11), (14, 14), (4, 14)), mode='round')
    s.add('rcloth', rect(4, 4, 10, 5), mode='flat')
    for x in range(5, 10, 2): s.px(x, 4, YEL); s.px(x+1, 5, BLUE)
    s.add('wfur', rect(4, 1, 10, 2), mode='round')
    s.dt(P['fur'][1], line((4, 12), (14, 12)))
    return s.render()

def i_knife():
    s = Spr(16, 16)
    s.add('silver', poly((7, 9), (13, 2), (14, 3), (9, 10)), mode='flat')  # асимметричный клинок
    s.dt(P['silver'][4], line((8, 8), (13, 3)))
    s.add('burl', poly((3, 12), (7, 9), (9, 11), (5, 14)), mode='round')  # рукоять из капа
    s.dt(P['burl'][1], line((5, 11), (7, 12)))
    return s.render()

def i_ice():
    s = Spr(16, 16)
    s.add('ice', poly((3, 5), (8, 2), (13, 4), (13, 11), (8, 14), (3, 11)), mode='round')
    s.dt(P['ice'][4], line((5, 5), (8, 3)), line((5, 7), (6, 6)))
    s.dt(P['ice'][1], line((8, 8), (11, 11)))
    return s.render()

def i_hoe():
    s = Spr(16, 16)
    s.add('wood', line((3, 14), (12, 3), wd=2), mode='cyl')
    s.add('metal', poly((10, 2), (15, 4), (14, 7), (11, 5)), mode='round')
    return s.render()

def i_can():
    s = Spr(16, 16)
    s.add('metal', rect(3, 6, 11, 13), mode='cyl')
    s.add('metal', poly((11, 8), (15, 4), (15, 6), (11, 11)), mode='flat')
    s.add('metal', line((4, 6), (7, 2), (10, 6)), mode='flat', sep=False)
    s.dt(P['water'][3], line((4, 8), (10, 8)))
    return s.render()

def i_rod():
    s = Spr(16, 16)
    s.add('birch', line((2, 14), (13, 2), wd=2), mode='cyl')
    s.add('dwood', ell(5, 11, 2, 2), mode='round')
    s.dt(hx('#eef3f8'), line((13, 2), (14, 8)))
    s.px(14, 9, RED)
    return s.render()

def _seeds(c):
    s = Spr(16, 16)
    s.add('birch', poly((3, 4), (13, 4), (12, 14), (4, 14)), mode='round')  # берестяной туесок
    s.add('birch', rect(3, 3, 13, 5), mode='flat')
    for x in range(4, 13, 2): s.px(x, 9, RED); s.px(x+1, 9, BLUE)
    s.add(c, ell(8, 3, 3, 1), mode='flat', sep=False)
    return s.render()

def i_potato():
    s = Spr(16, 16); s.add('clay', ell(8, 9, 5, 4), mode='round')
    for x, y in ((6, 8), (10, 10), (8, 11)): s.px(x, y, P['clay'][1])
    return s.render()

def i_barley():
    s = Spr(16, 16)
    for dx in (-2, 0, 2):
        s.add('gold', line((8+dx, 14), (8+dx*2, 3), wd=1), mode='flat', sep=False)
        s.add('gold', ell(8+dx*2, 4, 1, 3), mode='round')
    s.dt(P['gold'][4], line((6, 1), (5, 0)), line((10, 1), (11, 0)))
    return s.render()

def i_turnip():
    s = Spr(16, 16)
    s.add('leaf', poly((6, 1), (8, 6), (10, 1), (12, 3), (9, 7), (7, 7), (4, 3)), mode='round')
    s.add('wclay', ell(8, 10, 4, 4), mode='round')
    s.add('berry', ell(8, 8, 4, 2), mode='round', bias=.2, on=None)
    s.dt(P['wclay'][1], line((8, 14), (8, 15)))
    return s.render()

def i_kumys():  # кумыс в чороне уже есть; бочонок-кытыйа — ковш
    s = Spr(16, 16)
    s.add('dwood', ell(8, 9, 5, 4), mode='round')
    s.add('cream', ell(8, 8, 4, 2), mode='flat')
    s.add('dwood', poly((12, 7), (15, 3), (15, 5), (13, 9)), mode='flat')
    s.px(6, 11, RED); s.px(8, 12, BLUE); s.px(10, 11, RED)
    return s.render()

ITEMS = [  # индекс = номер кадра в items.png
    ('choron', i_choron), ('khomus', i_khomus), ('stroganina', i_stroganina), ('brusnika', i_brusnika),
    ('karas', i_karas), ('chir', i_chir), ('kerchekh', i_kerchekh), ('alaadyi', i_alaadyi),
    ('mammoth', i_bivень), ('torbasa', i_torbasa), ('knife', i_knife), ('ice', i_ice),
    ('hoe', i_hoe), ('can', i_can), ('rod', i_rod),
    ('seed_potato', lambda: _seeds('clay')), ('seed_barley', lambda: _seeds('gold')), ('seed_turnip', lambda: _seeds('berry')),
    ('potato', i_potato), ('barley', i_barley), ('turnip', i_turnip), ('kytyya', i_kumys),
]

# ---------------- КУЛЬТУРЫ 16x32, 5 стадий ----------------
def crop(kind, st):
    s = Spr(16, 32); b = 29
    if st == 0:
        for x in (6, 9): s.px(x, b, P['sod'][4]); s.px(x+1, b-1, P['sod'][3])
        return s.render(False)
    if kind == 'barley':
        h = [0, 4, 9, 14, 16][st]
        for dx in (-3, 0, 3):
            s.add('leaf' if st < 4 else 'gold', line((8+dx, b), (8+dx+(dx//3), b-h), wd=1), mode='flat', sep=False)
            if st >= 3: s.add('gold' if st == 4 else 'leaf', ell(8+dx+(dx//3), b-h, 1, 3), mode='round')
        return s.render()
    h = [0, 3, 6, 8, 9][st]
    s.add('leaf', ell(8, b-h//2-1, 2+st, 1+h//2), mode='round')
    if st >= 2:
        s.add('leaf', ell(5, b-h+2, 2, 2), mode='round'); s.add('leaf', ell(11, b-h+1, 2, 2), mode='round')
    if st == 4:
        if kind == 'turnip':
            s.add('wclay', ell(8, b, 3, 2), mode='round'); s.add('berry', ell(8, b-1, 3, 1), mode='flat', sep=False)
        else:
            for x in (5, 8, 11): s.px(x, b-h+1, hx('#f6f0e4')); s.px(x, b-h, YEL)  # цветы картофеля
    return s.render()

CROPS = ['potato', 'barley', 'turnip']

# ---------------- ДЕРЕВЬЯ / КУСТЫ ----------------
def larch():  # лиственница 32x48
    s = Spr(32, 48)
    s.add('dwood', rect(14, 30, 17, 46), mode='cyl')
    for i, (cy, rx) in enumerate(((34, 12), (27, 11), (20, 9), (13, 7), (7, 4))):
        s.add('leaf', poly((16-rx, cy+4), (16, cy-6), (16+rx, cy+4)), mode='round', bias=-.1+i*.04)
    s.add('leaf', poly((14, 4), (16, 0), (18, 4)), mode='flat')
    return s.render()

def birch_tree():
    s = Spr(32, 48)
    s.add('birch', rect(14, 22, 17, 46), mode='cyl')
    for y in (26, 31, 36, 41): s.dt(P['birch'][0], line((14, y), (15, y)))  # чечевички
    s.dt(P['birch'][0], line((16, 33), (17, 33)), line((16, 44), (17, 44)))
    s.add('leaf', ell(16, 14, 11, 10), mode='round', bias=.05)
    s.add('leaf', ell(10, 20, 6, 5), mode='round'); s.add('leaf', ell(22, 19, 6, 5), mode='round', bias=-.1)
    return s.render()

def bush(berries):
    s = Spr(16, 16)
    s.add('leaf', ell(8, 10, 7, 5), mode='round', bias=-.05)
    s.add('leaf', ell(5, 8, 3, 3), mode='round'); s.add('leaf', ell(11, 8, 3, 3), mode='round')
    if berries:
        for x, y in ((4, 10), (7, 12), (10, 10), (12, 12), (8, 8), (6, 7)):
            s.px(x, y, P['berry'][2]); s.px(x, y-1, P['berry'][4])
    return s.render()

def rock():
    s = Spr(16, 16)
    s.add('stone', ell(8, 10, 6, 4), mode='round'); s.add('stone', ell(6, 8, 3, 3), mode='round', bias=.1)
    return s.render()

# ---------------- ПОСТРОЙКИ ----------------
def balagan():  # 64x64, вид 3/4 сверху
    s = Spr(64, 64)
    # наклонные стены из жердей, обмазанные глиной (фасад)
    wall = s.add('clay', poly((6, 30), (58, 30), (61, 60), (3, 60)), mode='flat')
    for x in range(8, 58, 5): s.dt(P['clay'][2], line((x, 31), (x-2+x//20, 59)), on=wall)
    for y in (38, 47, 55): s.dt(P['clay'][4], line((6, y), (20, y)), on=wall)
    # плоская дерновая крыша с травой
    s.add('sod', poly((2, 10), (62, 10), (62, 31), (2, 31)), mode='flat')
    s.add('sod', rect(2, 28, 62, 31), mode='flat', bias=-.25)
    g = s.add('leaf', poly((3, 6), (61, 6), (61, 24), (3, 24)), mode='round', bias=.05)
    for x in range(4, 61, 3):
        s.px(x, 24+(x % 2), P['leaf'][2]); s.px(x, 25+(x % 2), P['leaf'][1])
        s.px(x+1, 8+(x*5 % 13), P['leaf'][4], on=g); s.px(x, 9+(x*5 % 13), P['leaf'][1], on=g)
    # труба камелька
    s.add('wclay', rect(46, 0, 51, 12), mode='cyl'); s.add('wclay', rect(45, 0, 52, 2), mode='flat')
    s.dt(hx('#3a3036'), rect(47, 0, 50, 0))
    # дверь
    s.add('dwood', rect(27, 40, 37, 60), mode='flat')
    for x in (29, 32, 35): s.dt(P['dwood'][1], line((x, 41), (x, 59)))
    s.px(35, 50, P['gold'][3])
    s.add('wood', rect(25, 37, 39, 39), mode='flat')
    # окна из льдин
    for x in (10, 46):
        s.add('wood', rect(x-1, 39, x+9, 49), mode='flat')
        s.add('ice', rect(x, 40, x+8, 48), mode='round', bias=.1)
        s.dt(P['ice'][4], line((x+1, 41), (x+3, 41)), line((x+1, 42), (x+1, 43)))
    return s.render()

def urasa():  # 48x64 берестяной конус
    s = Spr(48, 64)
    for x0, x1 in ((20, 14), (24, 24), (28, 34)):
        s.add('dwood', line((x0, 10), (x1, 0), wd=2), mode='flat', sep=False)
    cone = s.add('birch', poly((24, 4), (46, 62), (2, 62)), mode='round')
    for k, y in enumerate(range(16, 60, 8)):  # горизонтальные швы бересты
        w = (y-4)*22//58
        s.dt(P['birch'][1], line((24-w, y), (24+w, y)), on=cone)
        for x in range(24-w+2, 24+w-1, 4):
            s.px(x, y+2, P['birch'][0], on=cone)  # чечевички
    for y, cols in ((30, (RED, BLUE)), (48, (BLUE, RED))):  # орнаментные пояса
        w = (y-4)*22//58
        for x in range(24-w+1, 24+w, 2):
            s.px(x, y-1, cols[0], on=cone); s.px(x, y, YEL, on=cone); s.px(x+1, y+1, cols[1], on=cone)
    s.add('fur', poly((19, 62), (24, 40), (29, 62)), mode='round')  # меховой полог
    s.dt(P['fur'][1], line((24, 44), (24, 62)))
    return s.render()

def serge():  # коновязь 16x32
    s = Spr(16, 32)
    p = s.add('wood', rect(6, 6, 9, 31), mode='cyl')
    s.add('wood', ell(8, 4, 3, 3), mode='round')  # навершие-ковш
    s.add('wood', poly((5, 3), (8, 0), (11, 3)), mode='round')
    for y in (10, 16, 22):  # резные пояса
        s.dt(P['wood'][0], line((6, y), (9, y)), on=p); s.dt(P['wood'][4], line((6, y+1), (9, y+1)), on=p)
        s.dt(P['wood'][1], line((6, y+3), (9, y+3)), on=p)
    s.dt(P['wood'][0], line((6, 26), (9, 29)), on=p)
    return s.render()

def kamelyok(frame=0):  # глинобитный очаг 16x32
    s = Spr(16, 32)
    s.add('wclay', rect(5, 0, 10, 14), mode='cyl')
    s.add('wclay', poly((2, 13), (13, 13), (14, 31), (1, 31)), mode='round')
    s.add('dwood', ell(8, 23, 4, 5), mode='flat')
    f = ((8, 19), (7, 20), (9, 18)) [frame % 3]
    s.add('fire', poly((4, 28), (f[0], f[1]), (12, 28)), mode='glow')
    s.add('fire', poly((6, 28), (8, 22+frame % 2), (10, 28)), mode='glow', bias=.4, sep=False)
    s.add('wood', rect(4, 28, 12, 29), mode='flat')
    return s.render()

def ampaar():  # амбар-ящик для продажи 32x32
    s = Spr(32, 32)
    s.add('wood', poly((2, 10), (30, 10), (30, 29), (2, 29)), mode='flat')
    for y in (14, 19, 24): s.dt(P['wood'][1], line((3, y), (29, y)))
    s.add('dwood', poly((0, 11), (16, 2), (32, 11), (32, 13), (0, 13)), mode='round')
    s.add('wood', rect(13, 16, 19, 22), mode='flat')
    s.dt(P['gold'][3], rect(15, 18, 17, 20))
    for x in range(4, 29, 3): s.px(x, 27, RED if x % 2 else BLUE)
    return s.render()

def bed():
    s = Spr(16, 32)
    s.add('wood', rect(1, 2, 14, 30), mode='flat')
    s.add('fur', rect(2, 10, 13, 29), mode='round')
    s.add('wfur', rect(3, 3, 12, 9), mode='round')
    for x in range(3, 13, 2): s.px(x, 12, RED); s.px(x+1, 13, YEL)
    return s.render()

# ---------------- ПЕРСОНАЖИ 16x32 ----------------
def person(dirn, frame, kind='player'):
    """dirn: 0 вниз, 1 влево, 2 вправо, 3 вверх; frame 0..3 (0,2 — стойка)"""
    s = Spr(16, 32)
    flip = dirn == 2
    d = 1 if dirn == 2 else dirn
    leg = [0, 1, 0, -1][frame]
    coat = 'cloth' if kind == 'player' else 'fur'
    trim = 'wfur' if kind == 'player' else 'wfur'
    # ноги в торбасах
    if d in (0, 3):
        s.add('fur', rect(5, 25-max(0, leg), 7, 30-max(0, leg)), mode='flat')
        s.add('fur', rect(9, 25-max(0, -leg), 11, 30-max(0, -leg)), mode='flat')
    else:
        s.add('fur', rect(6+leg, 25, 8+leg, 30), mode='flat'); s.add('fur', rect(8-leg, 25, 10-leg, 30), mode='flat', bias=-.2)
    # кафтан
    body = s.add(coat, poly((4, 14), (12, 14), (13, 26), (3, 26)), mode='round')
    s.add(trim, rect(3, 25, 13, 26), mode='flat')
    if kind != 'player':
        for x in range(4, 13, 2): s.px(x, 24, RED, on=body); s.px(x+1, 24, YEL, on=body)
    else:
        s.dt(P['gold'][3], line((8, 15), (8, 24)), on=body)
        s.px(8, 18, P['gold'][4]); s.px(8, 21, P['gold'][4])
    # руки
    sw = [0, 1, 0, -1][frame]
    if d in (0, 3):
        s.add(coat, rect(2, 15+sw, 4, 22+sw), mode='cyl'); s.add(coat, rect(12, 15-sw, 14, 22-sw), mode='cyl')
        s.add('skin', rect(2, 22+sw, 4, 23+sw), mode='flat'); s.add('skin', rect(12, 22-sw, 14, 23-sw), mode='flat')
    else:
        s.add(coat, rect(6+sw, 15, 9+sw, 22), mode='cyl'); s.add('skin', rect(6+sw, 22, 9+sw, 23), mode='flat')
    # голова
    s.add('skin', ell(8, 9, 4, 5), mode='round')
    hat = s.add('wfur' if kind == 'player' else 'fur', ell(8, 5, 5, 4), mode='round')
    s.cut(rect(0, 9, 15, 9)) if False else None
    if kind == 'player':
        s.add('rcloth', rect(4, 1, 12, 3), mode='round')   # шапка с красным верхом
        s.px(8, 0, YEL)
    else:
        s.add('silver', rect(4, 6, 12, 7), mode='flat')  # серебряный налобник
        s.px(8, 6, BLUE)
    eye = hx('#1c1412')
    if d == 0:
        s.px(6, 10, eye); s.px(10, 10, eye); s.px(8, 12, P['skin'][1])
        if kind != 'player':  # борода сказителя
            s.add('cream', poly((5, 12), (11, 12), (8, 17)), mode='round')
    elif d == 1:
        s.px(5, 10, eye); s.px(4, 12, P['skin'][1])
        if kind != 'player': s.add('cream', poly((3, 12), (8, 12), (5, 17)), mode='round')
    else:
        s.add('mane' if kind == 'player' else 'cream', ell(8, 10, 4, 3), mode='round')
    im = s.render()
    if flip: im = im.transpose(0)
    return im

def portrait():  # олонхосут 64x64
    s = Spr(64, 64)
    s.add('fur', poly((6, 64), (12, 44), (52, 44), (58, 64)), mode='round')
    for x in range(10, 56, 3): s.px(x, 60, RED); s.px(x+1, 61, YEL); s.px(x+2, 60, BLUE)
    s.add('skin', ell(32, 30, 14, 17), mode='round')
    s.add('fur', ell(32, 14, 18, 10), mode='round')
    s.add('wfur', rect(13, 18, 51, 22), mode='round')
    s.add('silver', rect(18, 20, 46, 22), mode='flat')
    s.px(32, 21, BLUE); s.px(31, 21, RED); s.px(33, 21, RED)
    s.add('cream', poly((20, 38), (44, 38), (40, 54), (32, 60), (24, 54)), mode='round')
    s.dt(P['cream'][1], line((28, 44), (30, 56)), line((36, 44), (34, 56)))
    eye = hx('#1c1412')
    s.dt(eye, line((23, 29), (27, 30)), line((37, 30), (41, 29)))
    s.dt(P['skin'][1], line((22, 26), (27, 26)), line((37, 26), (42, 26)), line((32, 31), (31, 36)))
    s.dt(P['skin'][4], line((24, 24), (26, 24)))
    s.dt(P['cream'][0], line((29, 40), (35, 40)))
    return s.render()

# ---------------- ЛОШАДЬ 32x32 ----------------
def horse(frame=0):
    s = Spr(32, 32)
    a = [0, 1, -1][frame]
    for x, ph, b in ((7, a, -.25), (11, -a, 0), (20, -a, -.25), (24, a, 0)):
        s.add('coat', poly((x, 19), (x+4, 19), (x+4+ph, 28), (x+ph, 28)), mode='cyl', bias=b-.15)
        s.add('mane', rect(x+ph, 28, x+4+ph, 30), mode='flat')
    s.add('coat', ell(16, 17, 12, 7), mode='round')  # коренастое бочкообразное тело
    s.add('coat', poly((21, 17), (23, 7), (27, 6), (27, 18)), mode='round')   # шея
    s.add('coat', poly((24, 5), (28, 4), (31, 10), (31, 13), (28, 13), (25, 10)), mode='round')  # голова
    s.add('mane', poly((20, 14), (22, 4), (26, 3), (23, 16)), mode='round')
    s.add('mane', rect(30, 11, 31, 13), mode='flat')
    s.add('mane', poly((3, 13), (6, 12), (4, 26), (1, 24)), mode='round')
    for x in range(7, 25, 3): s.px(x, 23, P['coat'][1]); s.px(x+1, 11, P['coat'][4]); s.px(x, 24, P['coat'][2])
    s.px(27, 7, hx('#1c1412')); s.px(26, 3, P['mane'][2])
    return s.render()
