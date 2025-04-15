extends Node
signal beat_triggered(beat_number: int)

@export var bpm: int = 120
@export var metronome_pattern: Array[int] = [1, 2, 3, 0]
@export var metronome_sounds: Array[AudioStream]

var is_playing := false
var current_beat := 0

func _ready():
	for _i in metronome_sounds.size():
		var player = AudioStreamPlayer.new()
		add_child(player)

func start():
	if is_playing: return
	is_playing = true
	_process_beat()

func _process_beat():
	while is_playing:
		var sound_idx = metronome_pattern[current_beat % metronome_pattern.size()]
		if sound_idx > 0:
			get_child(sound_idx-1).play()
		
		emit_signal("beat_triggered", current_beat)
		current_beat += 1
		await get_tree().create_timer(60.0 / bpm).timeout
