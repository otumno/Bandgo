extends Button
class_name SceneTransitionButton

@export_category("Transition Settings")
enum TransitionType { SCENE, QUIT }
@export var transition_mode: TransitionType = TransitionType.SCENE
@export_file("*.tscn") var target_scene_path: String
@export var transition_sound: AudioStream
@export var transition_duration: float = 1.0
@export var fade_color: Color = Color.BLACK

@export_category("Debug")
@export var debug_logging: bool = true

var is_transitioning: bool = false
var audio_player: AudioStreamPlayer

func _ready():
	_init_audio_player()
	connect("pressed", Callable(self, "_on_button_pressed"))

func _init_audio_player():
	if not has_node("AudioStreamPlayer"):
		audio_player = AudioStreamPlayer.new()
		audio_player.name = "AudioStreamPlayer"
		add_child(audio_player)
	else:
		audio_player = $AudioStreamPlayer
	audio_player.stream = transition_sound

func _on_button_pressed():
	if debug_logging:
		print_debug("Button pressed, mode: ", transition_mode)
	await start_transition()

func start_transition():
	if is_transitioning:
		return
	is_transitioning = true
	set_disabled(true)

	# Создаем затемнение
	var fade_rect = _create_fade_rect()
	
	# Параллельный запуск звука и анимации
	var tween = create_tween().set_parallel(true)
	
	if transition_sound:
		audio_player.play()
		tween.tween_callback(audio_player.play)
	
	tween.tween_property(fade_rect, "color:a", 1.0, transition_duration)
	await tween.finished

	# Выполняем действие после анимации
	match transition_mode:
		TransitionType.SCENE:
			if not target_scene_path.is_empty():
				if ResourceLoader.exists(target_scene_path):
					get_tree().change_scene_to_file(target_scene_path)
				else:
					push_error("Scene file not found: ", target_scene_path)
		TransitionType.QUIT:
			get_tree().quit()
	
	# В реальности эта часть выполнится только если переход не сработал
	fade_rect.queue_free()
	is_transitioning = false
	set_disabled(false)

func _create_fade_rect() -> ColorRect:
	var rect = ColorRect.new()
	rect.color = fade_color
	rect.color.a = 0.0
	rect.size = get_viewport().size
	get_tree().root.add_child(rect)
	return rect
