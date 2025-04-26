extends Node

@export_category("Game Balance")
@export var instrument_settings: Dictionary = {
	"default": {
		"points_per_click": 10,
		"combo_window_seconds": 2.0,
		"combo_multipliers": [1, 2, 3, 5, 8],  # Обычный массив, редактор сам определит тип
		"allow_multiple_hits": false
	},
	"xylophone": {
		"points_per_click": 15,
		"combo_window_seconds": 1.5,
		"combo_multipliers": PackedInt32Array([1, 2, 3, 5, 8, 10, 12])
	},
	"drum": {
		"points_per_click": 8,
		"allow_multiple_hits": true,
		"combo_multipliers": PackedInt32Array([2, 2, 4, 4, 8, 8, 10, 12])
	}
}

@export var upgrade_costs: Dictionary = {"speed": 100, "power": 200}
@export var instrument_costs: Dictionary = {"guitar": 500, "drums": 800}
@export var global_combo_pattern: Array[int] = [1, 1, 1, 1]
