"""Собирает все PNG в ../assets. Запуск из любой папки: python build_assets.py"""
import os
from PIL import Image
from pix import sheet
import sprites as S

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets')
os.makedirs(OUT, exist_ok=True)
def save(im, name): im.save(os.path.join(OUT, name)); print('  ', name, im.size)

save(sheet(S.TILES(), 16, 16, 12), 'tiles.png')
save(sheet([f() for _, f in S.ITEMS], 16, 16, 8), 'items.png')
save(sheet([S.crop(k, st) for k in S.CROPS for st in range(5)], 16, 32, 5), 'crops.png')
for kind in ('player', 'olonkhosut'):
    save(sheet([S.person(d, f, kind) for d in range(4) for f in range(4)], 16, 32, 4), kind + '.png')
save(S.portrait(), 'portrait_olonkhosut.png')
h = [S.horse(f) for f in range(3)]
save(sheet(h + [i.transpose(0) for i in h], 32, 32, 3), 'horse.png')
save(sheet([S.larch(), S.birch_tree()], 32, 48, 2), 'trees.png')
save(sheet([S.bush(True), S.bush(False), S.rock()], 16, 16, 3), 'bush.png')
save(S.balagan(), 'balagan.png'); save(S.urasa(), 'urasa.png'); save(S.serge(), 'serge.png')
save(sheet([S.kamelyok(f) for f in range(3)], 16, 32, 3), 'kamelyok.png')
save(S.ampaar(), 'ampaar.png'); save(S.bed(), 'bed.png')

# превью x4
names = ['items.png', 'crops.png', 'player.png', 'olonkhosut.png', 'horse.png', 'trees.png',
         'balagan.png', 'urasa.png', 'serge.png', 'kamelyok.png', 'ampaar.png', 'portrait_olonkhosut.png', 'tiles.png']
ims = [Image.open(os.path.join(OUT, n)) for n in names]
W = 4*max(i.width for i in ims) + 16; H = sum(4*i.height + 8 for i in ims)
pv = Image.new('RGBA', (W, H), (40, 44, 52, 255)); y = 4
for i in ims:
    pv.alpha_composite(i.resize((i.width*4, i.height*4), Image.NEAREST), (8, y)); y += 4*i.height + 8
pv.save(os.path.join(OUT, '..', '_source', 'preview.png'))
print('готово')
S.portrait().save(os.path.join(OUT, '..', 'icon.png'))
