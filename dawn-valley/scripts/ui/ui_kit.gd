extends RefCounted
## Общий стиль интерфейса: пиксельный шрифт, деревянные рамки, ячейки предметов.

const INK := Color("3b1d1a")
const INK2 := Color("6b3824")
const PAPER := Color("f7e3b5")
const GOLD := Color("ffd36a")
const LIGHT := Color("fff4e0")

static var _theme: Theme
static var _font: FontFile


static func font() -> FontFile:
	if _font == null:
		_font = load("res://assets/fonts/PixelifySans.ttf")
		_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		_font.hinting = TextServer.HINTING_NONE
		_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	return _font


static func ui_region(r: Rect2) -> AtlasTexture:
	return Db.region("ui", r)


static func tex_style(r: Rect2, m: int, content_h := 6, content_v := 5) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = Db.tex("ui")
	sb.region_rect = r
	sb.texture_margin_left = m
	sb.texture_margin_right = m
	sb.texture_margin_top = m
	sb.texture_margin_bottom = m
	sb.content_margin_left = content_h
	sb.content_margin_right = content_h
	sb.content_margin_top = content_v
	sb.content_margin_bottom = content_v
	return sb


static func panel_style() -> StyleBoxTexture:
	return tex_style(Rect2(0, 0, 32, 32), 8, 9, 8)


static func tooltip_style() -> StyleBoxTexture:
	return tex_style(Rect2(0, 48, 16, 16), 4, 5, 4)


static func flat(bg: Color, border: Color = Color.TRANSPARENT, bw := 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	return sb


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = 10
	t.set_stylebox("panel", "Panel", panel_style())
	t.set_stylebox("panel", "PanelContainer", panel_style())
	t.set_color("font_color", "Label", INK)
	for st in [["normal", 0], ["hover", 24], ["pressed", 48], ["disabled", 72], ["focus", 24]]:
		var sb := tex_style(Rect2(st[1], 32, 24, 16), 4, 7, 3)
		t.set_stylebox(st[0], "Button", sb)
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", INK)
	t.set_color("font_pressed_color", "Button", INK)
	t.set_color("font_focus_color", "Button", INK)
	t.set_color("font_disabled_color", "Button", Color("5a4a44"))
	t.set_stylebox("slider", "HSlider", flat(Color("6b3824"), INK, 1))
	t.set_stylebox("grabber_area", "HSlider", flat(Color("e6b84a")))
	t.set_stylebox("grabber_area_highlight", "HSlider", flat(Color("fae694")))
	t.set_stylebox("normal", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("hover", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("pressed", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("focus", "CheckBox", StyleBoxEmpty.new())
	t.set_color("font_color", "CheckBox", INK)
	t.set_color("font_hover_color", "CheckBox", INK2)
	t.set_color("font_pressed_color", "CheckBox", INK)
	_theme = t
	return t


static func label(text: String, size := 10, color := INK, outline := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline:
		l.add_theme_color_override("font_outline_color", INK)
		l.add_theme_constant_override("outline_size", 4)
	return l


static func button(text: String, cb: Callable, size := 10) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func():
		Audio.sfx("click")
		cb.call())
	return b


static func heart(full: bool) -> AtlasTexture:
	return ui_region(Rect2(72 if full else 81, 0, 9, 8))


static func coin() -> AtlasTexture:
	return ui_region(Rect2(90, 0, 9, 9))


static func bolt() -> AtlasTexture:
	return ui_region(Rect2(99, 0, 8, 9))


static func panel(min_size := Vector2.ZERO) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = min_size
	return p


## Подпись предмета для подсказки: [заголовок, текст]
static func item_tooltip(id: String) -> Array:
	var it := Db.item(id)
	var cats := {"tool": "Инструмент", "seed": "Семена", "crop": "Урожай", "fish": "Рыба", "resource": "Ресурс",
		"forage": "Дары леса", "food": "Еда", "craft": "Изделие", "misc": "Ценность"}
	var lines := [cats.get(it.get("cat", ""), ""), it.get("desc", "")]
	if it.has("energy"):
		lines.append("Энергия: +%d" % int(it["energy"]))
	if int(it.get("price", 0)) > 0:
		lines.append("Цена: %d монет" % int(it["price"]))
	return [it.get("name", id), "\n".join(lines)]
