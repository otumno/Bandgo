extends Label

@export var rise_distance := 40.0
@export var duration := 0.8
@export var scale_effect: bool = true
@export var max_scale: float = 1.5
@export var fade_out_delay: float = 0.2

func show_score(value: Variant, popup_position: Vector2, color: Color, multiplier: int = 1):
	if value is String:
		text = value
	else:
		# Убрали отображение множителя
		text = str(value)
	self.modulate = color
	self.global_position = popup_position
	self.modulate.a = 1.0
	scale = Vector2.ONE
	var tween = create_tween()
	if scale_effect:
		tween.tween_property(self, "scale", Vector2(max_scale, max_scale), duration * 0.2)
		tween.tween_property(self, "scale", Vector2.ONE, duration * 0.3)
	tween.parallel().tween_property(self, "global_position", popup_position + Vector2(0, -rise_distance), duration)
	tween.parallel().tween_property(self, "modulate:a", 0.0, duration).set_delay(fade_out_delay)
	tween.tween_callback(queue_free)
