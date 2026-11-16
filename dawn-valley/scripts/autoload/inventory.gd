extends Node
## Inventory — 30 ячеек, первые 10 — панель быстрого доступа.

signal changed
signal selected_changed(index: int)

const SIZE := 30
const HOTBAR := 10
const MAX_STACK := 999

var slots := []
var selected := 0


func _init() -> void:
	clear()


func clear() -> void:
	slots.clear()
	for i in SIZE:
		slots.append(null)
	selected = 0


func select(i: int) -> void:
	selected = posmod(i, HOTBAR)
	selected_changed.emit(selected)


func current():
	return slots[selected]


func current_id() -> String:
	var s = slots[selected]
	return "" if s == null else s["id"]


## Добавляет предметы, возвращает сколько не поместилось.
func add(id: String, n: int = 1) -> int:
	if Db.stackable(id):
		for i in SIZE:
			var s = slots[i]
			if s != null and s["id"] == id and s["n"] < MAX_STACK:
				var k := mini(n, MAX_STACK - int(s["n"]))
				s["n"] += k
				n -= k
				if n <= 0:
					break
	while n > 0:
		var free := slots.find(null)
		if free == -1:
			break
		var k := mini(n, MAX_STACK) if Db.stackable(id) else 1
		slots[free] = {"id": id, "n": k}
		n -= k
	changed.emit()
	return n


func can_add(id: String, n: int = 1) -> bool:
	if slots.has(null):
		return true
	if Db.stackable(id):
		for s in slots:
			if s != null and s["id"] == id and int(s["n"]) + n <= MAX_STACK:
				return true
	return false


func count(id: String) -> int:
	var c := 0
	for s in slots:
		if s != null and s["id"] == id:
			c += int(s["n"])
	return c


func has(id: String, n: int = 1) -> bool:
	return count(id) >= n


func remove(id: String, n: int = 1) -> bool:
	if count(id) < n:
		return false
	for i in SIZE:
		var s = slots[i]
		if n <= 0:
			break
		if s != null and s["id"] == id:
			var k := mini(n, int(s["n"]))
			s["n"] -= k
			n -= k
			if s["n"] <= 0:
				slots[i] = null
	changed.emit()
	return true


func take_slot(i: int, n: int = 1) -> void:
	var s = slots[i]
	if s == null:
		return
	s["n"] -= n
	if s["n"] <= 0:
		slots[i] = null
	changed.emit()


func set_slot(i: int, v) -> void:
	slots[i] = v
	changed.emit()


func to_save() -> Array:
	return slots.duplicate(true)


func from_save(a: Array) -> void:
	clear()
	for i in mini(a.size(), SIZE):
		var s = a[i]
		if s != null:
			slots[i] = {"id": str(s["id"]), "n": int(s["n"])}
	changed.emit()
