extends "res://scripts/ui/modal.gd"
## Мини-игра рыбалки: удерживай кнопку, чтобы зелёная зона держала рыбу. Заполни шкалу улова.

signal finished(success: bool)

const H := 150.0
var fish_id := ""
var difficulty := 30.0
var bar_pos := 0.0       # низ зелёной зоны (0 — дно)
var bar_vel := 0.0
var bar_h := 40.0
var fish_pos := 60.0
var fish_target := 60.0
var fish_speed := 30.0
var progress := 0.3
var _t := 0.0
var _done := false
var meter: Control


func _ready() -> void:
	add_dim(0.25)
	difficulty = float(Db.fish[fish_id]["difficulty"])
	bar_h = lerpf(52.0, 26.0, difficulty / 100.0)
	fish_speed = lerpf(25.0, 95.0, difficulty / 100.0)
	var p := centered_panel()
	var vb := VBoxContainer.new()
	p.add_child(vb)
	vb.add_child(UiKit.label("Клюёт!", 11, UiKit.INK2))
	meter = _Meter.new()
	meter.ui = self
	meter.custom_minimum_size = Vector2(46, H + 6)
	vb.add_child(meter)
	vb.add_child(UiKit.label("Держи\nкнопку", 8))
	closable = false


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	var holding := Input.is_action_pressed("use")
	bar_vel += (220.0 if holding else -240.0) * delta
	bar_vel = clampf(bar_vel, -170.0, 170.0)
	bar_pos += bar_vel * delta
	if bar_pos < 0.0:
		bar_pos = 0.0
		bar_vel = -bar_vel * 0.35
	if bar_pos > H - bar_h:
		bar_pos = H - bar_h
		bar_vel = -bar_vel * 0.25
	if absf(fish_pos - fish_target) < 3.0 or randf() < delta * (0.4 + difficulty / 60.0):
		fish_target = randf_range(4.0, H - 8.0)
	fish_pos = move_toward(fish_pos, fish_target, fish_speed * delta * (1.0 + 0.5 * sin(_t * 3.0)))
	var inside := fish_pos >= bar_pos and fish_pos <= bar_pos + bar_h
	progress += (0.32 if inside else -0.22) * delta
	meter.queue_redraw()
	if progress >= 1.0:
		_finish(true)
	elif progress <= 0.0:
		_finish(false)


func _finish(ok: bool) -> void:
	_done = true
	finished.emit(ok)
	close()


class _Meter extends Control:
	var ui
	func _draw() -> void:
		var h: float = ui.H
		var r := Rect2(2, 2, 26, h + 2)
		draw_rect(r.grow(2), Color("3b1d1a"))
		draw_rect(r, Color("24508c"))
		draw_rect(Rect2(3, 3, 24, h), Color("2e6aa8"))
		var by: float = 3 + h - ui.bar_pos - ui.bar_h
		draw_rect(Rect2(4, by, 22, ui.bar_h), Color(0.4, 0.85, 0.35, 0.85))
		draw_rect(Rect2(4, by, 22, 2), Color("c4ec6a"))
		draw_texture(Db.icon(ui.fish_id), Vector2(7, 3 + h - ui.fish_pos - 8))
		var pr := Rect2(34, 2, 8, h + 2)
		draw_rect(pr.grow(1), Color("3b1d1a"))
		draw_rect(pr, Color("6b3824"))
		var ph: float = (h + 2) * clampf(ui.progress, 0.0, 1.0)
		var col := Color("d84a3c").lerp(Color("64aa40"), clampf(ui.progress, 0.0, 1.0))
		draw_rect(Rect2(34, 4 + h - ph, 8, ph), col)
