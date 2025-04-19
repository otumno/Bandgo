extends Node
class_name BPM_Manager

signal beat_triggered(beat_number: int)
signal pattern_detected(pattern: Array)

@export var bpm: int = 120:
	set(value):
		bpm = clamp(value, 40, 300)
		_update_beat_timer()

@export var metronome_pattern: Array[int] = [1, 2, 3, 0]
@export var metronome_sounds: Array[AudioStream]
@export var analysis_window: int = 4

var is_playing := false
var current_beat := 0
var players: Array[AudioStreamPlayer] = []
var beat_timer: Timer
var beat_history: Array[int] = []:
	get:
		return beat_history
	set(value):
		beat_history = value

func _ready():
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
	if is_playing: return
	
	is_playing = true
	current_beat = 0
	_process_beat()
	if !beat_timer.timeout.is_connected(_process_beat):
		beat_timer.timeout.connect(_process_beat)
	beat_timer.start()

func stop_metronome():
	is_playing = false
	if beat_timer:
		beat_timer.stop()
		if beat_timer.timeout.is_connected(_process_beat):
			beat_timer.timeout.disconnect(_process_beat)

func _process_beat():
	if !is_playing: return
	
	beat_history.append(current_beat)
	while beat_history.size() > analysis_window * 2:
		beat_history.remove_at(0)
	
	var sound_idx = metronome_pattern[current_beat % metronome_pattern.size()]
	if sound_idx > 0 and sound_idx <= players.size():
		players[sound_idx - 1].play()
	
	emit_signal("beat_triggered", current_beat)
	_check_for_pattern()
	current_beat += 1

func _check_for_pattern():
	if beat_history.size() < analysis_window * 2:
		return
	
	var last_window = beat_history.slice(-analysis_window)
	var prev_window = beat_history.slice(-analysis_window * 2, -analysis_window)
	
	if last_window == prev_window:
		emit_signal("pattern_detected", last_window)
