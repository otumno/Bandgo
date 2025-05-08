class_name InstrumentInfoDisplay
extends Control

@onready var panel = $PanelContainer
@onready var level_label = $PanelContainer/HBoxContainer/LevelLabel as Label
@onready var multiplier_label = $PanelContainer/HBoxContainer/MultiplierLabel as Label

func _ready():
	# Убедимся, что все элементы существуют
	if !panel || !level_label || !multiplier_label:
		push_error("Missing required nodes in InstrumentInfoDisplay!")
		return
	
	# Настройки по умолчанию
	level_label.text = "Lv.0"
	multiplier_label.text = ""

func update_display(level: int, multiplier: int):
	if !is_instance_valid(level_label) || !is_instance_valid(multiplier_label):
		return
	
	level_label.text = "Lv.%d" % level
	if multiplier > 1:
		multiplier_label.text = "x%d" % multiplier
		multiplier_label.modulate = Color.GOLD  # Подсветка при комбо
	else:
		multiplier_label.text = ""
