extends Control

@onready var level_label: Label = $PanelContainer/HBoxContainer/LevelLabel
@onready var multiplier_label: Label = $PanelContainer/HBoxContainer/MultiplierLabel

func _ready():
	if level_label:
		level_label.text = ""
		print("InstrumentInfoDisplay: level_label initialized")
	else:
		push_error("InstrumentInfoDisplay: level_label not found")
	
	if multiplier_label:
		multiplier_label.text = ""
		multiplier_label.visible = false
		print("InstrumentInfoDisplay: multiplier_label initialized")
	else:
		push_error("InstrumentInfoDisplay: multiplier_label not found")

func update_display(level: int, multiplier: int):
	if level_label:
		level_label.text = "Lv.%d" % level
		print("InstrumentInfoDisplay: Updated level_label to Lv.%d" % level)
	else:
		push_error("InstrumentInfoDisplay: level_label is null during update")
	
	if multiplier_label:
		if multiplier > 1:
			multiplier_label.text = "x%d" % multiplier
			multiplier_label.visible = true
			print("InstrumentInfoDisplay: Updated multiplier_label to x%d, visible: true" % multiplier)
		else:
			multiplier_label.text = ""
			multiplier_label.visible = false
			print("InstrumentInfoDisplay: Cleared multiplier_label, visible: false")
	else:
		push_error("InstrumentInfoDisplay: multiplier_label is null during update")
