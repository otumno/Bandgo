extends Node
class_name BPM_SpritePulser

@export_category("Sprite Settings")
@export var target_sprite: Sprite2D
@export var frame_1_texture: Texture2D
@export var frame_2_texture: Texture2D

@export_category("Pulse Settings")
@export var pulse_scale: Vector2 = Vector2(1.1, 1.1)
@export var pulse_duration: float = 0.2
@export var beat_pattern: Array[int] = [1, 0, 1, 0]  # Когда менять кадры
@export var pulse_pattern: Array[int] = [1, 0, 1, 0]  # Когда делать пульсацию
@export var frame_2_display_time: float = 0.05  # Время показа фрейма 2 (в секундах)

var _bpm_manager: BPM_Manager
var _current_beat: int = 0

func _ready():
	# Инициализация BPM Manager
	_bpm_manager = BPM_GlobalManager as BPM_Manager
	if not _bpm_manager:
		push_error("BPM Manager not found!")
		return
	
	# Проверка спрайта
	if not target_sprite:
		push_error("Target sprite not assigned!")
		return
	
	# Установка начального кадра
	target_sprite.texture = frame_1_texture
	
	# Подключение к битам
	_bpm_manager.beat_triggered.connect(_on_beat)

func _on_beat(beat_number: int):
	_current_beat = beat_number % beat_pattern.size()
	
	# Пульсация
	if pulse_pattern[_current_beat] == 1:
		_pulse_sprite()
	
	# Смена кадра если нужно
	if beat_pattern[_current_beat] == 1:
		_show_frame_2()

func _pulse_sprite():
	var tween = create_tween().set_parallel(true)
	var original_scale = target_sprite.scale
	
	tween.tween_property(target_sprite, "scale", original_scale * pulse_scale, pulse_duration / 2)\
		 .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	tween.tween_property(target_sprite, "scale", original_scale, pulse_duration / 2)\
		 .set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)\
		 .set_delay(pulse_duration / 2)

func _show_frame_2():
	# Показываем фрейм 2 на короткое время
	target_sprite.texture = frame_2_texture
	
	# Возвращаемся к фрейму 1 через заданное время
	await get_tree().create_timer(frame_2_display_time).timeout
	target_sprite.texture = frame_1_texture

func set_textures(frame1: Texture2D, frame2: Texture2D):
	frame_1_texture = frame1
	frame_2_texture = frame2
	target_sprite.texture = frame_1_texture
