extends Area2D
class_name Instrument

# Настройки инструмента
@export_category("Sound Settings")
@export var sound_pattern: Array[AudioStream]
@export var first_click_sound: AudioStream
@export var combo_sounds: Array[AudioStream]
@export var fail_sound: AudioStream

@export_category("Instrument Type")
@export var instrument_type: String = "default"

@export_category("Input Settings")
@export var input_keys: Array[String]

@export_category("Visual Feedback")
@export var score_popup_scene: PackedScene
@export var combo_colors: Array[Color] = [Color.GOLD, Color.CRIMSON, Color.DEEP_SKY_BLUE]
@export var enable_visual_feedback: bool = true
@export var feedback_scale: float = 1.1
@export var feedback_duration: float = 0.15
@export var max_scale_limit: float = 1.3
@export var hit_particles: GPUParticles2D
@export var combo_particles: GPUParticles2D

@export_category("Info Display")
@export var info_display: Control
@export var display_offset: Vector2 = Vector2(0, 50)
@export var auto_position_display: bool = false

@export_category("Combo Settings")
@export var combo_enabled: bool = true
@export var combo_reset_delay: float = 2.0

@export_category("Unlock Effects")
@export var unlock_scale_effect := Vector2(1.3, 1.3)
@export var unlock_effect_duration := 0.5

# Системные переменные
var points_per_click: int
var combo_window_seconds: float
var combo_multipliers: Array
var allow_multiple_hits_per_beat: bool
var _base_points: int = 0
var _current_combo_pattern: Array = []
var _unlocked_sound_indices: Array = []
var _beat_hit_status := {}
var feedback_tween: Tween
var current_level: int = 0

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var sprite: Sprite2D = $Sprite2D
var bpm_manager: BPM_Manager

var last_hit_time := 0.0
var combo_count := 0
var last_combo_time := 0.0
var current_combo_multiplier := 1
var current_pattern_index := 0
var base_scale: Vector2
var is_first_unlock := true

func _ready():
	_load_balance_settings()
	_initialize_nodes()
	_connect_signals()
	_apply_upgrades()
	_setup_instrument()
	add_to_group("instruments")
	
	if info_display and info_display.has_method("update_display"):
		info_display.update_display(current_level, current_combo_multiplier)
	elif info_display:
		push_warning("InfoDisplay missing update_display() method for ", instrument_type)
		
func _apply_upgrades():
	# Здесь обновляются параметры инструмента на основе апгрейдов
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		current_level = gm.get_instrument_level(instrument_type)
		_update_appearance()

func _load_balance_settings():
	var settings = GlobalBalanceManager.instrument_settings.get(instrument_type, {})
	_base_points = settings.get("points_per_click", 10)
	points_per_click = _base_points
	combo_window_seconds = settings.get("combo_window_seconds", combo_reset_delay)
	combo_multipliers = Array(settings.get("combo_multipliers", PackedInt32Array([1, 2, 3, 5, 8])))
	allow_multiple_hits_per_beat = settings.get("allow_multiple_hits", false)

func _initialize_nodes():
	if not audio_player:
		audio_player = AudioStreamPlayer.new()
		add_child(audio_player)
	
	if not sprite:
		for child in get_children():
			if child is Sprite2D:
				sprite = child
				break
	
	base_scale = sprite.scale if sprite else Vector2.ONE
	bpm_manager = get_tree().current_scene.get_node("BPM_Manager")

func _connect_signals():
	if bpm_manager:
		bpm_manager.beat_triggered.connect(_on_beat)
	
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.upgrades_updated.connect(_apply_upgrades)
		gm.instrument_upgraded.connect(_on_instrument_upgraded)
		gm.instrument_unlocked.connect(_on_instrument_unlocked)

	input_event.connect(_on_input_event)

func _setup_instrument():
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		current_level = gm.get_instrument_level(instrument_type)
		if current_level >= 1:
			visible = true
		_update_appearance()
		
		if info_display and info_display.has_method("update_display"):
			info_display.update_display(current_level, current_combo_multiplier)

func _update_appearance():
	var settings = GlobalBalanceManager.get_instrument_level_settings(instrument_type, current_level)
	
	if sprite and settings.has("texture") and settings.texture:
		sprite.texture = settings.texture
	
	if settings.has("points"):
		points_per_click = settings.points
		_base_points = settings.points

func _process(delta):
	if auto_position_display and info_display and sprite:
		var sprite_bottom = sprite.global_position.y + sprite.texture.get_height() * sprite.scale.y
		info_display.global_position.x = sprite.global_position.x + sprite.texture.get_width() * sprite.scale.x / 2 - info_display.size.x / 2
		info_display.global_position.y = sprite_bottom + display_offset.y

func _on_instrument_unlocked(unlocked_type: String):
	if unlocked_type == instrument_type:
		visible = true
		_update_appearance()
		
		if is_first_unlock:
			is_first_unlock = false
			_play_unlock_effect()

func _play_unlock_effect():
	if not sprite:
		return
	
	sprite.modulate.a = 0.0
	sprite.scale = unlock_scale_effect
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 1.0, unlock_effect_duration)
	tween.tween_property(sprite, "scale", base_scale, unlock_effect_duration)\
		 .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_instrument_upgraded(upgraded_type: String, level: int):
	if upgraded_type == instrument_type:
		current_level = level
		_update_appearance()
		if info_display and info_display.has_method("update_display"):
			info_display.update_display(current_level, current_combo_multiplier)

func _on_input_event(_viewport, event: InputEvent, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click()

func _on_beat(beat_number: int):
	if sound_pattern.size() > 0:
		current_pattern_index = beat_number % sound_pattern.size()

func _handle_click():
	var current_time = Time.get_ticks_msec()
	var current_beat = bpm_manager.current_beat if bpm_manager else 0

	if !allow_multiple_hits_per_beat && _beat_hit_status.get(current_beat, false):
		_handle_fail_hit(true)
		return

	if bpm_manager && !bpm_manager.is_playing:
		bpm_manager.start_metronome()
		if first_click_sound:
			_play_sound(first_click_sound)
		_play_visual_feedback()
		return

	if _unlocked_sound_indices.size() > 0:
		var sound_index = _unlocked_sound_indices[current_pattern_index % _unlocked_sound_indices.size()]
		_play_sound(sound_pattern[sound_index])
	elif sound_pattern.size() > 0:
		_play_sound(sound_pattern[current_pattern_index % sound_pattern.size()])

	if combo_enabled:
		_update_combo(current_time)
	else:
		current_combo_multiplier = 1
		combo_count = 0
	
	_play_visual_feedback()
	_add_points(points_per_click * current_combo_multiplier)
	_beat_hit_status[current_beat] = true
	current_pattern_index += 1
	
	if info_display and info_display.has_method("update_display"):
		info_display.update_display(current_level, current_combo_multiplier)

func _update_combo(current_time: float):
	var time_since_last_combo = (current_time - last_combo_time) / 1000.0
	if time_since_last_combo > combo_window_seconds:
		if combo_count > 0:
			combo_count = 0
			current_combo_multiplier = 1
			_update_info_display()
		return

	combo_count += 1
	if _current_combo_pattern.size() > 0:
		var pattern_index = (combo_count - 1) % _current_combo_pattern.size()
		if pattern_index < combo_multipliers.size():
			current_combo_multiplier = combo_multipliers[pattern_index]
	else:
		if combo_count <= combo_multipliers.size():
			current_combo_multiplier = combo_multipliers[combo_count - 1]
		else:
			current_combo_multiplier = combo_multipliers[-1]

	last_combo_time = current_time
	_update_info_display()

func _update_info_display():
	if info_display and info_display.has_method("update_display"):
		info_display.update_display(current_level, current_combo_multiplier)

func _play_sound(sound: AudioStream):
	audio_player.stream = sound
	audio_player.play()

func _add_points(points: int):
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("add_score"):
		gm.add_score(points)
		if score_popup_scene:
			var popup_position = sprite.global_position if sprite else global_position
			_show_score_popup(points, popup_position)

func _show_score_popup(points: int, popup_pos: Vector2):
	var popup = score_popup_scene.instantiate()
	get_tree().root.add_child(popup)
	var color = _get_popup_color()
	popup.show_score(points, popup_pos, color, current_combo_multiplier)

func _get_popup_color() -> Color:
	if combo_count >= 3 and combo_colors.size() > 0:
		var color_idx = min(combo_count - 3, combo_colors.size() - 1)
		return combo_colors[color_idx]
	return Color.WHITE

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
	if combo_count >= 3 and combo_particles:
		combo_particles.emitting = true
		if combo_colors.size() > 0:
			var color_idx = min(combo_count - 3, combo_colors.size() - 1)
			combo_particles.modulate = combo_colors[color_idx]

func _handle_fail_hit(is_double_hit: bool):
	combo_count = 0
	current_combo_multiplier = 1
	_play_fail_sound()
	_add_points(points_per_click if !is_double_hit else 0)
	if is_double_hit:
		_show_combo_reset("Double hit!")
	_update_info_display()

func _show_combo_reset(message: String):
	var popup_position = sprite.global_position if sprite else global_position
	if score_popup_scene:
		var popup = score_popup_scene.instantiate()
		get_tree().root.add_child(popup)
		popup.show_score(message, popup_position, Color.RED, 1)

func _play_fail_sound():
	if fail_sound:
		_play_sound(fail_sound)
