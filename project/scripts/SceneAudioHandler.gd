extends Node

@export_category("Music Settings")
@export var use_local_music: bool = false
@export var local_music: AudioStream

var audio_manager

func _ready():
	if Engine.is_editor_hint():
		return
	
	# Получаем автозагрузку без указания типа
	audio_manager = get_node("/root/AudioManager")
	
	if use_local_music and local_music:
		audio_manager.play_level_music(local_music)

func _exit_tree():
	if use_local_music and local_music:
		audio_manager.stop_level_music()
