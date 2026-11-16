extends Node
## GameClock — игровое время: 10 игровых минут = 7 секунд, день 06:00–24:00, 4 сезона по 28 дней.

signal minute_passed(hour: int, minute: int)
signal day_started(day: int, season: int, year: int)
signal season_changed(season: int)
signal time_up

const SECONDS_PER_TICK := 7.0
const DAY_START := 6 * 60
const DAY_END := 24 * 60
const DAYS_IN_SEASON := 28

var minutes := DAY_START
var day := 1
var season := 0
var year := 1
var running := false
var _timer := 0.0


func _process(delta: float) -> void:
	if not running or Game.is_paused():
		return
	_timer += delta
	if _timer >= SECONDS_PER_TICK:
		_timer -= SECONDS_PER_TICK
		minutes += 10
		minute_passed.emit(hour(), minutes % 60)
		if minutes >= DAY_END:
			running = false
			time_up.emit()


func next_day() -> void:
	minutes = DAY_START
	_timer = 0.0
	day += 1
	var new_season := false
	if day > DAYS_IN_SEASON:
		day = 1
		season += 1
		new_season = true
		if season > 3:
			season = 0
			year += 1
	if new_season:
		season_changed.emit(season)
	day_started.emit(day, season, year)


func hour() -> int:
	return minutes / 60


func abs_day() -> int:
	return (year - 1) * 112 + season * DAYS_IN_SEASON + day


func weekday() -> String:
	return Db.WEEKDAYS[(day - 1) % 7]


func time_text() -> String:
	return "%02d:%02d" % [hour() % 24, minutes % 60]


func season_key() -> String:
	return Db.SEASON_KEYS[season]


func reset() -> void:
	minutes = DAY_START
	day = 1
	season = 0
	year = 1
	_timer = 0.0


func to_save() -> Dictionary:
	return {"minutes": minutes, "day": day, "season": season, "year": year}


func from_save(d: Dictionary) -> void:
	minutes = int(d.get("minutes", DAY_START))
	day = int(d.get("day", 1))
	season = int(d.get("season", 0))
	year = int(d.get("year", 1))
	_timer = 0.0
