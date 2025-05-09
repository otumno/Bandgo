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
@export var allow_multiple_hits_per_beat: bool = false  # Добавлено
@export var input_keys: Array[String]

@export_category("Visual Feedback")
@export var score_popup_scene: PackedScene
@export var combo_colors: Array[Color] = [Color.GOLD, Color.CRIMSON, Color.DEEP_SKY_BLUE]
@export var enable_visual_feedback: bool = true
@export var feedback_scale: float = 1.1
@export var max_scale_limit: float = 1.3

@export_category("Combo Settings")
@export var combo_enabled: bool = true
@export var combo_reset_delay: float = 2.0

# Добавляем настройки размера
@export_category("Appearance Settings")
@export var base_size: Vector2 = Vector2(100, 100)
@export var unlock_scale_effect: Vector2 = Vector2(1.3, 1.3)
@export var unlock_effect_duration: float = 0.5
@export var feedback_duration: float = 0.15

# Системные переменные
var points_per_click: int
var combo_window_seconds: float
var combo_multipliers: Array
var _current_combo_multiplier: int = 1
var current_pattern_index: int = 0  # Добавлено
var _current_beat: int = 0
var _beat_hit_status := {}
var _combo_count: int = 0
var _last_combo_time: float = 0.0
var base_scale: Vector2 = Vector2.ONE
var target_scale: Vector2 = Vector2.ONE
var _unlocked_patterns: int = 1

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var sprite: Sprite2D = $Sprite2D
var bpm_manager: BPM_Manager

func _ready():
	_load_balance_settings()
	if GameManager.unlocked_instruments.has(instrument_type):
		visible = true  # Делаем видимым, если инструмент разблокирован
	_initialize_nodes()
	_connect_signals()
	_apply_upgrades()
	# Инициализация размера
	if sprite:
		# Рассчитываем нужный масштаб для достижения base_size
		var texture_size = sprite.texture.get_size() if sprite.texture else Vector2.ONE
		base_scale = Vector2(
			base_size.x / texture_size.x,
			base_size.y / texture_size.y
		)
		sprite.scale = base_scale * 0.5  # Начальный размер для анимации появления
		target_scale = base_scale
		
		# Запускаем анимацию появления
		_play_unlock_effect()

func _load_balance_settings():
	var settings = GlobalBalanceManager.instrument_settings.get(instrument_type, {})
	points_per_click = settings.get("points_per_click", 10)
	if not GameManager.unlocked_instruments.has(instrument_type):
		visible = false

func _initialize_nodes():
	if not audio_player:
		audio_player = AudioStreamPlayer.new()
		add_child(audio_player)
	
	if not sprite:
		for child in get_children():
			if child is Sprite2D:
				sprite = child
				break
	
	bpm_manager = get_tree().current_scene.get_node("BPM_Manager")

func _connect_signals():
	if bpm_manager:
		bpm_manager.beat_triggered.connect(_on_beat)
	
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.upgrades_updated.connect(_apply_upgrades)
		gm.instrument_unlocked.connect(_on_instrument_unlocked)
		gm.instrument_upgraded.connect(_on_instrument_upgraded)

	input_event.connect(_on_input_event)

func _apply_upgrades():
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		_unlocked_patterns = gm.unlocked_combo_lines.get(instrument_type, 1)
		var level = gm.get_instrument_level(instrument_type)
		var settings = GlobalBalanceManager.get_instrument_level_settings(instrument_type, level)
		if settings.has("points"):
			points_per_click = settings["points"]

func _on_beat(beat_number: int):
	pass  # Можно добавить логику реакции на бит

func _on_instrument_upgraded(instrument_type: String, level: int):
	if instrument_type == self.instrument_type:
		_apply_upgrades()

func _on_input_event(_viewport, event: InputEvent, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click()

func _handle_click():
	var current_time = Time.get_ticks_msec() / 1000.0
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

	# Воспроизведение звука
	var available_patterns = _get_available_patterns()
	if available_patterns.size() > 0:
		var pattern_index = _combo_count % available_patterns.size()
		_play_sound(available_patterns[pattern_index])

	# Обработка комбо
	if combo_enabled:
		_update_combo(current_time)

	# Добавление очков
	var points = points_per_click * _current_combo_multiplier
	GameManager.add_score(points)
	
	# Показ попапа очков (используем старый рабочий метод)
	if score_popup_scene:
		var popup_pos = global_position
		if sprite:
			# Центр спрайта инструмента
			popup_pos = sprite.global_position + Vector2(
				sprite.texture.get_width() * sprite.scale.x / 2,
				-sprite.texture.get_height() * sprite.scale.y / 2
			)
		_show_score_popup(points, popup_pos)
	
	_play_visual_feedback()
	_beat_hit_status[current_beat] = true
	current_pattern_index += 1

func _show_score_popup(points: int, popup_pos: Vector2):
	var popup = score_popup_scene.instantiate()
	get_tree().root.add_child(popup)
	var color = _get_popup_color()
	popup.show_score(points, popup_pos, color, _current_combo_multiplier)

func _get_popup_color() -> Color:
	if _combo_count >= 3 and combo_colors.size() > 0:
		var color_idx = min(_combo_count - 3, combo_colors.size() - 1)
		return combo_colors[color_idx]
	return Color.WHITE

func _get_available_patterns() -> Array:
	if sound_pattern.size() <= _unlocked_patterns:
		return sound_pattern
	return sound_pattern.slice(0, _unlocked_patterns)

func _update_combo(current_time: float):
	var time_since_last = current_time - _last_combo_time
	
	if time_since_last > combo_reset_delay:
		_combo_count = 0
		_current_combo_multiplier = 1
		return
	
	_combo_count += 1
	_last_combo_time = current_time
	
	var combo_settings = GlobalBalanceManager.upgrades_settings.get(instrument_type + "_combo", {})
	var multipliers = combo_settings.get("bonus_per_level", [2, 4, 6, 8, 10])
	_current_combo_multiplier = multipliers[min(_combo_count, multipliers.size() - 1)]

func _play_sound(sound: AudioStream):
	if audio_player and sound:
		audio_player.stream = sound
		audio_player.play()

func _handle_fail_hit(is_double_hit: bool):
	_combo_count = 0
	_current_combo_multiplier = 1
	_play_sound(fail_sound)
	GameManager.add_score(points_per_click if !is_double_hit else 0)

func _play_visual_feedback():
	if not sprite or not enable_visual_feedback:
		return
	
	var target_feedback_scale = target_scale * feedback_scale * (1.0 + 0.05 * _current_combo_multiplier)
	target_feedback_scale = target_feedback_scale.clamp(target_scale, target_scale * max_scale_limit)
	
	var tween = create_tween()
	tween.tween_property(sprite, "scale", target_feedback_scale, feedback_duration * 0.5)
	tween.tween_property(sprite, "scale", target_scale, feedback_duration * 0.5)

func _on_instrument_unlocked(unlocked_type: String):
	if unlocked_type == instrument_type:
		visible = true
		_play_unlock_effect()

func _play_unlock_effect():
	if not sprite:
		return
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(sprite, "scale", target_scale * unlock_scale_effect, unlock_effect_duration * 0.5)
	tween.tween_property(sprite, "modulate:a", 1.0, unlock_effect_duration)
	tween.tween_property(sprite, "scale", target_scale, unlock_effect_duration).set_delay(unlock_effect_duration * 0.5)
