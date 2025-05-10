extends Area2D
class_name Instrument

### ======================
### НАСТРОЙКИ ИНСТРУМЕНТА
### ======================

## Звуковые настройки
@export_category("Sound Settings")
@export var sound_pattern: Array[AudioStream]
@export var first_click_sound: AudioStream
@export var combo_sounds: Array[AudioStream]
@export var fail_sound: AudioStream

## Тип инструмента
@export_category("Instrument Type")
@export var instrument_type: String = "default"

## Настройки ввода
@export_category("Input Settings")
@export var input_keys: Array[String]
@export var allow_multiple_hits_per_beat: bool = false

## Визуальные эффекты
@export_category("Visual Feedback")
@export var score_popup_scene: PackedScene
@export var combo_colors: Array[Color] = [
	Color.GOLD, 
	Color.CRIMSON, 
	Color.DEEP_SKY_BLUE
]
@export var enable_visual_feedback: bool = true
@export var feedback_scale: float = 1.1
@export var feedback_duration: float = 0.15
@export var max_scale_limit: float = 1.3
@export var hit_particles: GPUParticles2D
@export var combo_particles: GPUParticles2D

## Настройки отображения информации
@export_category("Info Display")
@export var info_display: Control
@export var display_offset: Vector2 = Vector2(0, 50)
@export var auto_position_display: bool = false

## Настройки комбо
@export_category("Combo Settings")
@export var combo_enabled: bool = true
@export var combo_reset_delay: float = 2.0

## Эффекты разблокировки
@export_category("Unlock Effects")
@export var unlock_scale_effect := Vector2(1.3, 1.3)
@export var unlock_effect_duration := 0.5

## Настройки внешнего вида
@export_category("Appearance Settings")
@export var use_scene_scale: bool = true
@export var manual_base_scale: Vector2 = Vector2.ONE
@export var max_visual_scale: Vector2 = Vector2(1.5, 1.5)

### ======================
### СИСТЕМНЫЕ ПЕРЕМЕННЫЕ
### ======================
var points_per_click: int
var combo_window_seconds: float
var combo_multipliers: Array
var _base_points: int = 0
var _current_combo_pattern: Array = []
var _unlocked_sound_indices: Array = []
var _beat_hit_status := {}
var feedback_tween: Tween
var current_level: int = 0
var _base_scale: Vector2 = Vector2.ONE

# Ссылки на ноды
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var sprite: Sprite2D = $Sprite2D
var bpm_manager: BPM_Manager

# Состояние инструмента
var last_hit_time := 0.0
var combo_count := 0
var last_combo_time := 0.0
var current_combo_multiplier := 1
var current_pattern_index := 0
var base_scale: Vector2
var is_first_unlock := true
var _is_ready := false

### ======================
### ОСНОВНЫЕ МЕТОДЫ
### ======================

func _ready():
	_load_balance_settings()
	_initialize_nodes()
	_connect_signals()
	_setup_instrument()
	
	call_deferred("_initialize_scale")
	add_to_group("instruments")
	
	# Настройка дисплея
	if info_display:
		var canvas_layer = get_tree().root.get_node_or_null("InstrumentUILayer")
		if not canvas_layer:
			canvas_layer = CanvasLayer.new()
			canvas_layer.name = "InstrumentUILayer"
			get_tree().root.add_child(canvas_layer)
		
		# Перемещаем info_display в CanvasLayer, сохраняя позицию
		var old_parent = info_display.get_parent()
		if old_parent and old_parent != canvas_layer:
			old_parent.remove_child(info_display)
		canvas_layer.add_child(info_display)
		info_display.owner = canvas_layer
		
		# Сохраняем позицию из сцены
		info_display.z_index = 10
		info_display.visible = true
		
		# Обновляем содержимое дисплея
		if info_display.has_method("update_display"):
			info_display.update_display(current_level, current_combo_multiplier)
			print("Instrument %s: Setup display update - Level: %d, Multiplier: %d, Display visible: %s" % [instrument_type, current_level, current_combo_multiplier, info_display.visible])
		else:
			push_warning("Instrument %s: info_display lacks update_display method" % [instrument_type])
	else:
		push_warning("Instrument %s: No info_display assigned" % [instrument_type])

func _process(_delta: float):
	pass

### ======================
### МЕТОДЫ ИНИЦИАЛИЗАЦИИ
### ======================

func _load_balance_settings():
	var settings = GlobalBalanceManager.instrument_settings.get(instrument_type, {})
	_base_points = settings.get("points_per_click", 10)
	points_per_click = _base_points
	combo_window_seconds = settings.get("combo_window_seconds", combo_reset_delay)
	combo_multipliers = Array(settings.get("combo_multipliers", PackedInt32Array([1, 2, 3, 5, 8])))
	allow_multiple_hits_per_beat = settings.get("allow_multiple_hits", false)
	if sound_pattern.size() > 0:
		_unlocked_sound_indices.append(0)
	current_combo_multiplier = combo_multipliers[0]

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

func _initialize_scale():
	if not sprite:
		push_warning("Sprite not found, retrying...")
		await get_tree().process_frame
		_initialize_scale()
		return
	
	if use_scene_scale:
		self._base_scale = sprite.scale
	else:
		self._base_scale = manual_base_scale
	
	sprite.scale = self._base_scale
	
	if is_first_unlock and visible:
		_play_unlock_effect()
	
	_is_ready = true

func _connect_signals():
	if bpm_manager:
		bpm_manager.beat_triggered.connect(_on_beat)
	
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.upgrades_updated.connect(_apply_upgrades)
		gm.instrument_upgraded.connect(_on_instrument_upgraded)
		gm.instrument_unlocked.connect(_on_instrument_unlocked)

	input_event.connect(_on_input_event)

### ======================
### ОСНОВНАЯ ЛОГИКА
### ======================

func _setup_instrument():
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		current_level = gm.get_instrument_level(instrument_type)
		if current_level >= 1:
			visible = true
		_apply_upgrades()
		
		if info_display and info_display.has_method("update_display"):
			info_display.update_display(current_level, current_combo_multiplier)
			print("Instrument %s: Setup display update - Level: %d, Multiplier: %d, Display visible: %s" % [instrument_type, current_level, current_combo_multiplier, info_display.visible])

func _update_appearance():
	var settings = GlobalBalanceManager.get_instrument_level_settings(instrument_type, current_level)
	
	if sprite and settings.has("texture") and settings.texture:
		sprite.texture = settings.texture
	
	if settings.has("points"):
		points_per_click = settings.points
		_base_points = settings.points
	
	if info_display and info_display.has_method("update_display"):
		info_display.update_display(current_level, current_combo_multiplier)
		print("Instrument %s: Appearance display update - Level: %d, Multiplier: %d, Display visible: %s" % [instrument_type, current_level, current_combo_multiplier, info_display.visible])

func _on_input_event(_viewport, event: InputEvent, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click()

func _handle_click():
	if not _is_ready:
		return
	
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
		print("Instrument %s: Click display update - Level: %d, Multiplier: %d, Display visible: %s" % [instrument_type, current_level, current_combo_multiplier, info_display.visible])

### ======================
### СИСТЕМА КОМБО
### ======================

func _update_combo(current_time: float):
	var time_since_last_combo = (current_time - last_combo_time) / 1000.0
	
	if time_since_last_combo > combo_window_seconds:
		if combo_count > 0:
			combo_count = 0
			current_combo_multiplier = combo_multipliers[0]
			_update_info_display()
			print("Instrument %s: Combo reset - Multiplier: %d" % [instrument_type, current_combo_multiplier])
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
	print("Instrument %s: Combo updated - Count: %d, Multiplier: %d" % [instrument_type, combo_count, current_combo_multiplier])

func _update_info_display():
	if info_display and info_display.has_method("update_display"):
		info_display.update_display(current_level, current_combo_multiplier)
		print("Instrument %s: Info display update - Level: %d, Multiplier: %d, Display visible: %s" % [instrument_type, current_level, current_combo_multiplier, info_display.visible])

### ======================
### ВИЗУАЛЬНЫЕ ЭФФЕКТЫ
### ======================

func _play_unlock_effect():
	if not _is_ready or not sprite:
		return
	
	sprite.modulate.a = 0.0
	sprite.scale = unlock_scale_effect
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 1.0, unlock_effect_duration)
	tween.tween_property(sprite, "scale", self._base_scale, unlock_effect_duration)\
		 .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _play_visual_feedback():
	if not _is_ready or not sprite or not enable_visual_feedback:
		return
	
	var target_scale = self._base_scale * feedback_scale * (1.0 + 0.05 * current_combo_multiplier)
	target_scale.x = clamp(target_scale.x, self._base_scale.x, max_visual_scale.x)
	target_scale.y = clamp(target_scale.y, self._base_scale.y, max_visual_scale.y)
	
	if feedback_tween:
		feedback_tween.kill()
	feedback_tween = create_tween()
	feedback_tween.tween_property(sprite, "scale", target_scale, feedback_duration / 2)
	feedback_tween.tween_property(sprite, "scale", self._base_scale, feedback_duration / 2)
	
	if hit_particles:
		hit_particles.restart()
	
	if combo_count > 1 and combo_particles:
		combo_particles.restart()

### ======================
### ЗВУК И ОЧКИ
### ======================

func _play_sound(sound: AudioStream):
	if sound and audio_player:
		audio_player.stream = sound
		audio_player.play()

func _add_points(points: int):
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.add_score(points)
	
	if score_popup_scene:
		var popup = score_popup_scene.instantiate()
		if sprite:
			var viewport = get_viewport()
			var camera = viewport.get_camera_2d()
			var popup_pos = sprite.global_position
			if camera:
				popup_pos = camera.get_screen_position(sprite.global_position)
			popup.global_position = popup_pos + Vector2(0, -50)
		else:
			popup.global_position = global_position
		popup.set_points(points)
		get_tree().current_scene.add_child(popup)
		print("Instrument %s: ScorePopup created at %s with points %d" % [instrument_type, popup.global_position, points])

func _handle_fail_hit(_play_sound: bool):
	if fail_sound:
		_play_sound(fail_sound)
	
	if combo_enabled:
		combo_count = 0
		current_combo_multiplier = combo_multipliers[0]
		_update_info_display()

### ======================
### ОБРАБОТКА СОБЫТИЙ
### ======================

func _on_beat(_beat_number: int):
	_beat_hit_status.clear()

func _on_instrument_unlocked(_instrument_type: String):
	if _instrument_type == instrument_type:
		visible = true
		is_first_unlock = true
		if _is_ready:
			_play_unlock_effect()

func _on_instrument_upgraded(_instrument_type: String, level: int):
	if _instrument_type == instrument_type:
		current_level = level
		_update_appearance()

func _apply_upgrades():
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		current_level = gm.get_instrument_level(instrument_type)
		var settings = GlobalBalanceManager.get_instrument_level_settings(instrument_type, current_level)
		if settings.has("points"):
			points_per_click = settings.points
			_base_points = settings.points
		
		if gm.unlocked_combo_lines.has(instrument_type):
			_current_combo_pattern = []
			for i in range(gm.unlocked_combo_lines[instrument_type].size()):
				if gm.unlocked_combo_lines[instrument_type][i]:
					_current_combo_pattern.append(i)
		
		_unlocked_sound_indices.clear()
		for i in range(sound_pattern.size()):
			if i < current_level:
				_unlocked_sound_indices.append(i)
		
		_update_appearance()
