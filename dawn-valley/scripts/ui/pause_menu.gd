extends "res://scripts/ui/modal.gd"
## Меню паузы с настройками громкости и полноэкранного режима.

var in_main_menu := false
var settings_box: VBoxContainer


func _ready() -> void:
	add_dim(0.55)
	var p := centered_panel(Vector2(220, 0))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	p.add_child(vb)
	var t := UiKit.label("Настройки" if in_main_menu else "Пауза", 14, UiKit.INK2)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	if not in_main_menu:
		vb.add_child(UiKit.button("Продолжить", close))
	settings_box = VBoxContainer.new()
	vb.add_child(settings_box)
	_settings(settings_box)
	if not in_main_menu:
		vb.add_child(UiKit.label("Игра сохраняется каждую ночь,\nкогда ты ложишься спать.", 9, UiKit.INK2))
		vb.add_child(UiKit.button("Выйти в главное меню", _to_menu))
		vb.add_child(UiKit.button("Выйти из игры", func(): get_tree().quit()))
	else:
		vb.add_child(UiKit.button("Назад", close))


func _settings(box: VBoxContainer) -> void:
	for kind in [["Музыка", Audio.music_volume], ["Звуки", Audio.sfx_volume]]:
		var row := HBoxContainer.new()
		box.add_child(row)
		var l := UiKit.label(kind[0], 10)
		l.custom_minimum_size = Vector2(60, 0)
		row.add_child(l)
		var s := HSlider.new()
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.05
		s.value = kind[1]
		s.custom_minimum_size = Vector2(130, 12)
		s.focus_mode = Control.FOCUS_NONE
		s.set_meta("kind", kind[0])
		s.value_changed.connect(_on_volume.bind(s))
		row.add_child(s)
	var fs := CheckBox.new()
	fs.text = "Полный экран"
	fs.focus_mode = Control.FOCUS_NONE
	fs.add_theme_font_size_override("font_size", 10)
	fs.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fs.toggled.connect(func(on: bool):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED))
	box.add_child(fs)


func _on_volume(v: float, s: HSlider) -> void:
	if s.get_meta("kind") == "Музыка":
		Audio.set_volumes(v, Audio.sfx_volume)
	else:
		Audio.set_volumes(Audio.music_volume, v)
		Audio.sfx("click")


func _to_menu() -> void:
	game.dialog.ask("", null, "Выйти в главное меню? Прогресс текущего дня не сохранится.", ["Выйти", "Отмена"], func(i: int):
		if i == 0:
			game.go_to_menu())
