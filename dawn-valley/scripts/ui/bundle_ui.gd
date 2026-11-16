extends "res://scripts/ui/game_menu.gd"
## Окно мельницы: сдача наборов (наследует карточки из меню).

func _ready() -> void:
	add_dim()
	var p := centered_panel(Vector2(400, 0))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	p.add_child(vb)
	title_row(vb, "Мельница — помоги Марфе восстановить её")
	content = VBoxContainer.new()
	vb.add_child(content)
	held_icon = Control.new()
	_rebuild()


func _rebuild() -> void:
	for c in content.get_children():
		c.queue_free()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	content.add_child(grid)
	for b in Db.bundles:
		grid.add_child(bundle_card(b, true))
	content.add_child(UiKit.label("Нажми «Отдать», чтобы сдать подходящие предметы из рюкзака.", 9, UiKit.INK2))


func _donate(b: Dictionary) -> void:
	var has_any := false
	for item in b["need"]:
		if Inventory.count(item) > 0 and Game.bundle_have(b["id"], item) < int(b["need"][item]):
			has_any = true
	if not has_any:
		Audio.sfx("error")
		Game.notify.emit(null, "Нет подходящих предметов.")
		return
	var finished := Game.donate(b)
	if finished:
		Game.notify.emit(null, "Набор «%s» собран!" % b["name"])
	if Game.mill_fixed:
		close()
		game.celebrate_mill()
		return
	_rebuild()
