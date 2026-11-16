extends "res://scripts/ui/modal.gd"
## Меню (Tab / I): рюкзак на 30 ячеек, крафт, жители, мельница.

const TABS := ["Рюкзак", "Крафт", "Жители", "Мельница"]

var tab := 0
var content: VBoxContainer
var tab_buttons := []
var held = null          # предмет «в руке» курсора
var held_icon: Control
var inv_slots := []


func _ready() -> void:
	add_dim()
	var p := centered_panel(Vector2(400, 236))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	p.add_child(vb)
	var top := HBoxContainer.new()
	vb.add_child(top)
	for i in TABS.size():
		var b := UiKit.button(TABS[i], _set_tab.bind(i), 10)
		b.toggle_mode = true
		top.add_child(b)
		tab_buttons.append(b)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	var x := UiKit.button("X", close, 10)
	top.add_child(x)
	content = VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 4)
	vb.add_child(content)
	held_icon = _Held.new()
	held_icon.menu = self
	held_icon.top_level = true
	held_icon.z_index = 90
	held_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(held_icon)
	Inventory.changed.connect(_refresh_slots)
	Game.bundles_changed.connect(_on_bundles)
	_set_tab(tab)


func _on_bundles() -> void:
	if tab == 3:
		_set_tab(3)


func close() -> void:
	if held != null:
		var left := Inventory.add(held["id"], held["n"])
		held = null
		if left > 0:
			Game.notify.emit(null, "Не хватило места — часть предметов потеряна.")
	super.close()


func _set_tab(i: int) -> void:
	tab = i
	for k in tab_buttons.size():
		tab_buttons[k].button_pressed = k == i
	for c in content.get_children():
		content.remove_child(c)
		c.queue_free()
	inv_slots.clear()
	game.hide_tooltip()
	match i:
		0: _build_inventory()
		1: _build_craft()
		2: _build_people()
		3: _build_mill()


# ------------------------------------------------------------------ рюкзак
func _build_inventory() -> void:
	var grid := GridContainer.new()
	grid.columns = 10
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	content.add_child(_center(grid))
	for i in Inventory.SIZE:
		var s := ItemSlot.new()
		s.index = i
		if i < 10:
			s.hotkey = str((i + 1) % 10)
		s.clicked.connect(_on_slot)
		s.hovered.connect(_on_hover)
		grid.add_child(s)
		inv_slots.append(s)
		if i == 9:
			pass
	_refresh_slots()
	var info := HBoxContainer.new()
	info.add_theme_constant_override("separation", 10)
	content.add_child(info)
	var ci := TextureRect.new()
	ci.texture = UiKit.coin()
	ci.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	info.add_child(ci)
	info.add_child(UiKit.label("%d монет" % Economy.money, 10))
	info.add_child(UiKit.label("%s, день %d, год %d" % [Db.SEASONS[GameClock.season], GameClock.day, GameClock.year], 10, UiKit.INK2))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(sp)
	info.add_child(UiKit.button("Сортировать", _sort, 9))
	info.add_child(UiKit.button("Выбросить", _trash, 9))
	var hint := UiKit.label("ЛКМ — взять/положить, ПКМ — взять половину или положить одну.\nВерхний ряд — панель быстрого доступа (клавиши 1–0).", 9, UiKit.INK2)
	content.add_child(hint)


func _center(c: Control) -> CenterContainer:
	var cc := CenterContainer.new()
	cc.add_child(c)
	return cc


func _refresh_slots() -> void:
	for s in inv_slots:
		s.set_item(Inventory.slots[s.index], s.index == Inventory.selected)


func _on_slot(s, button: int) -> void:
	var i: int = s.index
	var cur = Inventory.slots[i]
	Audio.sfx("click")
	if button == MOUSE_BUTTON_LEFT:
		if held == null:
			if cur != null:
				held = cur
				Inventory.set_slot(i, null)
		elif cur == null:
			Inventory.set_slot(i, held)
			held = null
		elif cur["id"] == held["id"] and Db.stackable(cur["id"]):
			cur["n"] += held["n"]
			held = null
			Inventory.changed.emit()
		else:
			Inventory.set_slot(i, held)
			held = cur
	else:
		if held == null and cur != null and cur["n"] > 1:
			var half: int = cur["n"] / 2
			held = {"id": cur["id"], "n": half}
			cur["n"] -= half
			Inventory.changed.emit()
		elif held != null and (cur == null or (cur["id"] == held["id"] and Db.stackable(cur["id"]))):
			if cur == null:
				Inventory.set_slot(i, {"id": held["id"], "n": 1})
			else:
				cur["n"] += 1
				Inventory.changed.emit()
			held["n"] -= 1
			if held["n"] <= 0:
				held = null
	held_icon.queue_redraw()


func _on_hover(s, on: bool) -> void:
	if on and s.item != null and held == null:
		var tt := UiKit.item_tooltip(s.item["id"])
		game.show_tooltip(tt[0], tt[1])
	else:
		game.hide_tooltip()


func _trash() -> void:
	if held == null:
		Game.notify.emit(null, "Возьми предмет курсором, затем нажми «Выбросить».")
		return
	if Db.is_tool(held["id"]):
		Game.notify.emit(null, "Инструменты выбрасывать нельзя.")
		return
	held = null
	Audio.sfx("close")
	held_icon.queue_redraw()


func _sort() -> void:
	var tools := []
	var rest := []
	for s in Inventory.slots:
		if s != null:
			(tools if Db.is_tool(s["id"]) else rest).append(s)
	var order := ["hoe", "can", "axe", "pickaxe", "rod"]
	tools.sort_custom(func(a, b): return order.find(a["id"]) < order.find(b["id"]))
	rest.sort_custom(func(a, b): return Db.item(a["id"]).get("cat", "") + a["id"] < Db.item(b["id"]).get("cat", "") + b["id"])
	var all := tools + rest
	for i in Inventory.SIZE:
		Inventory.slots[i] = all[i] if i < all.size() else null
	Inventory.changed.emit()


class _Held extends Control:
	var menu
	func _process(_d: float) -> void:
		global_position = get_global_mouse_position() - Vector2(8, 8)
		queue_redraw()
	func _draw() -> void:
		if menu.held == null:
			return
		draw_texture(Db.icon(menu.held["id"]), Vector2.ZERO)
		if menu.held["n"] > 1:
			var f = preload("res://scripts/ui/ui_kit.gd").font()
			draw_string_outline(f, Vector2(9, 16), str(menu.held["n"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 2, Color("3b1d1a"))
			draw_string(f, Vector2(9, 16), str(menu.held["n"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)


# ------------------------------------------------------------------ крафт
func _build_craft() -> void:
	content.add_child(UiKit.label("Наведи на рецепт, чтобы увидеть материалы. Нажми — чтобы создать.", 9, UiKit.INK2))
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	content.add_child(_center(grid))
	for r in Db.recipes:
		var s := ItemSlot.new()
		s.custom_minimum_size = Vector2(18, 18)
		var ok := _can_craft(r)
		s.set_item({"id": r["out"], "n": int(r["n"])})
		s.dim = not ok
		s.clicked.connect(func(_sl, _b): _craft(r))
		s.hovered.connect(func(_sl, on):
			if on:
				var lines := []
				for k in r["need"]:
					lines.append("%s: %d/%d" % [Db.item_name(k), Inventory.count(k), int(r["need"][k])])
				game.show_tooltip(Db.item_name(r["out"]) + (" ×%d" % int(r["n"]) if int(r["n"]) > 1 else ""),
					Db.item(r["out"]).get("desc", "") + "\nНужно:\n" + "\n".join(lines))
			else:
				game.hide_tooltip())
		grid.add_child(s)
	content.add_child(_center(_craft_list()))


func _craft_list() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 1)
	for r in Db.recipes:
		var parts := PackedStringArray()
		for k in r["need"]:
			parts.append("%s ×%d" % [Db.item_name(k), int(r["need"][k])])
		var l := UiKit.label("%s — %s" % [Db.item_name(r["out"]), ", ".join(parts)], 9, UiKit.INK if _can_craft(r) else Color("8a90a0"))
		vb.add_child(l)
	return vb


func _can_craft(r: Dictionary) -> bool:
	for k in r["need"]:
		if Inventory.count(k) < int(r["need"][k]):
			return false
	return true


func _craft(r: Dictionary) -> void:
	if not _can_craft(r):
		Audio.sfx("error")
		Game.notify.emit(null, "Не хватает материалов.")
		return
	if not Inventory.can_add(r["out"], int(r["n"])):
		Game.notify.emit(null, "Рюкзак полон!")
		return
	for k in r["need"]:
		Inventory.remove(k, int(r["need"][k]))
	Inventory.add(r["out"], int(r["n"]))
	Audio.sfx("craft")
	Game.notify.emit(Db.icon(r["out"]), "Создано: " + Db.item_name(r["out"]))
	_set_tab(1)


# ------------------------------------------------------------------ жители
func _build_people() -> void:
	for id in Db.NPC_IDS:
		var d: Dictionary = Db.npcs[id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		content.add_child(row)
		var fr := PanelContainer.new()
		fr.add_theme_stylebox_override("panel", UiKit.tooltip_style())
		row.add_child(fr)
		var pr := TextureRect.new()
		pr.texture = Db.tex("portrait_" + id)
		pr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pr.custom_minimum_size = Vector2(32, 32)
		fr.add_child(pr)
		var info := VBoxContainer.new()
		info.add_theme_constant_override("separation", 0)
		info.custom_minimum_size = Vector2(110, 0)
		row.add_child(info)
		info.add_child(UiKit.label(d["name"], 11, UiKit.INK2))
		info.add_child(UiKit.label(d["role"], 9))
		var hearts := HBoxContainer.new()
		hearts.add_theme_constant_override("separation", 1)
		hearts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(hearts)
		for k in 10:
			var tr := TextureRect.new()
			tr.texture = UiKit.heart(k < Game.hearts(id))
			hearts.add_child(tr)
		var st := VBoxContainer.new()
		st.add_theme_constant_override("separation", 0)
		row.add_child(st)
		st.add_child(UiKit.label("Подарок сегодня: " + ("✓" if Game.gifted_today(id) else "—"), 9))
		var slot = Game.npc_slot(id)
		st.add_child(UiKit.label("Сейчас: " + ("дома" if slot == null else ("в деревне" if slot[2] == "village" else "у озера")), 9, UiKit.INK2))
	var note := UiKit.label("Разговор раз в день: +10 очков. Подарок: любимый +45, обычный +20, нелюбимый −20. 100 очков = 1 сердце.", 9, UiKit.INK2)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(380, 0)
	content.add_child(note)


# ------------------------------------------------------------------ мельница
func _build_mill() -> void:
	var done := 0
	for b in Db.bundles:
		if Game.bundle_done(b):
			done += 1
	content.add_child(UiKit.label("Восстановление мельницы: %d из 4 наборов. %s" % [done,
		"Мельница снова работает!" if Game.mill_fixed else "Приноси предметы к мельнице в деревне."], 10, UiKit.INK2))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	content.add_child(grid)
	for b in Db.bundles:
		grid.add_child(bundle_card(b, false))


func bundle_card(b: Dictionary, donate: bool) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.tooltip_style())
	p.custom_minimum_size = Vector2(186, 0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 1)
	p.add_child(vb)
	var ok := Game.bundle_done(b)
	vb.add_child(UiKit.label(b["name"] + ("  ✓ собрано" if ok else ""), 11, Color("7ee07e") if ok else UiKit.INK2))
	var row := HBoxContainer.new()
	vb.add_child(row)
	for item in b["need"]:
		var cell := HBoxContainer.new()
		cell.add_theme_constant_override("separation", 0)
		var tr := TextureRect.new()
		tr.texture = Db.icon(item)
		tr.mouse_filter = Control.MOUSE_FILTER_STOP
		tr.mouse_entered.connect(func(): game.show_tooltip(Db.item_name(item), "Сдано: %d/%d\nВ рюкзаке: %d" % [Game.bundle_have(b["id"], item), int(b["need"][item]), Inventory.count(item)]))
		tr.mouse_exited.connect(func(): game.hide_tooltip())
		cell.add_child(tr)
		cell.add_child(UiKit.label("%d/%d" % [Game.bundle_have(b["id"], item), int(b["need"][item])], 9))
		row.add_child(cell)
	var rw := "Награда: %d монет" % int(b["reward_money"])
	for k in b.get("reward", {}):
		rw += ", %s ×%d" % [Db.item_name(k), int(b["reward"][k])]
	vb.add_child(UiKit.label(rw, 8, UiKit.INK2))
	if donate and not ok:
		vb.add_child(UiKit.button("Отдать", func(): _donate(b), 9))
	return p


func _donate(b: Dictionary) -> void:
	pass
