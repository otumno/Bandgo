extends Node2D

@onready var label: Label = $Label
var points: int = 0

func _ready():
	if label:
		label.text = "+%d" % points
		# Устанавливаем размер шрифта через override
		label.add_theme_font_size_override("font_size", 40)
		var tween = create_tween()
		tween.tween_property(self, "position", position + Vector2(0, -50), 0.5)
		tween.tween_property(self, "modulate:a", 0.0, 0.5)
		tween.tween_callback(queue_free)
	else:
		push_warning("ScorePopup: Label not found")
		queue_free()

func set_points(value: int):
	points = value
	if label:
		label.text = "+%d" % points
