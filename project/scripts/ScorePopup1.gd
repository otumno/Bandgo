extends Node2D

@onready var label: Label = $Label
@export var rise_distance: float = 50.0
@export var duration: float = 0.8

func show_score(value: int, position: Vector2, color: Color, _multiplier: int = 1):
	global_position = position
	label.text = "+%d" % value
	label.modulate = color
	
	# Анимация
	var tween = create_tween()
	tween.tween_property(self, "position", position + Vector2(0, -rise_distance), duration)
	tween.parallel().tween_property(label, "scale", Vector2(1.2, 1.2), duration * 0.3)
	tween.tween_property(label, "scale", Vector2.ONE, duration * 0.5)
	tween.tween_callback(queue_free)
