extends Node

@export_category("Music Settings")
@export var global_music: AudioStream
@export var level_music: AudioStream
@export_range(0, 1, 0.01) var default_volume: float = 1.0

var is_global_active := true
var music_player: AudioStreamPlayer

func _ready():
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	music_player.volume_db = linear_to_db(default_volume)
	add_child(music_player)
	play_global_music()

func set_music_volume(volume: float):
	music_player.volume_db = linear_to_db(clamp(volume, 0, 1))

func play_global_music():
	is_global_active = true
	if global_music:
		music_player.stream = global_music
		music_player.play()

func play_level_music(music: AudioStream):
	is_global_active = false
	music_player.stream = music
	music_player.play()

func stop_all_music():  # Переименованный метод
	music_player.stop()

func stop_level_music():
	play_global_music()
