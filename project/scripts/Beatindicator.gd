extends Control

# Основные настройки
@export var bpm_manager: NodePath
@export var beat_count: int = 4
@export var rect_width: float = 100.0
@export var rect_height: float = 50.0
@export var margin: float = 50.0

# Цвета прямоугольников
@export var beat_colors: Array[Color] = [
	Color(Color.RED, 0.9),
	Color(Color.BLUE, 0.9),
	Color(Color.GREEN, 0.9),
	Color(Color.YELLOW, 0.9)
]

# Настройки индикатора
@export var indicator_color: Color = Color.WHITE
@export var indicator_width: float = 5.0
@export var indicator_height: float = 80.0
@export var indicator_position: float = 0.5

# Эффекты после прохождения
@export var use_secondary_colors: bool = true
@export var secondary_colors: Array[Color] = [
	Color(0.5, 0, 0, 0.7),    # Темно-красный
	Color(0, 0, 0.5, 0.7),    # Темно-синий
	Color(0, 0.5, 0, 0.7),    # Темно-зеленый
	Color(0.5, 0.5, 0, 0.7)   # Темно-желтый
]
@export var fade_after_pass: bool = true
@export var fade_speed: float = 0.5

# Эффекты масштабирования
@export var scale_up_amount: float = 1.5
@export var scale_down_amount: float = 0.0
@export var scale_effect_distance: float = 200.0

# Эффекты границ
@export var fade_distance: float = 100.0 # Дистанция от краев для исчезновения

# Системные переменные
var _bpm_manager: BPM_Manager
var _beat_rects: Array[ColorRect] = []
var _indicator: ColorRect
var _speed: float = 0.0
var _current_beat: int = 0
var _viewport_width: float = 0.0
var _indicator_x: float = 0.0
var _is_playing: bool = false

class BeatRectData:
	var rect: ColorRect
	var has_passed: bool = false
	var original_color: Color
	var current_alpha: float = 1.0
	var base_height: float = 0.0
	var is_active: bool = true
	var was_scaled: bool = false
	var color_index: int = 0  # Для корректного сопоставления цветов

var _rect_data: Array[BeatRectData] = []

func _ready():
	_viewport_width = get_viewport_rect().size.x
	_indicator_x = _viewport_width * indicator_position
	
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.5
	anchor_bottom = 0.5
	offset_top = -rect_height/2
	offset_bottom = rect_height/2
	
	_bpm_manager = get_node_or_null(bpm_manager)
	if not _bpm_manager:
		push_error("BPM Manager not found!")
		return
	
	if beat_colors.is_empty():
		beat_colors = _generate_default_colors(beat_count)
	
	_create_indicator()
	_initialize_rects()
	
	if _bpm_manager.has_signal("beat_triggered"):
		_bpm_manager.beat_triggered.connect(_on_beat)
	else:
		push_error("BPM Manager doesn't have beat_triggered signal!")

func _generate_default_colors(count: int) -> Array[Color]:
	var colors: Array[Color] = []
	for i in range(count):
		var hue = float(i) / float(count)
		colors.append(Color.from_hsv(hue, 0.8, 0.8, 0.9))
	return colors

func _create_indicator():
	_indicator = ColorRect.new()
	_indicator.color = indicator_color
	_indicator.size = Vector2(indicator_width, indicator_height)
	
	_indicator.anchor_left = 0.0
	_indicator.anchor_right = 0.0
	_indicator.anchor_top = 0.5
	_indicator.anchor_bottom = 0.5
	_indicator.offset_left = _indicator_x - indicator_width/2
	_indicator.offset_right = _indicator_x + indicator_width/2
	_indicator.offset_top = -indicator_height/2
	_indicator.offset_bottom = indicator_height/2
	
	add_child(_indicator)

func _initialize_rects():
	# Количество прямоугольников, видимых на экране + запас
	var visible_rects = ceil((_viewport_width - _indicator_x + margin) / rect_width) + beat_count
	
	# Дополнительные прямоугольники, которые будут появляться из-за экрана
	var buffer_rects = ceil(_viewport_width / rect_width)
	
	for i in range(visible_rects + buffer_rects):
		var rect = ColorRect.new()
		rect.size = Vector2(rect_width, rect_height)
		
		# Начинаем сразу после индикатора, остальные появляются за экраном
		var start_x = _indicator_x + i * rect_width
		
		rect.anchor_left = 0.0
		rect.anchor_right = 0.0
		rect.anchor_top = 0.5
		rect.anchor_bottom = 0.5
		rect.offset_left = start_x
		rect.offset_right = start_x + rect_width
		rect.offset_top = -rect_height/2
		rect.offset_bottom = rect_height/2
		
		var rect_data = BeatRectData.new()
		rect_data.rect = rect
		rect_data.color_index = i % beat_count
		rect_data.original_color = beat_colors[rect_data.color_index]
		rect_data.base_height = rect_height
		rect_data.is_active = true
		
		rect.color = rect_data.original_color
		_update_rect_visibility(rect_data)
		
		_rect_data.append(rect_data)
		_beat_rects.append(rect)
		add_child(rect)

func _process(delta):
	if not _bpm_manager:
		return
	
	# Обновляем прозрачность для всех прямоугольников
	for rect_data in _rect_data:
		_update_rect_visibility(rect_data)
	
	if not _bpm_manager.is_playing:
		return
	
	if not _is_playing:
		_is_playing = true
	
	var beat_duration = 60.0 / _bpm_manager.bpm
	_speed = rect_width / beat_duration
	
	for rect_data in _rect_data:
		var rect = rect_data.rect
		
		# Движение
		rect.offset_left -= _speed * delta
		rect.offset_right -= _speed * delta
		
		# Проверка прохождения индикатора
		if not rect_data.has_passed and rect.offset_right < _indicator_x:
			rect_data.has_passed = true
			if use_secondary_colors and secondary_colors.size() > rect_data.color_index:
				# Используем тот же индекс для вторичного цвета
				rect.color = secondary_colors[rect_data.color_index]
			# Мгновенный сброс масштаба
			rect.offset_top = -rect_data.base_height/2
			rect.offset_bottom = rect_data.base_height/2
			rect_data.was_scaled = false
		
		# Масштабирование только перед индикатором
		if not rect_data.has_passed:
			_handle_scale_effect(rect_data)
		
		# Перемещение вышедших за границы
		if rect.offset_right < -margin:
			_recycle_rect(rect_data)

func _update_rect_visibility(rect_data: BeatRectData):
	var rect = rect_data.rect
	var left_edge = rect.offset_left
	var right_edge = rect.offset_right
	
	# Исчезание у левой границы экрана
	var left_fade = clamp((left_edge + fade_distance) / fade_distance, 0.0, 1.0)
	
	# Исчезание у правой границы экрана
	var right_fade = clamp((_viewport_width - right_edge + fade_distance) / fade_distance, 0.0, 1.0)
	
	# Комбинированная прозрачность
	rect.modulate.a = min(left_fade, right_fade) * rect_data.current_alpha

func _handle_scale_effect(rect_data: BeatRectData):
	var rect = rect_data.rect
	var center_x = rect.offset_left + rect_width/2
	var dist_to_indicator = abs(center_x - _indicator_x)
	
	if dist_to_indicator < scale_effect_distance and not rect_data.has_passed:
		var t = 1.0 - (dist_to_indicator / scale_effect_distance)
		
		if scale_up_amount > 1.0:
			rect.offset_top = -rect_data.base_height/2 * lerp(1.0, scale_up_amount, t)
		
		if scale_down_amount > 1.0:
			rect.offset_bottom = rect_data.base_height/2 * lerp(1.0, scale_down_amount, t)
		
		rect_data.was_scaled = true

func _recycle_rect(rect_data: BeatRectData):
	var rect = rect_data.rect
	
	# 1. Находим самый правый прямоугольник
	var furthest_right = -INF
	for r in _beat_rects:
		if r.offset_right > furthest_right:
			furthest_right = r.offset_right
	
	# 2. Если не нашли (массив пуст), ставим за правой границей экрана
	if furthest_right == -INF:
		furthest_right = _viewport_width + margin
	
	# 3. Перемещаем прямоугольник вплотную к последнему
	rect.offset_left = furthest_right
	rect.offset_right = rect.offset_left + rect_width
	
	# 4. Полный сброс состояния
	rect_data.has_passed = false
	rect_data.current_alpha = 1.0
	rect_data.was_scaled = false
	
	# 5. Восстановление размеров
	rect.offset_top = -rect_data.base_height/2
	rect.offset_bottom = rect_data.base_height/2
	
	# 6. Обновление цвета (сохраняем индекс цвета)
	var new_index = (_current_beat + _rect_data.size()) % beat_count
	rect_data.color_index = new_index
	rect_data.original_color = beat_colors[new_index]
	rect.color = beat_colors[new_index]
	
	# 7. Перемещение в конец массивов
	_rect_data.erase(rect_data)
	_rect_data.append(rect_data)
	_beat_rects.erase(rect)
	_beat_rects.append(rect)
	
	# 8. Обновляем прозрачность
	_update_rect_visibility(rect_data)

func _on_beat(beat_number: int):
	_current_beat = beat_number
	
	var tween = create_tween()
	tween.tween_property(_indicator, "modulate:a", 1.0, 0.05)
	tween.tween_property(_indicator, "modulate:a", 0.7, 0.2)
