extends "res://scripts/ui/modal.gd"
## Ящик отгрузки (mode = "ship") или сундук (mode = "chest").

var mode := "ship"
var chest: Dictionary = {}
var top_slots := []
var inv_slots := []
var info: Label
var last_slot


func _ready() -> void:
	add_dim()
	var p := centered_panel(Vector2(232, 0))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	p.add_child(vb)
	title_row(vb, "Ящик отгрузки" if mode == "ship" else "Сундук")
	if mode == "ship":
		var row := HBoxContainer.new()
		vb.add_child(row)
		last_slot = ItemSlot.new()
		last_slot.clicked.connect(func(_s, _b): _take_back())
		last_slot.hovered.connect(_on_last_hover)
		row.add_child(last_slot)
		info = UiKit.label("", 9)
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.custom_minimum_size = Vector2(196, 0)
		row.add_child(info)
	else:
		var g := _grid(10)
		vb.add_child(g)
		for i in 20:
			var s := ItemSlot.new()
			s.index = i
			s.clicked.connect(_on_chest)
			s.hovered.connect(_on_hover)
			g.add_child(s)
			top_slots.append(s)
	vb.add_child(UiKit.label("Рюкзак — нажми на предмет:", 9, UiKit.INK2))
	var ig := _grid(10)
	vb.add_child(ig)
	for i in Inventory.SIZE:
		var s := ItemSlot.new()
		s.index = i
		s.clicked.connect(_on_inv)
		s.hovered.connect(_on_hover)
		ig.add_child(s)
		inv_slots.append(s)
	Inventory.changed.connect(_refresh)
	_refresh()


func _on_last_hover(_s, on: bool) -> void:
	if on:
		game.show_tooltip("Последний предмет", "Нажми, чтобы забрать обратно.")
	else:
		game.hide_tooltip()


func _grid(cols: int) -> GridContainer:
	var g := GridContainer.new()
	g.columns = cols
	g.add_theme_constant_override("h_separation", 2)
	g.add_theme_constant_override("v_separation", 2)
	return g


func _refresh() -> void:
	for s in inv_slots:
		var it = Inventory.slots[s.index]
		s.set_item(it)
		s.dim = mode == "ship" and it != null and not Economy.can_ship(it["id"])
	if mode == "ship":
		var last = Economy.shipping.back() if not Economy.shipping.is_empty() else null
		last_slot.set_item(last)
		info.text = "Предметы будут проданы ночью.\nВ ящике на %d монет." % Economy.shipping_value()
	else:
		for s in top_slots:
			s.set_item(chest["slots"][s.index])


func _on_hover(s, on: bool) -> void:
	if on and s.item != null:
		var tt := UiKit.item_tooltip(s.item["id"])
		game.show_tooltip(tt[0], tt[1])
	else:
		game.hide_tooltip()


func _on_inv(s, button: int) -> void:
	var it = Inventory.slots[s.index]
	if it == null:
		return
	var n: int = it["n"] if button == MOUSE_BUTTON_LEFT else 1
	if mode == "ship":
		if not Economy.can_ship(it["id"]):
			Audio.sfx("error")
			return
		Economy.ship(it["id"], n)
		Inventory.take_slot(s.index, n)
		Audio.sfx("coin")
	else:
		var left := _chest_add(it["id"], n)
		Inventory.take_slot(s.index, n - left)
		Audio.sfx("click")
	_refresh()


func _chest_add(id: String, n: int) -> int:
	var slots: Array = chest["slots"]
	for i in slots.size():
		if slots[i] != null and slots[i]["id"] == id and Db.stackable(id):
			slots[i]["n"] = int(slots[i]["n"]) + n
			return 0
	for i in slots.size():
		if slots[i] == null:
			slots[i] = {"id": id, "n": n}
			return 0
	return n


func _on_chest(s, button: int) -> void:
	var slots: Array = chest["slots"]
	var it = slots[s.index]
	if it == null:
		return
	var n: int = int(it["n"]) if button == MOUSE_BUTTON_LEFT else 1
	var left := Inventory.add(it["id"], n)
	it["n"] = int(it["n"]) - (n - left)
	if it["n"] <= 0:
		slots[s.index] = null
	Audio.sfx("click")
	_refresh()


func _take_back() -> void:
	if Economy.shipping.is_empty():
		return
	var last: Dictionary = Economy.shipping.back()
	var left := Inventory.add(last["id"], last["n"])
	if left == 0:
		Economy.shipping.pop_back()
	else:
		last["n"] = left
	_refresh()
