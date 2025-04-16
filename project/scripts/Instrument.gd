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

@export_category("Pattern Analysis")
@export var required_matches: int = 2  # Сколько раз должен повториться паттерн
@export var analysis_window: int = 4   # Количество тактов для анализа

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

# Для анализа паттернов
var input_buffer: Array[int] = []
var detected_pattern: Array[int] = []
var match_count: int = 0

func _ready():
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
	bpm_manager = BPM_GlobalManager as BPM_Manager
	
	if bpm_manager:
		print("BPM Manager connected successfully")
	else:
		push_error("BPM Manager not found in autoload!")
	
	# Получаем PatternAnalyzer из текущей сцены
	var pattern_analyzer = $PatternAnalyzer if has_node("PatternAnalyzer") else null
	if pattern_analyzer and pattern_analyzer.has_signal("pattern_detected"):
		pattern_analyzer.pattern_detected.connect(_on_pattern_detected)
		print("Connected signal 'pattern_detected'")
	else:
		push_warning("PatternAnalyzer not found or missing signal 'pattern_detected'")

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
	var current_beat = bpm_manager.current_beat if bpm_manager else -1
	
	if is_first_click and bpm_manager:
		bpm_manager.start_metronome()
	
	if is_first_click:
		_handle_first_click()
		is_first_click = false
	else:
		_handle_regular_click(current_time)
	
	# Добавляем текущий такт в буфер для анализа паттернов
	if current_beat != -1:
		input_buffer.append(current_beat)
		while input_buffer.size() > analysis_window:
			input_buffer.remove_at(0)
		
		# Проверяем паттерн
		_check_pattern()
	
	last_hit_time = current_time
	_play_visual_feedback()

func _check_pattern():
	if input_buffer.size() < analysis_window:
		print("Buffer too small:", input_buffer)
		return
	
	if bpm_manager and bpm_manager.check_pattern(input_buffer):
		match_count += 1
		print("Pattern match detected! Match count:", match_count)
	else:
		match_count = 0
		print("No pattern match. Resetting match count.")
	
	if match_count >= required_matches:
		detected_pattern = input_buffer.duplicate()
		match_count = 0
		print("Starting automation with pattern:", detected_pattern)
		_start_automation(detected_pattern)

func _start_automation(pattern: Array):
	print("Automating pattern:", pattern)
	for beat in pattern:
		await get_tree().create_timer(60.0 / bpm_manager.bpm).timeout
		if correct_sound_pattern.is_empty():
			push_error("Correct sound pattern is empty!")
			return
		
		var sound_index = beat % correct_sound_pattern.size()
		audio_player.stream = correct_sound_pattern[sound_index]
		audio_player.play()
		print("Playing sound at index:", sound_index)

func _on_pattern_detected(pattern: Array):
	print("Pattern detected in Instrument:", pattern)
	_start_automation(pattern)

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
