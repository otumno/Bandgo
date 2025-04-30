extends HBoxContainer

@onready var level_label: Label = $LevelLabel
@onready var multiplier_label: Label = $MultiplierLabel

func _ready():
	# Настройки внешнего вида
	level_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	multiplier_label.add_theme_color_override("font_color", Color.GOLD)
	
	# Выравнивание
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	multiplier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Минимальный размер, чтобы не "прыгал" при появлении множителя
	level_label.custom_minimum_size.x = 40
	multiplier_label.custom_minimum_size.x = 30

func update_display(level: int, multiplier: int):
	level_label.text = "Lv.%d" % level
	if multiplier > 1:
		multiplier_label.text = "x%d" % multiplier
		# Анимация при появлении множителя
		var tween = create_tween()
		tween.tween_property(multiplier_label, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(multiplier_label, "scale", Vector2.ONE, 0.2)
	else:
		multiplier_label.text = ""
