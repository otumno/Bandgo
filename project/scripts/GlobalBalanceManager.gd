extends Node

@export_category("Game Balance")
@export var instrument_settings: Dictionary = {
	"default": {
		"points_per_click": 10,
		"combo_window_seconds": 2.0,
		"combo_multipliers": [1, 2, 3, 5, 8],
		"allow_multiple_hits": false
	}
}

@export_category("Instrument Levels")
@export var instrument_levels: Dictionary = {
	"xylophone": {
		"base_price": 500,
		"levels": [
			{
				"texture": null,
				"points": 15,
				"unlock_required": 1
			},
			{
				"texture": null,
				"points": 25,
				"unlock_required": 2
			}
		]
	},
	"tomtom": {
		"base_price": 500,
		"levels": [
			{
				"texture": null,
				"points": 15,
				"unlock_required": 1
			},
			{
				"texture": null,
				"points": 25,
				"unlock_required": 2
			}
		]
	},
	"pata": {
		"base_price": 500,
		"levels": [
			{
				"texture": null,
				"points": 15,
				"unlock_required": 1
			},
			{
				"texture": null,
				"points": 25,
				"unlock_required": 2
			}
		]
	},
	"pon": {
		"base_price": 500,
		"levels": [
			{
				"texture": null,
				"points": 15,
				"unlock_required": 1
			},
			{
				"texture": null,
				"points": 25,
				"unlock_required": 2
			}
		]
	}
}

@export_category("Upgrades Settings")
@export var upgrades_settings: Dictionary = {
	"xylophone_unlock": {
		"name": "Xylophone",
		"cost_per_level": [0, 1000, 2000],
		"bonus_per_level": [1, 2, 3]
	},
	"tomtom_unlock": {
		"name": "tomtom",
		"cost_per_level": [500, 1000, 2000],
		"bonus_per_level": [1, 2, 3],
		"unlocks_pattern_line": [0, 1, 2]
	},
	"pata_unlock": {
		"name": "pata",
		"cost_per_level": [500, 1000, 2000],
		"bonus_per_level": [1, 2, 3],
		"unlocks_pattern_line": [0, 1, 2]
	},
	"pon_unlock": {
		"name": "pon",
		"cost_per_level": [500, 1000, 2000],
		"bonus_per_level": [1, 2, 3],
		"unlocks_pattern_line": [0, 1, 2]
	}
}

@export_category("Global Upgrades")
@export var global_upgrades: Dictionary = {
	"global_multiplier": {
		"name": "Глобальный множитель",
		"cost_per_level": [1000, 2000, 5000],
		"bonus_per_level": [0.1, 0.2, 0.3],
		"affects_background": true
	}
}

func get_instrument_level_settings(instrument_type: String, level: int) -> Dictionary:
	if not instrument_levels.has(instrument_type):
		return {}
	
	var levels = instrument_levels[instrument_type].get("levels", [])
	if level <= 0 or level > levels.size():
		return {}
	
	return levels[level - 1]

func get_max_instrument_level(instrument_type: String) -> int:
	if not instrument_levels.has(instrument_type):
		return 0
	return instrument_levels[instrument_type].get("levels", []).size()

func get_instrument_texture(instrument_type: String, level: int) -> Texture2D:
	var settings = get_instrument_level_settings(instrument_type, level)
	return settings.get("texture", null)
