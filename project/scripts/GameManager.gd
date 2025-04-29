extends Node

# Сигналы
signal score_updated(new_score)
signal player_name_updated(new_name)
signal upgrades_updated()
signal instrument_unlocked(instrument_type: String)
signal instrument_upgraded(instrument_type: String, level: int)

# Переменные состояния
var player_name: String = "Player":
	set(value):
		player_name = value
		emit_signal("player_name_updated", value)

var score: int = 0:
	set(value):
		score = value
		emit_signal("score_updated", value)

var current_slot: int = 1
var unlocked_instruments: Array[String] = []
var upgrade_levels: Dictionary = {}
var unlocked_combo_lines: Dictionary = {}

func _ready():
	load_default_settings()

func load_default_settings():
	player_name = "Player"
	score = 0
	unlocked_instruments.clear()
	upgrade_levels.clear()
	unlocked_combo_lines.clear()

func reset():
	load_default_settings()
	emit_signal("score_updated", score)
	emit_signal("upgrades_updated")

func add_score(points: int):
	var multiplier = 1.0
	if upgrade_levels.has("global_multiplier"):
		multiplier += upgrade_levels["global_multiplier"] * 0.1
	score += int(points * multiplier)
	emit_signal("score_updated", score)

func get_instrument_level(instrument_type: String) -> int:
	return upgrade_levels.get(instrument_type + "_unlock", 0)

func can_upgrade_instrument(instrument_type: String) -> bool:
	var current_level = get_instrument_level(instrument_type)
	var settings = GlobalBalanceManager.instrument_levels.get(instrument_type, {})
	return current_level < settings.get("levels", []).size()

func get_next_upgrade_cost(instrument_type: String) -> int:
	var current_level = get_instrument_level(instrument_type)
	var settings = GlobalBalanceManager.upgrades_settings.get(instrument_type + "_unlock", {})
	var costs = settings.get("cost_per_level", [])
	return costs[current_level] if current_level < costs.size() else -1

func upgrade(upgrade_id: String, cost: int) -> bool:
	if score < cost:
		return false
	
	if upgrade_id.ends_with("_unlock"):
		var instrument_type = upgrade_id.split("_")[0]
		var new_level = upgrade_levels.get(upgrade_id, 0) + 1
		
		upgrade_levels[upgrade_id] = new_level
		score -= cost
		
		if new_level == 1:
			unlocked_instruments.append(instrument_type)
			emit_signal("instrument_unlocked", instrument_type)
		
		emit_signal("instrument_upgraded", instrument_type, new_level)
		emit_signal("score_updated", score)
		emit_signal("upgrades_updated")
		return true
	
	if not upgrade_levels.has(upgrade_id):
		upgrade_levels[upgrade_id] = 1
	else:
		upgrade_levels[upgrade_id] += 1
	
	score -= cost
	emit_signal("score_updated", score)
	
	var settings = GlobalBalanceManager.upgrades_settings.get(upgrade_id, {})
	if settings.has("unlocks_pattern_line"):
		var line_index = settings["unlocks_pattern_line"][upgrade_levels[upgrade_id] - 1]
		var instrument_type = upgrade_id.split("_")[0]
		unlock_combo_line(instrument_type, line_index)
	
	emit_signal("upgrades_updated")
	return true

func unlock_combo_line(instrument_type: String, line_index: int):
	if not unlocked_combo_lines.has(instrument_type):
		unlocked_combo_lines[instrument_type] = []
	
	if unlocked_combo_lines[instrument_type].size() <= line_index:
		unlocked_combo_lines[instrument_type].resize(line_index + 1)
	
	unlocked_combo_lines[instrument_type][line_index] = true

func get_save_data() -> Dictionary:
	return {
		"version": 2,
		"player_name": player_name,
		"score": score,
		"unlocked_instruments": unlocked_instruments,
		"upgrade_levels": upgrade_levels,
		"unlocked_combo_lines": unlocked_combo_lines
	}

func load_save_data(data: Dictionary):
	player_name = data.get("player_name", "Player")
	score = data.get("score", 0)
	unlocked_instruments = data.get("unlocked_instruments", [])
	upgrade_levels = data.get("upgrade_levels", {})
	unlocked_combo_lines = data.get("unlocked_combo_lines", {})
	emit_signal("score_updated", score)
	emit_signal("upgrades_updated")
