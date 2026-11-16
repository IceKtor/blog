extends Node
## Проверка: все скрипты и сцены загружаются без ошибок разбора.
func _ready() -> void:
	var bad := 0
	for dir in ["res://scripts", "res://scripts/autoload", "res://scripts/ui", "res://scenes"]:
		var d := DirAccess.open(dir)
		for f in d.get_files():
			if f.ends_with(".gd") or f.ends_with(".tscn"):
				var r = load(dir + "/" + f)
				if r == null:
					bad += 1
					print("FAIL ", f)
	print("checked, bad=", bad)
	get_tree().quit()
