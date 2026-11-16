extends "res://scripts/ui/modal.gd"
## Лавка Тимофея: семена текущего сезона и полезные товары.

const EXTRA := [["berry_snack", 120], ["fence", 10], ["path_stone", 8], ["chest", 400], ["sprinkler", 900]]

var money_label: Label
var list: VBoxContainer


func _ready() -> void:
	add_dim()
	var p := centered_panel(Vector2(330, 0))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	p.add_child(vb)
	var head := HBoxContainer.new()
	vb.add_child(head)
	var fr := PanelContainer.new()
	fr.add_theme_stylebox_override("panel", UiKit.tooltip_style())
	head.add_child(fr)
	var pr := TextureRect.new()
	pr.texture = Db.tex("portrait_timofey")
	pr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pr.custom_minimum_size = Vector2(40, 40)
	fr.add_child(pr)
	var hv := VBoxContainer.new()
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hv)
	hv.add_child(UiKit.label("Лавка Тимофея", 13, UiKit.INK2))
	hv.add_child(UiKit.label("«Всё свежее! Shift + клик — купить 5 штук.»", 9))
	var mr := HBoxContainer.new()
	hv.add_child(mr)
	var ci := TextureRect.new()
	ci.texture = UiKit.coin()
	ci.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	mr.add_child(ci)
	money_label = UiKit.label("", 10)
	mr.add_child(money_label)
	head.add_child(UiKit.button("X", close, 10))
	list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 2)
	vb.add_child(list)
	_build()


func _goods() -> Array:
	var g := []
	for c in Db.crops:
		if int(Db.crops[c]["season"]) == GameClock.season:
			g.append(["seed_" + c, int(Db.crops[c]["seed_price"])])
	return g + EXTRA


func _build() -> void:
	money_label.text = "%d монет" % Economy.money
	for c in list.get_children():
		c.queue_free()
	var goods := _goods()
	if GameClock.season == 3:
		list.add_child(UiKit.label("Зимой семян нет — земля промёрзла. Загляни весной!", 9, UiKit.INK2))
	for g in goods:
		var id: String = g[0]
		var price: int = g[1]
		var row := Button.new()
		row.focus_mode = Control.FOCUS_NONE
		row.custom_minimum_size = Vector2(300, 20)
		row.disabled = Economy.money < price
		row.pressed.connect(_buy.bind(id, price))
		row.mouse_entered.connect(func():
			var tt := UiKit.item_tooltip(id)
			game.show_tooltip(tt[0], tt[1] + "\nВ рюкзаке: %d" % Inventory.count(id)))
		row.mouse_exited.connect(func(): game.hide_tooltip())
		list.add_child(row)
		var hb := HBoxContainer.new()
		hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hb.offset_left = 4
		hb.offset_right = -6
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(hb)
		var tr := TextureRect.new()
		tr.texture = Db.icon(id)
		tr.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		hb.add_child(tr)
		var nl := UiKit.label(Db.item_name(id), 10)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(nl)
		hb.add_child(UiKit.label(str(price), 10, UiKit.INK2))
		var c2 := TextureRect.new()
		c2.texture = UiKit.coin()
		c2.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		hb.add_child(c2)


func _buy(id: String, price: int) -> void:
	var n := 5 if Input.is_key_pressed(KEY_SHIFT) else 1
	n = mini(n, Economy.money / price)
	if n <= 0 or not Economy.buy(id, price, n):
		Audio.sfx("error")
		return
	Audio.sfx("coin")
	Game.notify.emit(Db.icon(id), "Куплено: %s ×%d" % [Db.item_name(id), n])
	_build()
