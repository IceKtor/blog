extends Node
## Economy — монеты, покупка и ящик отгрузки (оплата на следующее утро).

signal money_changed(value: int)

var money := 500
var shipping := []   # [{"id", "n"}]


func add_money(v: int) -> void:
	money = maxi(0, money + v)
	money_changed.emit(money)


func can_afford(v: int) -> bool:
	return money >= v


func buy(id: String, price: int, n: int = 1) -> bool:
	if money < price * n or not Inventory.can_add(id, n):
		return false
	add_money(-price * n)
	Inventory.add(id, n)
	return true


func sell_price(id: String) -> int:
	return int(Db.item(id).get("price", 0))


func can_ship(id: String) -> bool:
	return sell_price(id) > 0 and not Db.is_tool(id)


func ship(id: String, n: int) -> void:
	for s in shipping:
		if s["id"] == id:
			s["n"] += n
			return
	shipping.append({"id": id, "n": n})


func shipping_value() -> int:
	var t := 0
	for s in shipping:
		t += sell_price(s["id"]) * int(s["n"])
	return t


## Вызывается ночью: продаёт содержимое ящика и возвращает отчёт.
func process_shipping() -> Dictionary:
	var lines := []
	var total := 0
	for s in shipping:
		var v := sell_price(s["id"]) * int(s["n"])
		lines.append({"id": s["id"], "n": s["n"], "value": v})
		total += v
	shipping.clear()
	add_money(total)
	return {"items": lines, "total": total}


func to_save() -> Dictionary:
	return {"money": money, "shipping": shipping.duplicate(true)}


func from_save(d: Dictionary) -> void:
	money = int(d.get("money", 500))
	shipping = []
	for s in d.get("shipping", []):
		shipping.append({"id": str(s["id"]), "n": int(s["n"])})
	money_changed.emit(money)
