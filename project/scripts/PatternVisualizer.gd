extends Node2D

@export var pattern_colors: Array[Color] = [
	Color.GREEN, 
	Color.RED, 
	Color.BLUE, 
	Color.YELLOW
]
@export var cell_size: Vector2 = Vector2(20, 20)
@export var spacing: float = 5.0

var current_pattern: Array[bool] = []
var pattern_history: Array[Array] = []

func _ready():
	var bpm_manager = get_node("/root/BPM_GlobalManager")
	bpm_manager.pattern_detected.connect(_on_pattern_detected)

func _on_pattern_detected(pattern: Array[bool], _start_beat: int):
	current_pattern = pattern.duplicate()
	pattern_history.append(pattern.duplicate())
	
	if pattern_history.size() > 5:
		pattern_history.remove_at(0)
	
	queue_redraw()

func _draw():
	if current_pattern.is_empty():
		return
	
	# Рисуем текущий паттерн
	for i in range(current_pattern.size()):
		var color = pattern_colors[i % pattern_colors.size()] if current_pattern[i] else Color(0.2, 0.2, 0.2, 0.5)
		var rect = Rect2(
			Vector2(i * (cell_size.x + spacing), 0),
			cell_size
		)
		draw_rect(rect, color, true)
	
	# Рисуем историю паттернов
	for p in range(pattern_history.size()):
		for i in range(pattern_history[p].size()):
			var color = pattern_colors[i % pattern_colors.size()] if pattern_history[p][i] else Color(0.2, 0.2, 0.2, 0.5)
			var rect = Rect2(
				Vector2(i * (cell_size.x + spacing), (p + 1) * (cell_size.y + spacing)),
				cell_size
			)
			draw_rect(rect, color, true)
