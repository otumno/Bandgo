extends Node
# НЕ используем class_name для автозагрузки!

@export_category("Music Settings")
@export var global_music: AudioStream
@export var level_music: AudioStream

var is_global_active := true
var music_player: AudioStreamPlayer

func _ready():
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	play_global_music()

func play_global_music():
	is_global_active = true
	if global_music:
		music_player.stream = global_music
		music_player.play()

func play_level_music(music: AudioStream):
	is_global_active = false
	music_player.stream = music
	music_player.play()

func stop_music():
	music_player.stop()

func stop_level_music():
	play_global_music()
