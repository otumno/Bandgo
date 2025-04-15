extends Node
class_name SceneTransitionManager

@export var default_fade_duration: float = 1.0
@export var default_fade_color: Color = Color.BLACK

func transition_to_scene(scene_path: String, fade_duration: float = -1.0, fade_color: Color = Color(-1,-1,-1)):
	if fade_duration < 0:
		fade_duration = default_fade_duration
	if fade_color == Color(-1,-1,-1):
		fade_color = default_fade_color
	
	# Получаем Viewport
	var viewport = get_tree().root
	
	# Создаем эффект затемнения
	var fade_rect := ColorRect.new()
	fade_rect.color = fade_color
	fade_rect.color.a = 0.0
	fade_rect.size = viewport.size  # Используем размер Viewport
	fade_rect.z_index = 1000
	viewport.add_child(fade_rect)
	
	# Анимация
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, fade_duration)
	await tween.finished
	
	# Переход на сцену
	if get_tree().change_scene_to_file(scene_path) != OK:
		push_error("Failed to load scene: ", scene_path)
	
	# Очистка
	fade_rect.queue_free()
