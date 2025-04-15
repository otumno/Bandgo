extends Node

@export_category("Music Settings")
@export var use_local_music: bool = false
@export var local_music: AudioStream
@export_range(0, 1, 0.01) var music_volume: float = 1.0:
	set(value):
		music_volume = clamp(value, 0, 1)
		_update_music_volume()

var audio_manager

func _ready():
	if Engine.is_editor_hint():
		return
	
	audio_manager = get_node("/root/AudioManager")
	
	if use_local_music and local_music:
		audio_manager.play_level_music(local_music)
		_update_music_volume()

func _update_music_volume():
	if audio_manager and audio_manager.has_method("set_music_volume"):
		audio_manager.set_music_volume(music_volume)

func _exit_tree():
	if use_local_music and local_music:
		audio_manager.stop_level_music()
