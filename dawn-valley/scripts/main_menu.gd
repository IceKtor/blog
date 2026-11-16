extends Control
## Главное меню: новая игра, продолжить, настройки, выход.

const UiKit = preload("res://scripts/ui/ui_kit.gd")
const PauseMenu = preload("res://scripts/ui/pause_menu.gd")

var buttons: VBoxContainer
var clouds := []


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = Db.tex("title_bg")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	add_child(bg)
	var title := UiKit.label("Рассветная долина", 32, Color("fff4c0"), true)
	title.add_theme_constant_override("outline_size", 8)
	title.add_theme_color_override("font_outline_color", Color("6b3824"))
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	title.offset_top = 22
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	var sub := UiKit.label("симулятор фермерства", 12, Color("fff4e0"), true)
	sub.set_anchors_preset(Control.PRESET_CENTER_TOP)
	sub.grow_horizontal = Control.GROW_DIRECTION_BOTH
	sub.offset_top = 62
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)
	var p := UiKit.panel(Vector2(150, 0))
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	p.offset_top = 30
	p.offset_bottom = 30
	add_child(p)
	buttons = VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 4)
	p.add_child(buttons)
	_main_buttons()
	var foot := UiKit.label("Godot 4 · дипломный проект", 9, Color("fff4e0"), true)
	foot.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	foot.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	foot.grow_vertical = Control.GROW_DIRECTION_BEGIN
	foot.offset_right = -6
	foot.offset_bottom = -4
	add_child(foot)
	Audio.play_music("music_spring")


func _clear() -> void:
	for c in buttons.get_children():
		buttons.remove_child(c)
		c.queue_free()


func _main_buttons() -> void:
	_clear()
	buttons.add_child(UiKit.button("Новая игра", _new_game, 12))
	var cont := UiKit.button("Продолжить", _continue, 12)
	cont.disabled = not SaveManager.has_save()
	buttons.add_child(cont)
	buttons.add_child(UiKit.button("Настройки", _settings, 12))
	buttons.add_child(UiKit.button("Выход", func(): get_tree().quit(), 12))


func _new_game() -> void:
	if SaveManager.has_save():
		_clear()
		var l := UiKit.label("Начать заново?\nСтарое сохранение\nбудет удалено.", 10)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		buttons.add_child(l)
		buttons.add_child(UiKit.button("Да, начать", _start_new, 11))
		buttons.add_child(UiKit.button("Назад", _main_buttons, 11))
	else:
		_start_new()


func _start_new() -> void:
	SaveManager.delete_save()
	Game.new_game()
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _continue() -> void:
	if SaveManager.load_game():
		get_tree().change_scene_to_file("res://scenes/game.tscn")


func _settings() -> void:
	var m := PauseMenu.new()
	m.in_main_menu = true
	add_child(m)
