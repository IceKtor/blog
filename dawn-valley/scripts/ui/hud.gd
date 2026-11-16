extends Control
## HUD: часы, день и сезон, монеты, шкала энергии, панель быстрого доступа, уведомления.

const UiKit = preload("res://scripts/ui/ui_kit.gd")
const ItemSlot = preload("res://scripts/ui/item_slot.gd")

var game
var day_label: Label
var time_label: Label
var money_label: Label
var energy_bar: Control
var slots := []
var item_name: Label
var _name_t := 0.0
var notes: VBoxContainer
var banner: Label
var _banner_t := 0.0
var _shown_money := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# часы
	var clock := UiKit.panel(Vector2(88, 0))
	clock.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	clock.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	clock.offset_left = -92
	clock.offset_right = -4
	clock.offset_top = 4
	clock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(clock)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	clock.add_child(vb)
	day_label = UiKit.label("", 10)
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(day_label)
	time_label = UiKit.label("", 16, UiKit.INK2)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(time_label)
	var mrow := HBoxContainer.new()
	mrow.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(mrow)
	var ci := TextureRect.new()
	ci.texture = UiKit.coin()
	ci.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	mrow.add_child(ci)
	money_label = UiKit.label("", 10)
	mrow.add_child(money_label)
	# энергия
	energy_bar = _EnergyBar.new()
	energy_bar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	energy_bar.offset_left = -18
	energy_bar.offset_top = -82
	energy_bar.offset_right = -6
	energy_bar.offset_bottom = -6
	add_child(energy_bar)
	# панель быстрого доступа
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UiKit.tex_style(Rect2(0, 0, 32, 32), 3, 4, 4))
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bar.offset_bottom = -3
	add_child(bar)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 1)
	bar.add_child(hb)
	for i in 10:
		var s := ItemSlot.new()
		s.index = i
		s.hotkey = str((i + 1) % 10)
		s.clicked.connect(func(sl, _b): Inventory.select(sl.index))
		s.hovered.connect(_on_hover)
		hb.add_child(s)
		slots.append(s)
	item_name = UiKit.label("", 10, UiKit.LIGHT, true)
	item_name.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	item_name.grow_horizontal = Control.GROW_DIRECTION_BOTH
	item_name.offset_top = -46
	item_name.offset_bottom = -32
	item_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(item_name)
	# уведомления
	notes = VBoxContainer.new()
	notes.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	notes.grow_vertical = Control.GROW_DIRECTION_BEGIN
	notes.offset_left = 4
	notes.offset_bottom = -6
	notes.alignment = BoxContainer.ALIGNMENT_END
	notes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(notes)
	banner = UiKit.label("", 16, UiKit.LIGHT, true)
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	banner.offset_top = 24
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(banner)
	Inventory.changed.connect(refresh)
	Inventory.selected_changed.connect(_on_selected)
	Game.water_changed.connect(_on_water)
	Game.notify.connect(note)
	_shown_money = Economy.money
	refresh()


func _process(delta: float) -> void:
	day_label.text = "%s, %d · %s" % [GameClock.weekday(), GameClock.day, Db.SEASONS[GameClock.season]]
	time_label.text = GameClock.time_text()
	_shown_money = move_toward(_shown_money, Economy.money, maxf(1.0, absf(Economy.money - _shown_money) * delta * 6.0))
	money_label.text = str(int(round(_shown_money)))
	energy_bar.queue_redraw()
	if _name_t > 0.0:
		_name_t -= delta
		item_name.modulate.a = clampf(_name_t, 0.0, 1.0)
	if _banner_t > 0.0:
		_banner_t -= delta
		banner.modulate.a = clampf(_banner_t, 0.0, 1.0)


func _on_selected(_i: int) -> void:
	refresh()
	_flash_name()


func _on_water(_v: int) -> void:
	refresh()


func refresh() -> void:
	for i in 10:
		slots[i].set_item(Inventory.slots[i], i == Inventory.selected)


func _flash_name() -> void:
	var id := Inventory.current_id()
	item_name.text = "" if id == "" else Db.item_name(id)
	_name_t = 2.0


func _on_hover(s, on: bool) -> void:
	if on and s.item != null:
		var tt := UiKit.item_tooltip(s.item["id"])
		game.show_tooltip(tt[0], tt[1])
	else:
		game.hide_tooltip()


func show_banner(text: String) -> void:
	banner.text = text
	_banner_t = 2.5


func note(icon: Texture2D, text: String) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.tooltip_style())
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hb := HBoxContainer.new()
	p.add_child(hb)
	if icon:
		var tr := TextureRect.new()
		tr.texture = icon
		hb.add_child(tr)
	hb.add_child(UiKit.label(text, 10))
	notes.add_child(p)
	if notes.get_child_count() > 5:
		notes.get_child(0).queue_free()
	var tw := p.create_tween()
	tw.tween_interval(2.6)
	tw.tween_property(p, "modulate:a", 0.0, 0.5)
	tw.tween_callback(p.queue_free)


class _EnergyBar extends Control:
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color("e8ecf4"))
		draw_rect(r.grow(-1), Color("1a2234"))
		var k := Game.energy / Game.MAX_ENERGY
		var inner := r.grow(-2)
		var fh := inner.size.y * k
		var col := Color("64aa40") if k > 0.5 else (Color("ecc840") if k > 0.2 else Color("d84a3c"))
		draw_rect(Rect2(inner.position.x, inner.end.y - fh, inner.size.x, fh), col)
		var b = preload("res://scripts/ui/ui_kit.gd").bolt()
		draw_texture(b, Vector2((size.x - 8) / 2, -11))
