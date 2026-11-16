extends "res://scripts/ui/modal.gd"
## Итоги дня: проданные из ящика предметы и выручка.

var report := {}


func _ready() -> void:
	add_dim(0.0)
	var p := centered_panel(Vector2(260, 0))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	p.add_child(vb)
	var t := UiKit.label("Итоги дня", 14, UiKit.INK2)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	if report.get("passed_out", false):
		vb.add_child(UiKit.label("Ты уснул от усталости. Сегодня сил будет меньше.", 9, Color("ac2a30")))
	var items: Array = report.get("items", [])
	if items.is_empty():
		vb.add_child(UiKit.label("Вчера ничего не было отгружено.", 10))
	for it in items:
		var row := HBoxContainer.new()
		vb.add_child(row)
		var tr := TextureRect.new()
		tr.texture = Db.icon(it["id"])
		row.add_child(tr)
		var l := UiKit.label("%s ×%d" % [Db.item_name(it["id"]), int(it["n"])], 10)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		row.add_child(UiKit.label(str(int(it["value"])), 10, UiKit.INK2))
	var tot := HBoxContainer.new()
	vb.add_child(tot)
	var tl := UiKit.label("Выручка:", 11)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tot.add_child(tl)
	tot.add_child(UiKit.label("%d монет" % int(report.get("total", 0)), 11, Color("2e723a")))
	vb.add_child(UiKit.label("%s, день %d. Игра сохранена." % [Db.SEASONS[GameClock.season], GameClock.day], 9, UiKit.INK2))
	vb.add_child(UiKit.button("Доброе утро!", close))
	if int(report.get("total", 0)) > 0:
		Audio.sfx("coin")
