extends Control
## Ячейка предмета: фон, иконка, количество, полоска воды у лейки.

signal clicked(slot: Control, button: int)
signal hovered(slot: Control, on: bool)

const UiKit = preload("res://scripts/ui/ui_kit.gd")

var item = null
var selected := false
var index := -1
var hotkey := ""
var dim := false


func _init() -> void:
	custom_minimum_size = Vector2(18, 18)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func(): hovered.emit(self, true))
	mouse_exited.connect(func(): hovered.emit(self, false))


func set_item(v, sel := false) -> void:
	item = v
	selected = sel
	queue_redraw()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and (e.button_index == MOUSE_BUTTON_LEFT or e.button_index == MOUSE_BUTTON_RIGHT):
		clicked.emit(self, e.button_index)
		accept_event()


func _draw() -> void:
	draw_texture(UiKit.ui_region(Rect2(50 if selected else 32, 0, 18, 18)), Vector2.ZERO)
	if item != null:
		var c := Color(1, 1, 1, 0.4) if dim else Color.WHITE
		draw_texture(Db.icon(item["id"]), Vector2(1, 1), c)
		var n := int(item["n"])
		var f := UiKit.font()
		if n > 1:
			var s := str(n)
			var wdt := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			var p := Vector2(17 - wdt, 17)
			draw_string_outline(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, 2, Color("1e1e2a"))
			draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
		if item["id"] == "can":
			var k := float(Game.can_water) / Game.CAN_SIZE
			draw_rect(Rect2(2, 15, 14, 2), Color("1c3466"))
			draw_rect(Rect2(2, 15, 14 * k, 2), Color("4a8cc4"))
	if hotkey != "":
		var f := UiKit.font()
		draw_string(f, Vector2(2, 7), hotkey, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("8a96b0"))
