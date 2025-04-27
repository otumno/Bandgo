extends Node

signal score_updated(new_score)
signal player_name_updated(new_name)
signal upgrades_updated()  # Новый сигнал для обновления UI

var player_name: String = "Player":
	set(value):
		player_name = value
		emit_signal("player_name_updated", value)

var score: int = 0:
	set(value):
		score = value
		emit_signal("score_updated", value)

var current_slot: int = 1

# --- НОВЫЕ ПЕРЕМЕННЫЕ ДЛЯ АПГРЕЙДОВ ---
var unlocked_instruments: Array[String] = []  # Список купленных инструментов (например, ["xylophone", "drum"])
var upgrade_levels: Dictionary = {}          # Уровни апгрейдов (например, {"xylophone_base": 2, "global_multiplier": 1})
var unlocked_combo_lines: Dictionary = {}    # Разблокированные строчки комбо (например, {"xylophone": [true, false, true]})

func reset():
	player_name = "Player"
	score = 0
	unlocked_instruments.clear()
	upgrade_levels.clear()
	unlocked_combo_lines.clear()
	emit_signal("score_updated", score)
	emit_signal("upgrades_updated")

# Добавляет очки (учитывает апгрейды)
func add_score(points: int):
	var multiplier = 1.0
	if upgrade_levels.has("global_multiplier"):
		multiplier += upgrade_levels["global_multiplier"] * 0.1  # +10% за уровень
	score += int(points * multiplier)
	emit_signal("score_updated", score)

# Покупка инструмента
func unlock_instrument(instrument_type: String):
	if not unlocked_instruments.has(instrument_type):
		unlocked_instruments.append(instrument_type)
		emit_signal("upgrades_updated")

# Повышение уровня апгрейда
func upgrade(upgrade_id: String, cost: int) -> bool:
	if score >= cost:
		if not upgrade_levels.has(upgrade_id):
			upgrade_levels[upgrade_id] = 1
		else:
			upgrade_levels[upgrade_id] += 1
		score -= cost
		emit_signal("score_updated", score)
		emit_signal("upgrades_updated")
		return true
	return false

# Разблокировка строчки комбо
func unlock_combo_line(instrument_type: String, line_index: int):
	if not unlocked_combo_lines.has(instrument_type):
		unlocked_combo_lines[instrument_type] = []
	if unlocked_combo_lines[instrument_type].size() <= line_index:
		unlocked_combo_lines[instrument_type].resize(line_index + 1)
	unlocked_combo_lines[instrument_type][line_index] = true
