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
	# Добавлена проверка на пустой паттерн
	if metronome_pattern.is_empty():
		metronome_pattern = [1] # Устанавливаем минимальный паттерн по умолчанию
		push_warning("BPM_Manager: metronome_pattern is empty, using default [1]")
	_initialize_players()
	_setup_timer()

func _initialize_players():
	for sound in metronome_sounds:
		var player = AudioStreamPlayer.new()
		player.stream = sound
		player.bus = "SFX"
		add_child(player)
		players.append(player)

func _setup_timer():
	beat_timer = Timer.new()
	beat_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	add_child(beat_timer)
	_update_beat_timer()

func _update_beat_timer():
	if beat_timer:
		beat_timer.wait_time = 60.0 / bpm

func start_metronome():
	if is_playing:
		return
	is_playing = true
	current_beat = 0
	_process_beat()
	if not beat_timer.timeout.is_connected(_process_beat):
		beat_timer.timeout.connect(_process_beat)
	beat_timer.start()

func stop_metronome():
	is_playing = false
	if beat_timer:
		beat_timer.stop()
		if beat_timer.timeout.is_connected(_process_beat):
			beat_timer.timeout.disconnect(_process_beat)

func _process_beat():
	if not is_playing:
		return
	# Добавлена проверка на пустой паттерн перед использованием %
	var pattern_size = max(1, metronome_pattern.size())
	var sound_idx = metronome_pattern[current_beat % pattern_size]
	if sound_idx > 0 and sound_idx <= players.size():
		players[sound_idx - 1].play()
	emit_signal("beat_triggered", current_beat)
	current_beat += 1
