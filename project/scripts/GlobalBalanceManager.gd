extends Node

@export_category("Game Balance")
@export var points_per_click: int = 1
@export var in_rhythm_multiplier: int = 10
@export var rhythm_window_before_ms: int = 100
@export var rhythm_window_after_ms: int = 50
@export var upgrade_costs: Dictionary = {"speed": 100, "power": 200}
@export var instrument_costs: Dictionary = {"guitar": 500, "drums": 800}
@export var combo_multipliers: Array[int] = [1, 2, 3, 5, 10]
@export var combo_pattern: Array[int] = [1, 1, 1, 1]
@export var max_missed_beats_allowed: int = 3
@export var combo_reset_message_delay_beats: int = 4
