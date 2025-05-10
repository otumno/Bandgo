extends Node

@export_category("Game Balance")
@export var instrument_settings: Dictionary = {
	"default": {
		"points_per_click": 10,
		"combo_window_seconds": 2.0,
		"combo_multipliers": [2, 3, 5, 8, 10], # Изменено: начальный множитель x2
		"allow_multiple_hits": false
	}
}

@export_category("Initial Unlocks")
@export var initial_instruments: Dictionary = {
	"xylophone": {
		"initial_cost": 0,
		"display_name": "Xylophone"
	},
	"tomtom": {
		"initial_cost": 500,
		"display_name": "Tom-Tom"
	},
	"pata": {
		"initial_cost": 750,
		"display_name": "Pata"
	},
	"pon": {
		"initial_cost": 1000,
		"display_name": "Pon"
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
		"name": "Xylophone Level",
		"cost_per_level": [0, 1000, 2000],
		"bonus_per_level": [1, 2, 3]
	},
	"tomtom_unlock": {
		"name": "Tom-Tom Level",
		"cost_per_level": [500, 1000, 2000],
		"bonus_per_level": [1, 2, 3]
	},
	"pata_unlock": {
		"name": "Pata Level",
		"cost_per_level": [750, 1500, 3000],
		"bonus_per_level": [1, 2, 3]
	},
	"pon_unlock": {
		"name": "Pon Level",
		"cost_per_level": [1000, 2000, 4000],
		"bonus_per_level": [1, 2, 3]
	},
	"xylophone_combo": {
		"name": "Xylophone Combo",
		"cost_per_level": [500, 1000, 2000, 4000, 8000],
		"bonus_per_level": [2, 4, 6, 8, 10],
		"unlocks_pattern_line": [1, 2, 3, 4, 5]
	},
	"tomtom_combo": {
		"name": "Tom-Tom Combo",
		"cost_per_level": [500, 1000, 2000, 4000, 8000],
		"bonus_per_level": [2, 4, 6, 8, 10],
		"unlocks_pattern_line": [1, 2, 3, 4, 5]
	},
	"pata_combo": {
		"name": "Pata Combo",
		"cost_per_level": [750, 1500, 3000, 6000, 12000],
		"bonus_per_level": [2, 4, 6, 8, 10],
		"unlocks_pattern_line": [1, 2, 3, 4, 5]
	},
	"pon_combo": {
		"name": "Pon Combo",
		"cost_per_level": [1000, 2000, 4000, 8000, 16000],
		"bonus_per_level": [2, 4, 6, 8, 10],
		"unlocks_pattern_line": [1, 2, 3, 4, 5]
	}
}

@export_category("Global Upgrades")
@export var global_upgrades: Dictionary = {
	"global_multiplier": {
		"name": "Global Multiplier",
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
