extends Button

@export_category("Transition Settings")
@export_file("*.tscn") var target_scene: String = "res://project/scenes/MainMenu.tscn"
@export var transition_sound: AudioStream
@export var fade_duration: float = 0.5
@export var fade_color: Color = Color.BLACK

var _is_transitioning := false

func _ready():
	connect("pressed", _on_pressed)

func _on_pressed():
	if _is_transitioning: 
		return
	
	_is_transitioning = true
	disabled = true  # Блокируем кнопку
	
	# 1. Сохраняем игру (без ожидания)
	_save_game()
	
	# 2. Создаем элементы для перехода
	var fade_rect = _create_fade_rect()
	var audio_player = _create_audio_player()
	
	# 3. Запускаем параллельные анимации
	var tween = create_tween().set_parallel(true)
	
	if audio_player:
		tween.tween_property(audio_player, "volume_db", 0.0, 0.1)  # Плавное появление звука
	
	tween.tween_property(fade_rect, "color:a", 1.0, fade_duration)
	await tween.finished
	
	# 4. Переход на сцену
	var result = get_tree().change_scene_to_file(target_scene)
	if result != OK:
		push_error("Ошибка загрузки сцены: ", result)
		get_tree().quit()
	
	# 5. Очистка (на всякий случай)
	if is_instance_valid(fade_rect):
		fade_rect.queue_free()
	if audio_player and is_instance_valid(audio_player):
		audio_player.queue_free()
	
	_is_transitioning = false

func _create_fade_rect() -> ColorRect:
	var fade_rect = ColorRect.new()
	fade_rect.color = fade_color
	fade_rect.color.a = 0.0  # Начинаем с прозрачного
	fade_rect.size = get_tree().root.size
	fade_rect.z_index = 1000
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Игнорируем клики
	get_tree().root.add_child(fade_rect)
	return fade_rect

func _create_audio_player() -> AudioStreamPlayer:
	if not transition_sound:
		return null
		
	var player = AudioStreamPlayer.new()
	player.stream = transition_sound
	player.volume_db = -80.0  # Начинаем с тихого звука
	add_child(player)
	player.play()
	return player

func _save_game() -> bool:
	var gm = get_node("/root/GameManager")
	return get_node("/root/SaveSystem").save_game(gm.current_slot)
