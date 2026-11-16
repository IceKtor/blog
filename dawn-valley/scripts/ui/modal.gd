extends Control
## Базовое модальное окно: затемнение фона, закрытие по Esc (через игровую сцену).

signal closed

const UiKit = preload("res://scripts/ui/ui_kit.gd")
const ItemSlot = preload("res://scripts/ui/item_slot.gd")

var game
var closable := true


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func add_dim(a := 0.45) -> void:
	var d := ColorRect.new()
	d.color = Color(0.05, 0.03, 0.08, a)
	d.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(d)


func centered_panel(min_size := Vector2.ZERO) -> PanelContainer:
	var p := UiKit.panel(min_size)
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(p)
	return p


func title_row(parent: Control, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var l := UiKit.label(text, 12, UiKit.INK)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(l)
	var x := UiKit.button("✕", close, 10)
	x.text = "X"
	row.add_child(x)
	return row


func close() -> void:
	if game:
		game.hide_tooltip()
	closed.emit()
	queue_free()
