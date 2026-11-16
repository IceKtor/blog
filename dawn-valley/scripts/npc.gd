extends CharacterBody2D
## Житель деревни: бродит в своей зоне по расписанию, останавливается при разговоре.

const T := 16
var id := ""
var loc
var area := Rect2i()
var sprite: Sprite2D
var dir := 0
var target := Vector2.ZERO
var wait := 1.0
var stop_t := 0.0
var stuck := 0.0
var anim_t := 0.0


func setup(npc_id: String, location, a: Rect2i) -> void:
	id = npc_id
	loc = location
	area = a
	var t: Vector2i = loc.random_free_tile(area)
	position = Vector2(t.x * T + 8, t.y * T + 14)
	target = position
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(10, 6)
	shape.shape = r
	shape.position = Vector2(0, -3)
	add_child(shape)
	sprite = Sprite2D.new()
	sprite.texture = Db.tex(id)
	sprite.hframes = 5
	sprite.vframes = 4
	sprite.centered = false
	sprite.offset = Vector2(-8, -31)
	add_child(sprite)


func display_name() -> String:
	return Db.npcs[id]["name"]


func face(p: Vector2) -> void:
	var d := p - global_position
	if absf(d.x) > absf(d.y):
		dir = 2 if d.x > 0 else 1
	else:
		dir = 0 if d.y > 0 else 3
	stop_t = 4.0
	sprite.frame = dir * 5


func _physics_process(delta: float) -> void:
	if Game.is_paused() or stop_t > 0.0:
		stop_t = maxf(0.0, stop_t - delta) if not Game.is_paused() else stop_t
		velocity = Vector2.ZERO
		sprite.frame = dir * 5
		return
	if wait > 0.0:
		wait -= delta
		sprite.frame = dir * 5
		return
	var to := target - global_position
	if to.length() < 2.0 or stuck > 1.0:
		stuck = 0.0
		wait = randf_range(2.0, 6.0)
		var t: Vector2i = loc.random_free_tile(area)
		target = Vector2(t.x * T + 8, t.y * T + 12)
		return
	velocity = to.normalized() * 26.0
	var before := global_position
	move_and_slide()
	if global_position.distance_to(before) < 0.2:
		stuck += delta
	if absf(to.x) > absf(to.y):
		dir = 2 if to.x > 0 else 1
	else:
		dir = 0 if to.y > 0 else 3
	anim_t += delta
	sprite.frame = dir * 5 + int(anim_t * 6.0) % 4
