extends Area2D
class_name Instrument

@export_category("Sound Settings")
@export var correct_sound_pattern: Array[AudioStream]
@export var fail_sound: AudioStream
@export var first_click_sound: AudioStream

@export_category("Gameplay Settings")
@export var points_per_click: int = 10
@export var in_rhythm_multiplier: float = 2.0
@export var rhythm_window_ms: float = 100.0

@export_category("Visual Feedback")
@export var feedback_scale: float = 1.1
@export var feedback_duration: float = 0.15
@export var enable_visual_feedback: bool = true

var pattern_index := 0
var last_hit_time := 0.0
var is_first_click := true
var sprite: Sprite2D
var audio_player: AudioStreamPlayer
var bpm_manager: BPM_Manager

func _ready():
	# Инициализация компонентов
	_initialize_audio_player()
	_find_sprite()
	_setup_bpm_manager()
	_connect_input()

func _initialize_audio_player():
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "InstrumentAudioPlayer"
	add_child(audio_player)

func _find_sprite():
	for child in get_children():
		if child is Sprite2D:
			sprite = child
			break

func _setup_bpm_manager():
	bpm_manager = _get_bpm_manager()
	if bpm_manager:
		print("BPM Manager connected successfully")
	else:
		push_error("BPM Manager not found!")

func _get_bpm_manager() -> BPM_Manager:
	if get_node("/root").has_node("BpmManager"):
		var manager = get_node("/root/BpmManager")
		if manager is BPM_Manager:
			return manager
	
	var managers = get_tree().get_nodes_in_group("BPM_Manager")
	if not managers.is_empty() and managers[0] is BPM_Manager:
		return managers[0]
	
	return null

func _connect_input():
	input_event.connect(_on_input_event)
	set_process_input(true)

func _exit_tree():
	if bpm_manager:
		bpm_manager.stop_metronome()

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click()

func _handle_click():
	var current_time = Time.get_ticks_msec()
	
	if is_first_click and bpm_manager:
		bpm_manager.start_metronome()
	
	if is_first_click:
		_handle_first_click()
		is_first_click = false
	else:
		_handle_regular_click(current_time)
	
	last_hit_time = current_time
	_play_visual_feedback()

func _handle_first_click():
	if first_click_sound:
		audio_player.stream = first_click_sound
		audio_player.play()
	_add_points(points_per_click)

func _handle_regular_click(current_time: float):
	if not bpm_manager:
		_add_points(points_per_click)
		return
	
	var beat_time = (60.0 / bpm_manager.bpm) * 1000.0
	var time_since_last = current_time - last_hit_time
	var time_in_beat = fmod(time_since_last, beat_time)
	
	if _is_in_rhythm(time_in_beat, beat_time):
		_play_correct_sound()
		_add_points(int(points_per_click * in_rhythm_multiplier))
	else:
		_play_fail_sound()
		_add_points(points_per_click)

func _is_in_rhythm(time_in_beat: float, beat_time: float) -> bool:
	return (time_in_beat <= rhythm_window_ms or 
		   (beat_time - time_in_beat) <= rhythm_window_ms)

func _play_correct_sound():
	if correct_sound_pattern.is_empty(): 
		return
	
	audio_player.stream = correct_sound_pattern[pattern_index % correct_sound_pattern.size()]
	audio_player.play()
	pattern_index += 1

func _play_fail_sound():
	if fail_sound:
		audio_player.stream = fail_sound
		audio_player.play()

func _add_points(points: int):
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("add_score"):
		game_manager.add_score(points)
	else:
		push_warning("GameManager not found or missing add_score method")

func _play_visual_feedback():
	if not sprite or not enable_visual_feedback:
		return
	
	var base_scale = sprite.scale
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(sprite, "scale", base_scale * feedback_scale, feedback_duration * 0.6)
	tween.tween_property(sprite, "scale", base_scale, feedback_duration * 0.4)
