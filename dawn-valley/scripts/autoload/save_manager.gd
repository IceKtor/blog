extends Node
## SaveManager — запись и чтение прогресса в JSON (каталог user://).

const SAVE_PATH := "user://savegame.json"
const SETTINGS_PATH := "user://settings.cfg"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var state := {
		"version": 1,
		"clock": GameClock.to_save(),
		"inventory": Inventory.to_save(),
		"economy": Economy.to_save(),
		"game": Game.to_save(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(state))


func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var result = JSON.parse_string(file.get_as_text())
	if not (result is Dictionary):
		return false
	GameClock.from_save(result.get("clock", {}))
	Inventory.from_save(result.get("inventory", []))
	Economy.from_save(result.get("economy", {}))
	Game.from_save(result.get("game", {}))
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func load_settings() -> ConfigFile:
	var c := ConfigFile.new()
	c.load(SETTINGS_PATH)
	return c


func save_settings(c: ConfigFile) -> void:
	c.save(SETTINGS_PATH)
