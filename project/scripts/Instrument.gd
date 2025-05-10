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
@export var auto_position_display: bool = true

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
	
	if info_display:
		if info_display.has_method("update_display"):
			info_display.update_display(current_level, current_combo_multiplier)
			print("Instrument %s: Initial display update - Level: %d, Multiplier: %d, Display visible: %s" % [instrument_type, current_level, current_combo_multiplier, info_display.visible])
		else:
			push_warning("Instrument %s: InfoDisplay missing update_display() method" % instrument_type)
	else:
		push_warning("Instrument %s: info_display is null" % instrument_type)

func _process(_delta: float):
	if auto_position_display and info_display and sprite and _is_ready:
		var sprite_bottom = sprite.global_position.y + sprite.texture.get_height() * sprite.scale.y
		info_display.global_position.x = sprite.global_position.x + sprite.texture.get_width() * sprite.scale.x / 2 - info_display.size.x / 2
		info_display.global_position.y = sprite_bottom + display_offset.y
		if not info_display.visible:
			info_display.visible = true
			print("Instrument %s: Forced info_display visible in _process" % instrument_type)

### ======================
### МЕТОДЫ ИНИЦИАЛИЗАЦИИ
### ======================

func _load_balance_settings():
	"""Загрузка настроек баланса из GlobalBalanceManager"""
	var settings = GlobalBalanceManager.instrument_settings.get(instrument_type, {})
	_base_points = settings.get("points_per_click", 10)
	points_per_click = _base_points
	combo_window_seconds = settings.get("combo_window_seconds", combo_reset_delay)
	combo_multipliers = Array(settings.get("combo_multipliers", PackedInt32Array([2, 3, 5, 8, 10])))
	allow_multiple_hits_per_beat = settings.get("allow_multiple_hits", false)
	# Инициализация _unlocked_sound_indices
	if sound_pattern.size() > 0:
		_unlocked_sound_indices.append(0) # Первый звук доступен по умолчанию
	current_combo_multiplier = combo_multipliers[0] # Устанавливаем начальный множитель

func _initialize_nodes():
	"""Инициализация и поиск необходимых нод"""
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
	"""Инициализация масштаба с защитой от ошибок"""
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
	"""Подключение всех необходимых сигналов"""
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
	"""Первоначальная настройка инструмента"""
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		current_level = gm.get_instrument_level(instrument_type)
		if current_level >= 1:
			visible = true
		_apply_upgrades() # Обновляем комбо и звуки при инициализации
		
		if info_display and info_display.has_method("update_display"):
			info_display.update_display(current_level, current_combo_multiplier)
			print("Instrument %s: Setup display update - Level: %d, Multiplier: %d, Display visible: %s" % [instrument_type, current_level, current_combo_multiplier, info_display.visible])

func _update_appearance():
	"""Обновление визуального представления"""
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
	"""Обработка ввода"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click()

func _handle_click():
	"""Основная логика обработки клика"""
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
	"""Обновление состояния комбо"""
	var time_since_last_combo = (current_time - last_combo_time) / 1000.0
	
	if time_since_last_combo > combo_window_seconds:
		if combo_count > 0:
			combo_count = 0
			current_combo_multiplier = combo_multipliers[0] # Начальный множитель
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
	"""Обновление отображения информации"""
	if info_display and info_display.has_method("update_display"):
		info_display.update_display(current_level, current_combo_multiplier)
		print("Instrument %s: Info display update - Level: %d, Multiplier: %d, Display visible: %s" % [instrument_type, current_level, current_combo_multiplier, info_display.visible])

### ======================
### ВИЗУАЛЬНЫЕ ЭФФЕКТЫ
### ======================

func _play_unlock_effect():
	"""Эффект при разблокировке инструмента"""
	if not _is_ready or not sprite:
		return
	
	sprite.modulate.a = 0.0
	sprite.scale = unlock_scale_effect
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 1.0, unlock_effect_duration)
	tween.tween_property(sprite, "scale", self._base_scale, unlock_effect_duration)\
		 .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _play_visual_feedback():
	"""Визуальный эффект при клике"""
	if not _is_ready or not sprite or not enable_visual_feedback:
		return
	
	var target_scale = self._base_scale * feedback_scale * (1.0 + 0.05 * current_combo_multiplier)
	target_scale.x = clamp(target_scale.x, self._base_scale.x, max_visual_scale.x)
	target_scale.y = clamp(target_scale.y, self._base_scale.y, max_visual_scale.y)
	
	if feedback_tween:
		feedback_tween.kill()
	
	feedback_tween = create_tween()
	feedback_tween.tween_property(sprite, "scale", target_scale, feedback_duration * 0.5)\
				 .set_ease(Tween.EASE_OUT)
	feedback_tween.tween_property(sprite, "scale", self._base_scale, feedback_duration * 0.5)\
				 .set_ease(Tween.EASE_IN)
	
	_emit_particles(true)

func _emit_particles(_is_in_rhythm: bool):
	if hit_particles:
		hit_particles.emitting = true
	if combo_count >= 3 and combo_particles:
		combo_particles.emitting = true
		if combo_colors.size() > 0:
			var color_idx = min(combo_count - 3, combo_colors.size() - 1)
			combo_particles.modulate = combo_colors[color_idx]

### ======================
### ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
### ======================

func _play_sound(sound: AudioStream):
	"""Воспроизведение звука"""
	if audio_player and sound:
		audio_player.stream = sound
		audio_player.play()

func _add_points(points: int):
	"""Добавление очков с визуальным отображением"""
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("add_score"):
		gm.add_score(points)
		if score_popup_scene:
			var popup_position = sprite.global_position if sprite else global_position
			_show_score_popup(points, popup_position)

func _show_score_popup(points: int, popup_pos: Vector2):
	"""Отображение попапа с очками"""
	var popup = score_popup_scene.instantiate()
	get_tree().root.add_child(popup)
	var color = _get_popup_color()
	popup.show_score(points, popup_pos, color, current_combo_multiplier)

func _get_popup_color() -> Color:
	"""Получение цвета для попапа в зависимости от комбо"""
	if combo_count >= 3 and combo_colors.size() > 0:
		var color_idx = min(combo_count - 3, combo_colors.size() - 1)
		return combo_colors[color_idx]
	return Color.WHITE

func _handle_fail_hit(is_double_hit: bool):
	"""Обработка неудачного попадания"""
	combo_count = 0
	current_combo_multiplier = combo_multipliers[0] # Сбрасываем на начальный множитель
	_play_fail_sound()
	_add_points(points_per_click if !is_double_hit else 0)
	if is_double_hit:
		_show_combo_reset("Double hit!")
	_update_info_display()
	print("Instrument %s: Fail hit - Multiplier reset to: %d" % [instrument_type, current_combo_multiplier])

func _show_combo_reset(message: String):
	"""Отображение сообщения о сбросе комбо"""
	var popup_position = sprite.global_position if sprite else global_position
	if score_popup_scene:
		var popup = score_popup_scene.instantiate()
		get_tree().root.add_child(popup)
		popup.show_score(message, popup_position, Color.RED, 1)

func _play_fail_sound():
	"""Воспроизведение звука ошибки"""
	if fail_sound:
		_play_sound(fail_sound)

### ======================
### ОБРАБОТЧИКИ СИГНАЛОВ
### ======================

func _on_instrument_unlocked(unlocked_type: String):
	"""Обработка разблокировки инструмента"""
	if unlocked_type == instrument_type:
		visible = true
		_update_appearance()
		
		if is_first_unlock:
			is_first_unlock = false
			call_deferred("_play_unlock_effect")

func _on_instrument_upgraded(upgraded_type: String, level: int):
	"""Обработка улучшения инструмента"""
	if upgraded_type == instrument_type:
		current_level = level
		_apply_upgrades() # Обновляем комбо и звуки
		if info_display and info_display.has_method("update_display"):
			info_display.update_display(current_level, current_combo_multiplier)
			print("Instrument %s: Upgrade display update - Level: %d, Multiplier: %d, Display visible: %s" % [instrument_type, current_level, current_combo_multiplier, info_display.visible])

func _on_beat(beat_number: int):
	"""Обработка бита от BPM менеджера"""
	if sound_pattern.size() > 0:
		current_pattern_index = beat_number % sound_pattern.size()

func _apply_upgrades():
	"""Применение улучшений"""
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		current_level = gm.get_instrument_level(instrument_type)
		_update_appearance()
		
		# Обновление звуковых паттернов
		_unlocked_sound_indices.clear()
		var combo_lines = gm.unlocked_combo_lines.get(instrument_type, [])
		if sound_pattern.size() > 1: # Добавляем новые паттерны только если звуков больше одного
			for i in combo_lines.size():
				if i < sound_pattern.size() and combo_lines[i]:
					_unlocked_sound_indices.append(i)
		if _unlocked_sound_indices.is_empty() and sound_pattern.size() > 0:
			_unlocked_sound_indices.append(0) # Гарантируем, что хотя бы один звук доступен
		
		# Обновление множителей комбо
		var combo_upgrade_id = instrument_type + "_combo"
		var combo_level = gm.upgrade_levels.get(combo_upgrade_id, 0)
		var settings = GlobalBalanceManager.upgrades_settings.get(combo_upgrade_id, {})
		if settings.has("bonus_per_level"):
			combo_multipliers = settings["bonus_per_level"].slice(0, combo_level + 1)
		if combo_multipliers.is_empty():
			combo_multipliers = GlobalBalanceManager.instrument_settings.get(instrument_type, {}).get("combo_multipliers", [2, 3, 5, 8, 10])
		
		# Сбрасываем текущий множитель на начальный
		current_combo_multiplier = combo_multipliers[0]
		_update_info_display()
		print("Instrument %s: Apply upgrades - Multipliers: %s, Current Multiplier: %d" % [instrument_type, combo_multipliers, current_combo_multiplier])
