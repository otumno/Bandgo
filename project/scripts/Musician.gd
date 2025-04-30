extends Node2D
class_name Musician

@export var instrument_type: String  # Какой инструмент автоматизирует
@export var auto_play_pattern: Array[int] = [1, 0, 1, 0]  # Паттерн автоигры
@export var visual_effect: PackedScene  # Визуал музыканта

var current_beat: int = 0
var bpm_manager: BPM_Manager

func _ready():
	bpm_manager = get_tree().current_scene.get_node("BPM_Manager")
	if bpm_manager:
		bpm_manager.beat_triggered.connect(_on_beat)
	
	# Создаем визуал
	if visual_effect:
		var effect = visual_effect.instantiate()
		add_child(effect)

func _on_beat(beat: int):
	current_beat = beat % auto_play_pattern.size()
	if auto_play_pattern[current_beat] == 1:
		_play_instrument()

func _play_instrument():
	var instrument = _find_instrument()
	if instrument:
		instrument._handle_click()  # Имитируем клик

func _find_instrument() -> Instrument:
	for node in get_tree().get_nodes_in_group("instruments"):
		if node.instrument_type == instrument_type:
			return node
	return null
