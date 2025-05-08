extends Node
# Главный менеджер игры (автозагружается как синглтон)

signal score_updated(new_score)
signal player_name_updated(new_name)
signal upgrades_updated()
signal instrument_unlocked(instrument_type: String)
signal instrument_upgraded(instrument_type: String, level: int)

# Основные игровые переменные
var player_name: String = "Player":
	set(value):
		if value != player_name:
			player_name = value
			emit_signal("player_name_updated", value)

var score: int = 0:
	set(value):
		if value != score:
			score = value
			emit_signal("score_updated", value)

# Система слотов сохранения
var current_slot: int = 1:
	set(value):
		if current_slot != value:
			SaveSystem.save_game(current_slot)  # Сохраняем текущий слот
			current_slot = value
			if not SaveSystem.load_game(current_slot):  # Загружаем новый
				reset()

# Коллекции игровых данных
var unlocked_instruments: Array[String] = []       # Разблокированные инструменты
var upgrade_levels: Dictionary = {}                # Уровни улучшений (например, {"xylophone_unlock": 2})
var unlocked_combo_lines: Dictionary = {}          # Открытые паттерны (например, {"xylophone": 3})

func _ready():
	load_default_settings()
	print("GameManager initialized for slot ", current_slot)

# Сброс к начальным настройкам
func load_default_settings():
	player_name = "Player"
	score = 0
	unlocked_instruments.clear()
	upgrade_levels.clear()
	unlocked_combo_lines.clear()
	print("Default settings loaded")

func reset():
	load_default_settings()
	emit_signal("score_updated", score)
	emit_signal("upgrades_updated")
	print("Game state reset")

# Добавление очков с учетом множителей
func add_score(points: int):
	if points <= 0:
		return
	
	var multiplier = 1.0
	if upgrade_levels.has("global_multiplier"):
		multiplier += upgrade_levels["global_multiplier"] * 0.1
	
	var final_points = int(points * multiplier)
	score += final_points
	emit_signal("score_updated", score)
	print("Added score: ", final_points, " (base: ", points, " multiplier: ", multiplier, ")")

# Получение уровня инструмента
func get_instrument_level(instrument_type: String) -> int:
	if instrument_type.is_empty():
		push_error("Empty instrument_type!")
		return 0
	return upgrade_levels.get(instrument_type + "_unlock", 0)

# Основная функция улучшений
func upgrade(upgrade_id: String, cost: int) -> bool:
	if upgrade_id.is_empty():
		push_error("Empty upgrade_id!")
		return false
	
	if score < cost:
		print("Not enough points for upgrade ", upgrade_id, " (needed: ", cost, ")")
		return false
	
	# 1. Обработка разблокировки инструментов
	if upgrade_id.ends_with("_unlock"):
		var instrument_type = upgrade_id.split("_")[0]
		if instrument_type.is_empty():
			push_error("Invalid upgrade format: ", upgrade_id)
			return false
			
		var new_level = upgrade_levels.get(upgrade_id, 0) + 1
		upgrade_levels[upgrade_id] = new_level
		score -= cost
		
		if new_level == 1:  # Первый уровень = разблокировка
			unlocked_instruments.append(instrument_type)
			emit_signal("instrument_unlocked", instrument_type)
			print("Instrument unlocked: ", instrument_type)
		
		emit_signal("instrument_upgraded", instrument_type, new_level)
		emit_signal("upgrades_updated")
		print("Upgraded ", instrument_type, " to level ", new_level)
		return true
	
	# 2. Обработка комбо-апгрейдов
	if upgrade_id.ends_with("_combo"):
		var instrument_type = upgrade_id.split("_")[0]
		if instrument_type.is_empty():
			return false
			
		var new_level = upgrade_levels.get(upgrade_id, 0) + 1
		upgrade_levels[upgrade_id] = new_level
		score -= cost
		
		# Разблокируем паттерн из GlobalBalanceManager
		var settings = GlobalBalanceManager.upgrades_settings.get(upgrade_id, {})
		if settings.has("unlocks_pattern_line"):
			var pattern_to_unlock = settings["unlocks_pattern_line"][new_level - 1]
			unlock_combo_line(instrument_type, pattern_to_unlock)
		
		emit_signal("upgrades_updated")
		print("Combo upgraded: ", instrument_type, " to level ", new_level)
		return true
	
	# 3. Обычные улучшения (глобальные)
	if not upgrade_levels.has(upgrade_id):
		upgrade_levels[upgrade_id] = 1
	else:
		upgrade_levels[upgrade_id] += 1
	
	score -= cost
	emit_signal("score_updated", score)
	emit_signal("upgrades_updated")
	print("Upgrade applied: ", upgrade_id, " level ", upgrade_levels[upgrade_id])
	return true

# Разблокировка линии комбо (паттерна)
func unlock_combo_line(instrument_type: String, line_index: int):
	if instrument_type.is_empty():
		push_error("Empty instrument_type in unlock_combo_line!")
		return
	
	if not unlocked_combo_lines.has(instrument_type):
		unlocked_combo_lines[instrument_type] = []
	
	if unlocked_combo_lines[instrument_type].size() <= line_index:
		unlocked_combo_lines[instrument_type].resize(line_index + 1)
	
	unlocked_combo_lines[instrument_type][line_index] = true
	print("Combo line unlocked: ", instrument_type, " line ", line_index)

# Подготовка данных для сохранения
func get_save_data() -> Dictionary:
	return {
		"version": 2,
		"player_name": player_name,
		"score": score,
		"unlocked_instruments": unlocked_instruments,
		"upgrade_levels": upgrade_levels,
		"unlocked_combo_lines": unlocked_combo_lines
	}

# Загрузка сохраненных данных
func load_save_data(data: Dictionary):
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Invalid save data format!")
		return
	
	player_name = data.get("player_name", "Player")
	score = data.get("score", 0)
	unlocked_instruments = data.get("unlocked_instruments", [])
	upgrade_levels = data.get("upgrade_levels", {})
	unlocked_combo_lines = data.get("unlocked_combo_lines", {})
	
	emit_signal("score_updated", score)
	emit_signal("upgrades_updated")
	print("Game state loaded from save data")
