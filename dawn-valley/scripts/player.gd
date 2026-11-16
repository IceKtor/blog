extends CharacterBody2D
## Игрок: движение в 4 направлениях, инструменты в клетке перед собой (или под курсором мыши), рыбалка.

const T := 16
const SPEED := 82.0
const DIRS := [Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1)]
const DIR_NAMES := ["down", "left", "right", "up"]
const COST := {"hoe": 2, "can": 1, "axe": 3, "pickaxe": 3, "rod": 2}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var tool_sprite: Sprite2D = $Tool
@onready var camera: Camera2D = $Camera2D
@onready var bang: Label = $Bang

var game
var loc
var dir := 0
var busy := 0.0
var fishing := ""        # "" | wait | bite
var fish_t := 0.0
var bobber := Vector2.ZERO
var _holding := false
var _hold_t := 0.0
var _mouse_t := 0.0
var _step_t := 0.0


func _ready() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var tex := Db.tex("player")
	for d in 4:
		for kind in ["walk", "idle", "use"]:
			var a := "%s_%s" % [kind, DIR_NAMES[d]]
			frames.add_animation(a)
			frames.set_animation_speed(a, 8.0)
			var cols := [0, 1, 2, 3] if kind == "walk" else ([0] if kind == "idle" else [4])
			for c in cols:
				var at := AtlasTexture.new()
				at.atlas = tex
				at.region = Rect2(c * 16, d * 32, 16, 32)
				frames.add_frame(a, at)
	anim.sprite_frames = frames
	anim.play("idle_down")
	bang.visible = false


func set_dir(d: int) -> void:
	dir = d
	anim.play("idle_" + DIR_NAMES[dir])


func feet_tile() -> Vector2i:
	return Vector2i(floori(global_position.x / T), floori((global_position.y - 3.0) / T))


func target_tile() -> Vector2i:
	var ft := feet_tile()
	if _mouse_t > 0.0:
		var mt: Vector2i = loc.tile_at(get_global_mouse_position())
		if absi(mt.x - ft.x) <= 1 and absi(mt.y - ft.y) <= 1:
			return mt
	return ft + DIRS[dir]


func _face_tile(t: Vector2i) -> void:
	var d := t - feet_tile()
	if d == Vector2i.ZERO:
		return
	if absi(d.x) > absi(d.y):
		dir = 2 if d.x > 0 else 1
	else:
		dir = 0 if d.y > 0 else 3


func can_act() -> bool:
	return not Game.is_paused() and not game.locked and busy <= 0.0 and fishing == ""


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		_mouse_t = 4.0
	if Game.is_paused() or game.locked:
		return
	if e.is_action_pressed("use"):
		if e is InputEventMouseButton:
			_mouse_t = 4.0
		if fishing != "":
			_reel()
		elif can_act():
			_holding = true
			_hold_t = 0.0
			use()
		get_viewport().set_input_as_handled()
	elif e.is_action_released("use"):
		_holding = false
	elif e.is_action_pressed("interact"):
		if e is InputEventMouseButton:
			_mouse_t = 4.0
		if can_act():
			interact()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	_mouse_t = maxf(0.0, _mouse_t - delta)
	if fishing != "":
		_fishing_tick(delta)
		return
	if Game.is_paused() or game.locked:
		velocity = Vector2.ZERO
		if not anim.animation.begins_with("use"):
			anim.play("idle_" + DIR_NAMES[dir])
		return
	if busy > 0.0:
		busy -= delta
		if busy <= 0.0:
			tool_sprite.visible = false
			anim.play("idle_" + DIR_NAMES[dir])
		return
	if _holding and Input.is_action_pressed("use") and Db.is_tool(Inventory.current_id()) and Inventory.current_id() != "rod":
		_hold_t += delta
		if _hold_t > 0.15:
			_hold_t = 0.0
			use()
			return
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if v.length() > 0.1:
		if absf(v.x) > absf(v.y) + 0.01:
			dir = 2 if v.x > 0 else 1
		else:
			dir = 0 if v.y > 0 else 3
		velocity = v.normalized() * SPEED
		move_and_slide()
		anim.play("walk_" + DIR_NAMES[dir])
		_step_t -= delta
		if _step_t <= 0.0:
			_step_t = 0.32
			Audio.sfx("step", 0.2)
		if get_slide_collision_count() > 0:
			var s = loc.door_at(feet_tile() + DIRS[dir])
			if s != null and s.get("action", "") in ["enter_house", "enter_mine"]:
				game.handle_action(s["action"], feet_tile() + DIRS[dir])
				return
		game.check_exit()
	else:
		velocity = Vector2.ZERO
		anim.play("idle_" + DIR_NAMES[dir])


# ------------------------------------------------------------------ действия
func use() -> void:
	var id := Inventory.current_id()
	var t := target_tile()
	_face_tile(t)
	if loc.is_ripe(t) and not Db.is_tool(id):
		loc.harvest(t)
		_pose(0.2)
		return
	if id == "":
		interact()
		return
	var it := Db.item(id)
	match it.get("cat", ""):
		"tool":
			if id == "rod":
				_cast(t)
			else:
				_swing(id, t)
		"seed":
			if not loc.plant(id, t):
				interact()
		_:
			if id in loc.PLACEABLE:
				if t == feet_tile() or not loc.place(id, t):
					interact()
			elif it.has("energy"):
				game.ask_eat(id)
			else:
				interact()


func interact() -> void:
	var t := target_tile()
	var front := global_position + Vector2(DIRS[dir]) * 14.0 + Vector2(0, -4)
	for n in loc.npcs.values():
		if n.global_position.distance_to(front) < 15.0 or n.global_position.distance_to(loc.world_pos(t) + Vector2(0, 6)) < 12.0:
			game.talk_to(n)
			return
	_face_tile(t)
	var r: String = loc.interact(t)
	if r == "" and t != feet_tile() + DIRS[dir]:
		r = loc.interact(feet_tile() + DIRS[dir])
	if r != "" and r != "done":
		game.handle_action(r, t)


func _pose(time: float) -> void:
	busy = time
	anim.play("use_" + DIR_NAMES[dir])


func _swing(id: String, t: Vector2i) -> void:
	_pose(0.3)
	tool_sprite.texture = Db.icon(id)
	tool_sprite.visible = true
	var base: Vector2 = [Vector2(5, -10), Vector2(-8, -14), Vector2(8, -14), Vector2(5, -22)][dir]
	tool_sprite.position = base
	tool_sprite.flip_h = dir == 1
	tool_sprite.z_index = 0 if dir == 3 else 1
	var a0 := -1.6 if dir != 1 else 1.6
	var a1 := 0.5 if dir != 1 else -0.5
	tool_sprite.rotation = a0
	var tw := create_tween()
	tw.tween_property(tool_sprite, "rotation", a1, 0.14).set_trans(Tween.TRANS_BACK)
	tw.tween_callback(func(): loc.use_tool(id, t))


# ------------------------------------------------------------------ рыбалка
func _cast(t: Vector2i) -> void:
	var water_t := t
	if not loc.is_water(water_t):
		water_t = t + DIRS[dir]
		if not loc.is_water(water_t):
			Game.notify.emit(null, "Встань лицом к воде.")
			return
	if not Game.spend(COST["rod"]):
		return
	Audio.sfx("cast")
	fishing = "wait"
	fish_t = randf_range(1.5, 5.0)
	bobber = loc.world_pos(water_t)
	anim.play("use_" + DIR_NAMES[dir])
	tool_sprite.texture = Db.icon("rod")
	tool_sprite.visible = true
	tool_sprite.rotation = 0.3 if dir != 1 else -0.3
	tool_sprite.flip_h = dir == 1
	queue_redraw()


func _fishing_tick(delta: float) -> void:
	velocity = Vector2.ZERO
	queue_redraw()
	if Game.is_paused():
		return
	fish_t -= delta
	if fishing == "wait" and fish_t <= 0.0:
		fishing = "bite"
		fish_t = 1.0
		bang.visible = true
		Audio.sfx("bite")
	elif fishing == "bite" and fish_t <= 0.0:
		_end_fishing()
		Game.notify.emit(null, "Рыба сорвалась…")
		Audio.sfx("fail")


func _reel() -> void:
	if fishing == "bite":
		var fish_id: String = game.pick_fish()
		_end_fishing()
		game.start_fishing(fish_id)
	else:
		_end_fishing()


func _end_fishing() -> void:
	fishing = ""
	bang.visible = false
	tool_sprite.visible = false
	anim.play("idle_" + DIR_NAMES[dir])
	queue_redraw()


func _draw() -> void:
	if fishing == "":
		return
	var b := to_local(bobber) + Vector2(0, sin(Time.get_ticks_msec() / 200.0) + (2.0 if fishing == "bite" else 0.0))
	var hand := tool_sprite.position + Vector2(8 if dir != 1 else -8, -6)
	draw_line(hand, b, Color(1, 1, 1, 0.6), 1.0)
	draw_circle(b, 2.5, Color("eef3f8"))
	draw_circle(b + Vector2(0, -1), 1.5, Color("c42c34"))
