extends Area2D
class_name Instrument

@export_category("Sound Settings")
@export var correct_sound_pattern: Array[AudioStream]
@export var fail_sound: AudioStream
@export var first_click_sound: AudioStream
@export var combo_sounds: Array[AudioStream]

@export_category("Gameplay Settings")
@export var points_per_click: int = 10
@export var in_rhythm_multiplier: float = 2.0
@export var rhythm_window_ms: float = 100.0
@export var combo_window_seconds: float = 2.0
@export var combo_multipliers: Array[int] = [1, 2, 3, 5, 8]

@export_category("Visual Feedback")
@export var score_popup_scene: PackedScene
@export var in_rhythm_color: Color = Color.GREEN
@export var out_of_rhythm_color: Color = Color.WHITE
@export var combo_colors: Array[Color] = [Color.GOLD, Color.CRIMSON, Color.DEEP_SKY_BLUE]
@export var feedback_scale: float = 1.1
@export var feedback_duration: float = 0.15
@export var enable_visual_feedback: bool = true
@export var max_scale_limit: float = 1.3
@export var hit_particles: GPUParticles2D
@export var combo_particles: GPUParticles2D

@onready var pattern_analyzer: PatternAnalyzer = $PatternAnalyzer
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var sprite: Sprite2D = $Sprite2D

var bpm_manager: BPM_Manager
var last_hit_time := 0.0
var is_first_click := true
var pattern_index := 0
var feedback_tween: Tween
var base_scale: Vector2
var combo_count := 0
var last_combo_time := 0.0
var current_combo_multiplier := 1

func _ready():
	_initialize_nodes()
	_connect_signals()
	base_scale = sprite.scale if sprite else Vector2.ONE
	input_event.connect(_on_input_event)

func _initialize_nodes():
	if not audio_player:
		audio_player = AudioStreamPlayer.new()
		audio_player.name = "AudioStreamPlayer"
		add_child(audio_player)
	
	if not sprite:
		for child in get_children():
			if child is Sprite2D:
				sprite = child
				break

func _connect_signals():
	bpm_manager = get_node_or_null("/root/BPM_GlobalManager")
	if bpm_manager:
		print("BPM Manager linked in Instrument")
	else:
		push_error("BPM Manager not found in autoload!")
	
	if pattern_analyzer:
		pattern_analyzer.pattern_verified.connect(_on_pattern_verified)
	else:
		print("PatternAnalyzer not found - continuing without pattern analysis")

func _on_input_event(_viewport, event: InputEvent, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click()

func _handle_click():
	var current_time = Time.get_ticks_msec()
	var current_beat = bpm_manager.current_beat if bpm_manager else 0
	
	if is_first_click:
		if bpm_manager:
			bpm_manager.start_metronome()
		is_first_click = false
		if first_click_sound:
			_play_sound(first_click_sound)
	
	if pattern_analyzer:
		pattern_analyzer.register_input(current_beat)
	
	var is_in_rhythm = _check_rhythm(current_time)
	_update_combo(current_time, is_in_rhythm)
	
	if is_in_rhythm:
		_play_correct_sound()
		_add_points(int(points_per_click * in_rhythm_multiplier * current_combo_multiplier))
	else:
		_play_fail_sound()
		_add_points(points_per_click)
	
	last_hit_time = current_time
	_play_visual_feedback()
	_emit_particles(is_in_rhythm)

func _check_rhythm(current_time: float) -> bool:
	if not bpm_manager:
		return false
	
	var beat_time = (60.0 / bpm_manager.bpm) * 1000.0
	var time_since_last = current_time - last_hit_time
	var time_in_beat = fmod(time_since_last, beat_time)
	
	return (time_in_beat <= rhythm_window_ms or 
		   (beat_time - time_in_beat) <= rhythm_window_ms)

func _update_combo(current_time: float, is_in_rhythm: bool):
	var time_since_last_combo = (current_time - last_combo_time) / 1000.0
	
	if is_in_rhythm and time_since_last_combo <= combo_window_seconds:
		combo_count += 1
		current_combo_multiplier = combo_multipliers[min(combo_count, combo_multipliers.size() - 1)]
	else:
		combo_count = 0
		current_combo_multiplier = 1
	
	last_combo_time = current_time

func _play_correct_sound():
	if correct_sound_pattern.is_empty():
		return
	
	if combo_count >= 3 and not combo_sounds.is_empty():
		var sound_idx = min(combo_count - 3, combo_sounds.size() - 1)
		_play_sound(combo_sounds[sound_idx])
	else:
		audio_player.stream = correct_sound_pattern[pattern_index % correct_sound_pattern.size()]
		audio_player.play()
		pattern_index += 1

func _play_fail_sound():
	if fail_sound:
		_play_sound(fail_sound)

func _play_sound(sound: AudioStream):
	audio_player.stream = sound
	audio_player.play()

func _add_points(points: int):
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("add_score"):
		gm.add_score(points)
		if score_popup_scene and (sprite or is_instance_valid(self)):
			var popup_position = sprite.global_position if sprite else global_position
			_show_score_popup(points, popup_position)

func _show_score_popup(points: int, popup_pos: Vector2):
	var popup = score_popup_scene.instantiate()
	get_tree().root.add_child(popup)
	
	var is_in_rhythm = _check_rhythm(Time.get_ticks_msec())
	var color = _get_popup_color(is_in_rhythm)
	
	popup.show_score(points, popup_pos, color, current_combo_multiplier)

func _get_popup_color(is_in_rhythm: bool) -> Color:
	if combo_count >= 3 and combo_colors.size() > 0:
		var color_idx = min(combo_count - 3, combo_colors.size() - 1)
		return combo_colors[color_idx]
	return in_rhythm_color if is_in_rhythm else out_of_rhythm_color

func _play_visual_feedback():
	if not sprite or not enable_visual_feedback:
		return
	
	if feedback_tween:
		feedback_tween.kill()
	
	var target_scale = base_scale * feedback_scale * (1.0 + 0.1 * current_combo_multiplier)
	target_scale.x = min(target_scale.x, base_scale.x * max_scale_limit)
	target_scale.y = min(target_scale.y, base_scale.y * max_scale_limit)
	
	feedback_tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	feedback_tween.tween_property(sprite, "scale", target_scale, feedback_duration * 0.5)
	feedback_tween.tween_property(sprite, "scale", base_scale, feedback_duration * 0.5)

func _emit_particles(is_in_rhythm: bool):
	if hit_particles:
		hit_particles.emitting = true
		hit_particles.modulate = in_rhythm_color if is_in_rhythm else out_of_rhythm_color
	
	if combo_count >= 3 and combo_particles:
		combo_particles.emitting = true
		if combo_colors.size() > 0:
			var color_idx = min(combo_count - 3, combo_colors.size() - 1)
			combo_particles.modulate = combo_colors[color_idx]

func _on_pattern_verified(pattern: Array[bool]):
	await _start_automation(pattern)
	pattern_analyzer.reset()

func _start_automation(pattern: Array[bool]) -> void:
	print("Playing back pattern:", pattern)
	for i in range(pattern_analyzer.auto_repeat_count):
		for hit in pattern:
			await get_tree().create_timer(60.0 / bpm_manager.bpm).timeout
			if hit and not correct_sound_pattern.is_empty():
				var sound_index = randi() % correct_sound_pattern.size()
				_play_sound(correct_sound_pattern[sound_index])
