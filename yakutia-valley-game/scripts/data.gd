extends RefCounted
## Справочник предметов, культур и рецептов.
## frame — номер кадра в assets/items.png (8 колонок по 16×16).

const ITEMS := {
	"choron":      {"name": "Чорон с кумысом", "desc": "Резной кубок с кумысом. Его пьют на Ысыахе.", "price": 250, "frame": 0, "energy": 40, "type": "food"},
	"khomus":      {"name": "Хомус", "desc": "Варган. Звенит, как ветер над аласом.", "price": 400, "frame": 1, "type": "misc"},
	"stroganina":  {"name": "Строганина", "desc": "Тонкая стружка мороженого чира.", "price": 180, "frame": 2, "energy": 50, "type": "food"},
	"brusnika":    {"name": "Брусника", "desc": "Кислая таёжная ягода.", "price": 40, "frame": 3, "energy": 10, "type": "food"},
	"karas":       {"name": "Карась", "desc": "Золотой озёрный карась.", "price": 60, "frame": 4, "type": "fish"},
	"chir":        {"name": "Чир", "desc": "Северная сиговая рыба. Лучшая для строганины.", "price": 90, "frame": 5, "type": "fish"},
	"kerchekh":    {"name": "Кёрчэх", "desc": "Взбитые сливки с ягодами.", "price": 220, "frame": 6, "energy": 60, "type": "food"},
	"alaadyi":     {"name": "Алаадьи", "desc": "Пышные оладьи на ячменной муке.", "price": 150, "frame": 7, "energy": 45, "type": "food"},
	"mammoth":     {"name": "Бивень мамонта", "desc": "Вечная мерзлота хранит древности.", "price": 2000, "frame": 8, "type": "misc"},
	"torbasa":     {"name": "Торбаса", "desc": "Меховые сапоги с бисерной вышивкой.", "price": 600, "frame": 9, "type": "misc"},
	"knife":       {"name": "Якутский нож", "desc": "Асимметричный клинок, рукоять из берёзового капа.", "price": 500, "frame": 10, "type": "misc"},
	"ice":         {"name": "Льдина", "desc": "Кусок озёрного льда. Кто её выудил?", "price": 15, "frame": 11, "energy": 2, "type": "food"},
	"hoe":         {"name": "Мотыга", "desc": "Рыхлит землю, разбивает камни.", "price": 0, "frame": 12, "type": "tool"},
	"can":         {"name": "Лейка", "desc": "Поливает грядки.", "price": 0, "frame": 13, "type": "tool"},
	"rod":         {"name": "Удочка", "desc": "Встань лицом к воде и закинь.", "price": 0, "frame": 14, "type": "tool"},
	"seed_potato": {"name": "Семена картофеля", "desc": "Растёт 6 дней. Даёт 2 клубня.", "price": 15, "frame": 15, "type": "seed", "crop": "potato"},
	"seed_barley": {"name": "Семена ячменя", "desc": "Растёт 4 дня.", "price": 10, "frame": 16, "type": "seed", "crop": "barley"},
	"seed_turnip": {"name": "Семена репы", "desc": "Растёт 3 дня.", "price": 12, "frame": 17, "type": "seed", "crop": "turnip"},
	"potato":      {"name": "Картофель", "desc": "Северный картофель с аласа.", "price": 80, "frame": 18, "energy": 15, "type": "food"},
	"barley":      {"name": "Ячмень", "desc": "Из него пекут алаадьи.", "price": 45, "frame": 19, "type": "crop"},
	"turnip":      {"name": "Репа", "desc": "Сочная и сладкая.", "price": 70, "frame": 20, "energy": 12, "type": "food"},
	"kumys":       {"name": "Кумыс", "desc": "Кобылье молоко в кытыйе-ковше.", "price": 100, "frame": 21, "energy": 20, "type": "food"},
}

# row — ряд в assets/crops.png, days — сколько политых дней до урожая
const CROPS := {
	"potato": {"row": 0, "days": 6, "item": "potato", "yield": 2},
	"barley": {"row": 1, "days": 4, "item": "barley", "yield": 2},
	"turnip": {"row": 2, "days": 3, "item": "turnip", "yield": 1},
}

const RECIPES := [
	{"out": "stroganina", "need": {"chir": 1}},
	{"out": "alaadyi", "need": {"barley": 2}},
	{"out": "kerchekh", "need": {"kumys": 1, "brusnika": 2}},
	{"out": "choron", "need": {"kumys": 2}},
]

const SHOP := [
	["seed_turnip", 25], ["seed_barley", 20], ["seed_potato", 30],
	["khomus", 500], ["torbasa", 800], ["knife", 700],
]

# Отношение олонхосута к подаркам: 3 — обожает, 1 — нравится, -1 — не нравится
const GIFTS := {"khomus": 3, "stroganina": 3, "choron": 2, "kerchekh": 2, "alaadyi": 1,
	"brusnika": 1, "karas": 1, "chir": 1, "mammoth": 3, "ice": -1}

const NPC_LINES := [
	["Дорообо! Алас нынче зелёный — значит, лето будет щедрым.",
	 "Карась в озере любит тихое утро. Закинь удочку пораньше.",
	 "Брусника в тайге поспевает за три дня. Не обирай всё — оставь птицам.",
	 "Посади ячмень: из него выйдут славные алаадьи.",
	 "Олонхо поётся девять ночей подряд. Начинается оно так: «В стародавние времена, когда Средний мир был молод...»"],
	["Ты уже не гость на этом аласе. Земля тебя помнит.",
	 "Чир — для строганины, а кумыс — в чорон. Так заведено.",
	 "Погладь коня у сэргэ — кобыла отблагодарит кумысом."],
	["Сэргэ у твоего балагана держит не только коня, но и удачу рода.",
	 "Спою тебе на Ысыахе. Ты заслужил место у огня.",
	 "Хомус звенит лучше всего, когда над аласом тихо."],
]
