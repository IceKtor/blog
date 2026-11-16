extends Control
## Окно диалога: текст с печатью по буквам, портрет и имя собеседника, варианты ответа.

const UiKit = preload("res://scripts/ui/ui_kit.gd")

var game
var panel: PanelContainer
var text: Label
var name_label: Label
var portrait: TextureRect
var port_box: Control
var choices: VBoxContainer
var arrow: Label
var _lines := []
var _done := Callable()
var _choice_cb := Callable()
var _options := []
var _typing := 0.0
var _opened_frame := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel = UiKit.panel(Vector2(420, 70))
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.offset_bottom = -32
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(_on_panel_input)
	add_child(panel)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	panel.add_child(hb)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(left)
	text = UiKit.label("", 12)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.custom_minimum_size = Vector2(310, 0)
	left.add_child(text)
	choices = VBoxContainer.new()
	choices.add_theme_constant_override("separation", 2)
	left.add_child(choices)
	arrow = UiKit.label("▼", 9, UiKit.INK2)
	arrow.text = ">>"
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	left.add_child(arrow)
	port_box = VBoxContainer.new()
	hb.add_child(port_box)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiKit.tooltip_style())
	port_box.add_child(frame)
	portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(56, 56)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.add_child(portrait)
	name_label = UiKit.label("", 10, UiKit.INK2)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	port_box.add_child(name_label)
	visible = false


func is_open() -> bool:
	return visible


func say(who: String, tex: Texture2D, lines: Array, done := Callable()) -> void:
	_lines = lines.duplicate()
	_done = done
	_choice_cb = Callable()
	_options = []
	_open(who, tex)
	_next()


func ask(who: String, tex: Texture2D, question: String, options: Array, cb: Callable) -> void:
	_lines = []
	_done = Callable()
	_choice_cb = cb
	_options = options
	_open(who, tex)
	_show_text(question)


func _open(who: String, tex: Texture2D) -> void:
	if not visible:
		Game.push_pause()
	visible = true
	move_to_front()
	_opened_frame = Engine.get_process_frames()
	name_label.text = who
	portrait.texture = tex
	port_box.visible = tex != null
	Audio.sfx("open")


func _show_text(s: String) -> void:
	text.text = s
	text.visible_characters = 0
	_typing = 0.0
	for c in choices.get_children():
		c.queue_free()
	choices.visible = false
	arrow.visible = false


func _process(delta: float) -> void:
	if not visible:
		return
	if text.visible_characters >= 0 and text.visible_characters < text.text.length():
		_typing += delta * 70.0
		text.visible_characters = int(_typing)
		if text.visible_characters >= text.text.length():
			_finish_typing()


func _finish_typing() -> void:
	text.visible_characters = -1
	if _choice_cb.is_valid() and choices.get_child_count() == 0:
		choices.visible = true
		for i in _options.size():
			var b := UiKit.button("%d. %s" % [i + 1, _options[i]], _pick.bind(i), 10)
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			choices.add_child(b)
	else:
		arrow.visible = true


func _pick(i: int) -> void:
	var cb := _choice_cb
	_close()
	cb.call(i)


func _next() -> void:
	if _lines.is_empty():
		var d := _done
		_close()
		if d.is_valid():
			d.call()
		return
	_show_text(_lines.pop_front())


func _advance() -> void:
	if Engine.get_process_frames() == _opened_frame:
		return
	if text.visible_characters != -1:
		_finish_typing()
	elif not _choice_cb.is_valid():
		_next()


func _close() -> void:
	if visible:
		visible = false
		Game.pop_pause()


func _on_panel_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_advance()
		accept_event()


func _unhandled_input(e: InputEvent) -> void:
	if not visible:
		return
	if e is InputEventKey and e.pressed and not e.echo and _choice_cb.is_valid():
		var k: int = e.physical_keycode - KEY_1
		if k >= 0 and k < _options.size():
			if text.visible_characters != -1:
				_finish_typing()
			_pick(k)
			get_viewport().set_input_as_handled()
			return
	if e.is_action_pressed("use") or e.is_action_pressed("interact"):
		_advance()
		get_viewport().set_input_as_handled()
	elif e.is_action_pressed("pause") and _choice_cb.is_valid():
		var cb := _choice_cb
		_close()
		cb.call(_options.size() - 1)
		get_viewport().set_input_as_handled()
