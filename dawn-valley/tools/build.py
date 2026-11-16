"""Генерирует всю графику игры «Рассветная долина». Запуск: python build.py"""
import os, json
from PIL import Image
import tiles, objects as O, chars, items as I, ui_art

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
SPR = os.path.join(ROOT, 'assets', 'sprites'); os.makedirs(SPR, exist_ok=True)
def save(im, name): im.save(os.path.join(SPR, name))
def strip(ims, w, h, cols=None):
    cols = cols or len(ims); rows = (len(ims) + cols - 1) // cols
    out = Image.new('RGBA', (w * cols, h * rows))
    for i, im in enumerate(ims): out.paste(im, ((i % cols) * w, (i // cols) * h))
    return out

for s in tiles.SEASONS:
    save(tiles.season_sheet(s), f'tiles_{s}.png')
    save(strip([O.oak(s), O.pine(s)], 32, 48), f'trees_{s}.png')
objs = [O.weed(s) for s in tiles.SEASONS] + [O.stone_small(), O.twig(), O.stump(), O.mine_rock('rock'), O.mine_rock('rock2'),
        O.mine_rock('copper'), O.mine_rock('iron'), O.mine_rock('gold'), O.ladder(), O.fence(), O.sprinkler(), O.path_stone()] + \
       [O.bush(s) for s in tiles.SEASONS] + [O.dock_post()]
save(strip(objs, 16, 16, 8), 'objects.png')
for name, f in (('chest', O.chest), ('shipping_bin', O.shipping_bin), ('bed', O.bed), ('table', O.table), ('stove', O.stove),
                ('lift', O.lift), ('lamp', O.lamp), ('well', O.well), ('bench', O.bench), ('farmhouse', O.farmhouse), ('shop', O.shop),
                ('school', O.school), ('mine_entrance', O.mine_entrance)):
    save(f(), name + '.png')
save(O.house('rblue', 'lwood', 0), 'house_a.png'); save(O.house('rred', 'lwood', 1), 'house_b.png')
save(O.mill(False), 'mill_broken.png'); save(O.mill(True), 'mill_fixed.png')
save(strip([O.flowerbed(s) for s in tiles.SEASONS], 32, 16), 'flowerbed.png')
for k, c in chars.CHARS.items():
    save(chars.sheet(c), f'{k}.png'); save(chars.portrait(c), f'portrait_{k}.png')
save(strip([I.crop(k, st) for k in I.CROPS for st in range(6)], 16, 32, 6), 'crops.png')

icons = [('hoe', I.tool_hoe()), ('can', I.tool_can()), ('axe', I.tool_axe()), ('pickaxe', I.tool_pick()), ('rod', I.tool_rod())]
icons += [('seed_' + k, I.seed(k)) for k in I.CROPS] + [(k, I.produce(k)) for k in I.CROPS]
icons += [('carp', I.fish('gold', 'orange')), ('perch', I.fish('lime', 'red', spots='green')), ('pike', I.fish('green', 'lime', slim=True, spots='yellow')),
          ('trout', I.fish('pink', 'white', spots='beet')), ('catfish', I.fish('stone', 'hgrey', whisk=True)), ('bream', I.fish('iron', 'stone', flat=True))]
icons += [('wood', I.wood()), ('stone', I.stone()), ('fiber', I.fiber()), ('copper_ore', I.ore('copper')), ('iron_ore', I.ore('iron')), ('gold_ore', I.ore('goldore'))]
icons += [(k, I.forage(k)) for k in ('wild_onion', 'daffodil', 'blackberry', 'chamomile', 'mushroom', 'hazelnut', 'winter_root', 'holly')]
icons += [(k, I.food(k)) for k in ('berry_snack', 'mushroom_soup', 'fish_soup', 'veggie_stew')]
icons += [('chest', I.scale_obj(O.chest())), ('sprinkler', O.sprinkler()), ('fence', O.fence()), ('path_stone', O.path_stone()), ('ancient_coin', I.coin())]
save(strip([im for _, im in icons], 16, 16, 8), 'items.png')
json.dump({k: i for i, (k, _) in enumerate(icons)}, open(os.path.join(ROOT, 'data', 'item_frames.json'), 'w'), indent=1)

save(ui_art.ui_sheet(), 'ui.png'); save(ui_art.title_bg(), 'title_bg.png')
ic = chars.portrait(chars.CHARS['player']); ic.save(os.path.join(ROOT, 'icon.png'))
print('готово:', len(os.listdir(SPR)), 'файлов,', len(icons), 'предметов')
