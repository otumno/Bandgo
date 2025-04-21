extends Node2D
@onready var bpm_manager = $BPM_Manager
@onready var score_label = $UI/ScoreLabel
@onready var name_label = $UI/NameLabel
func _ready():
	var gm = get_node("/root/GameManager")
	update_ui(gm)
	for instrument in $Instruments.get_children():
		if bpm_manager:
			instrument.input_event.connect(_on_first_click)
func _on_first_click():
	bpm_manager.start_metronome()
	for instrument in $Instruments.get_children():
		instrument.input_event.disconnect(_on_first_click)
func update_ui(gm: Node):
	score_label.text = "Score: %d" % gm.score
	name_label.text = "Player: %s" % gm.player_name
func _on_back_button_pressed():
	get_node("/root/SaveSystem").force_save()
	get_node("/root/SceneManager").load_scene("res://scenes/MainMenu.tscn")
func _exit_tree():
	if bpm_manager:
		bpm_manager.stop_metronome()
