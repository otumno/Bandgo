extends Node2D

@onready var player_name_label: Label = %PlayerNameLabel
@onready var fame_label: Label = %FameLabel

func _ready() -> void:
	update_player_info()
	if SaveSystem.player_name.is_empty():
		get_tree().change_scene_to_file("res://scenes/SlotSelection.tscn")

func update_player_info() -> void:
	player_name_label.text = SaveSystem.player_name
	fame_label.text = "%d Fame" % SaveSystem.fame

func on_click() -> void:
	SaveSystem.fame += 1
	update_player_info()
	if SaveSystem.fame % 10 == 0:
		SaveSystem.save_game(SaveSystem.current_slot)
