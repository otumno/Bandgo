extends Button
class_name SceneTransitionButton

@export_category("Transition Settings")
enum TransitionType { SCENE, QUIT }
@export var transition_mode: TransitionType = TransitionType.SCENE
@export_file("*.tscn") var target_scene_path: String
@export var transition_sound: AudioStream
@export var transition_duration: float = 1.0
@export var fade_color: Color = Color.BLACK

var is_transitioning: bool = false
var audio_player: AudioStreamPlayer

func _ready() -> void:
	_init_audio_player()
	connect("pressed", _on_button_pressed)

func _init_audio_player() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "TransitionAudioPlayer"
	add_child(audio_player)
	audio_player.stream = transition_sound

func _on_button_pressed() -> void:
	if is_transitioning:
		return
	
	# Останавливаем музыку сразу при нажатии (только для выхода из игры)
	if transition_mode == TransitionType.QUIT:
		var audio_manager = get_node("/root/AudioManager")
		if audio_manager:
			audio_manager.stop_music()
	
	# Воспроизводим звук нажатия
	if transition_sound:
		audio_player.play()
	
	await start_transition()

func start_transition() -> void:
	is_transitioning = true
	disabled = true

	# Получаем корневой Viewport
	var viewport = get_tree().root
	
	# Создаем эффект затемнения
	var fade_rect := ColorRect.new()
	fade_rect.color = fade_color
	fade_rect.color.a = 0.0
	fade_rect.size = viewport.size
	fade_rect.z_index = 1000
	viewport.add_child(fade_rect)

	# Анимация затемнения
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, transition_duration)
	await tween.finished

	# Выполняем действие после завершения анимации
	match transition_mode:
		TransitionType.SCENE:
			if target_scene_path and ResourceLoader.exists(target_scene_path):
				get_tree().change_scene_to_file(target_scene_path)
			else:
				push_error("Target scene not found: ", target_scene_path)
		TransitionType.QUIT:
			get_tree().quit()

	# Очистка
	if is_instance_valid(fade_rect):
		fade_rect.queue_free()
	
	is_transitioning = false
	disabled = false
