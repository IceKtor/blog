extends PanelContainer
## Всплывающая подсказка рядом с курсором.

const UiKit = preload("res://scripts/ui/ui_kit.gd")
var title: Label
var body: Label


func _ready() -> void:
	add_theme_stylebox_override("panel", UiKit.tooltip_style())
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_level = true
	z_index = 100
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 1)
	add_child(vb)
	title = UiKit.label("", 11, UiKit.INK2)
	vb.add_child(title)
	body = UiKit.label("", 9)
	body.custom_minimum_size = Vector2(120, 0)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(body)
	visible = false


func show_text(t: String, b: String) -> void:
	title.text = t
	body.text = b
	body.visible = b != ""
	visible = true
	reset_size()
	_follow()


func _process(_d: float) -> void:
	if visible:
		_follow()


func _follow() -> void:
	var vp := get_viewport_rect().size
	var p := get_global_mouse_position() + Vector2(10, 10)
	if p.x + size.x > vp.x:
		p.x = get_global_mouse_position().x - size.x - 4
	if p.y + size.y > vp.y:
		p.y = vp.y - size.y - 2
	global_position = p.round()
