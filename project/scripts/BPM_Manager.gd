extends Node
class_name BPM_Manager

signal beat_triggered(beat_number: int)

@export var bpm: int = 120:
	set(value):
		bpm = clamp(value, 40, 300)
		_update_beat_timer()

@export var metronome_pattern: Array[int] = [1, 2, 3, 0]
@export var metronome_sounds: Array[AudioStream]

var is_playing := false
var current_beat := 0
var players: Array[AudioStreamPlayer] = []
var beat_timer: Timer

func _ready():
	# Предварительная загрузка звуков
	for sound in metronome_sounds:
		var player = AudioStreamPlayer.new()
		player.stream = sound
		player.bus = "SFX"
		add_child(player)
		players.append(player)
	
	# Точный таймер
	beat_timer = Timer.new()
	beat_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	add_child(beat_timer)
	_update_beat_timer()

func _update_beat_timer():
	if beat_timer:
		beat_timer.wait_time = 60.0 / bpm

func start_metronome():
	if is_playing: return
	
	is_playing = true
	current_beat = 0
	_process_beat()
	beat_timer.timeout.connect(_process_beat)
	beat_timer.start()

func stop_metronome():
	is_playing = false
	if beat_timer:
		beat_timer.stop()
		beat_timer.timeout.disconnect(_process_beat)

func _process_beat():
	if !is_playing: return
	
	var sound_idx = metronome_pattern[current_beat % metronome_pattern.size()]
	if sound_idx > 0 and sound_idx <= players.size():
		players[sound_idx-1].play()
	
	emit_signal("beat_triggered", current_beat)
	current_beat += 1
