extends Control

var level_label: Label
var multiplier_label: Label

func _ready():
	level_label = get_node_or_null("PanelContainer/HBoxContainer/LevelLabel")
	multiplier_label = get_node_or_null("PanelContainer/HBoxContainer/MultiplierLabel")
	if level_label:
		level_label.text = "Lv.0"
	if multiplier_label:
		multiplier_label.text = "x1"
	else:
		push_warning("InstrumentInfoDisplay: MultiplierLabel not found")

func update_display(level: int, multiplier: int):
	if level_label:
		level_label.text = "Lv.%d" % level
	else:
		push_warning("InstrumentInfoDisplay: LevelLabel not found")
	if multiplier_label:
		multiplier_label.text = "x%d" % multiplier
	else:
		push_warning("InstrumentInfoDisplay: MultiplierLabel not found")
	visible = true
