extends Node

@export_category("Game Balance")
@export var instrument_settings: Dictionary = {
	"default": {
		"points_per_click": 10,
		"combo_window_seconds": 2.0,
		"combo_multipliers": [1, 2, 3, 5, 8],
		"allow_multiple_hits": false
	},
	"xylophone": {
		"points_per_click": 15,
		"combo_multipliers": [1, 2, 3, 5, 8, 10, 12]
	}
}

# --- Новые настройки апгрейдов ---
@export var upgrades_settings: Dictionary = {
	# Апгрейды инструментов
	"xylophone_base": {
		"name": "Xylophone Power",
		"cost_per_level": [100, 200, 300],  # Стоимость каждого уровня
		"bonus_per_level": [5, 10, 15]      # +5 очков за уровень
	},
	"xylophone_combo": {
		"name": "Xylophone Combo",
		"cost_per_level": [150, 300],
		"unlocks_pattern_line": [1, 3]  # Разблокирует 2-ю и 4-ю строчки паттерна
	},
	# Общие апгрейды
	"global_multiplier": {
		"name": "Global Multiplier",
		"cost_per_level": [500, 1000],
		"bonus_per_level": [0.1, 0.2]  # +10% за уровень
	}
}
