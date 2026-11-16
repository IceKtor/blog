extends Node
## Audio — фоновая музыка по сезонам и звуки действий.

var music := AudioStreamPlayer.new()
var _pool := []
var _cache := {}
var _track := ""
var music_volume := 0.7
var sfx_volume := 0.8


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(music)
	music.finished.connect(func(): music.play())
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	var c := SaveManager.load_settings()
	music_volume = c.get_value("audio", "music", 0.7)
	sfx_volume = c.get_value("audio", "sfx", 0.8)
	_apply()


func _stream(name: String) -> AudioStream:
	if not _cache.has(name):
		var path := "res://assets/audio/%s.wav" % name
		_cache[name] = load(path) if ResourceLoader.exists(path) else null
	return _cache[name]


func play_music(name: String) -> void:
	if name == _track:
		return
	_track = name
	var s := _stream(name)
	if s == null:
		music.stop()
		return
	var tw := create_tween()
	if music.playing:
		tw.tween_property(music, "volume_db", -40.0, 0.6)
	tw.tween_callback(func():
		music.stream = s
		music.play())
	tw.tween_property(music, "volume_db", _db(music_volume) - 6.0, 0.8)


func stop_music() -> void:
	_track = ""
	music.stop()


func sfx(name: String, pitch_var := 0.08) -> void:
	var s := _stream(name)
	if s == null:
		return
	for p in _pool:
		if not p.playing:
			p.stream = s
			p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
			p.volume_db = _db(sfx_volume)
			p.play()
			return


func set_volumes(m: float, s: float) -> void:
	music_volume = m
	sfx_volume = s
	_apply()
	var c := SaveManager.load_settings()
	c.set_value("audio", "music", m)
	c.set_value("audio", "sfx", s)
	SaveManager.save_settings(c)


func _apply() -> void:
	music.volume_db = _db(music_volume) - 6.0


func _db(v: float) -> float:
	return linear_to_db(maxf(v, 0.001))
