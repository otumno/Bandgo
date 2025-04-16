extends Node
class_name BPM_Manager

# Сигналы
signal beat_triggered(beat_number: int)
signal pattern_detected(pattern: Array)

@export var bpm: int = 120:
	set(value):
		bpm = clamp(value, 40, 300)
		_update_beat_timer()

@export var metronome_pattern: Array[int] = [1, 2, 3, 0]
@export var metronome_sounds: Array[AudioStream]

@export var analysis_window: int = 4  # Количество тактов для анализа

var is_playing := false
var current_beat := 0
var players: Array[AudioStreamPlayer] = []
var beat_timer: Timer
var beat_history: Array[int] = []  # История тактов для анализа

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
	
	# Сохраняем текущий такт в историю
	beat_history.append(current_beat)
	while beat_history.size() > analysis_window * 2:  # Ограничиваем размер истории
		beat_history.remove_at(0)
	
	# Воспроизводим звук для текущего такта
	var sound_idx = metronome_pattern[current_beat % metronome_pattern.size()]
	if sound_idx > 0 and sound_idx <= players.size():
		players[sound_idx - 1].play()
	
	# Уведомляем о новом такте
	emit_signal("beat_triggered", current_beat)
	
	# Проверяем паттерн и эмитируем сигнал, если он найден
	_check_for_pattern()
	
	current_beat += 1

func _check_for_pattern():
	if beat_history.size() < analysis_window * 2:
		return
	
	var last_window = beat_history.slice(-analysis_window)
	var prev_window = beat_history.slice(-analysis_window * 2, -analysis_window)
	
	if last_window == prev_window:
		emit_signal("pattern_detected", last_window)
		print("Emitting signal 'pattern_detected' from BPM_Manager:", last_window)

# Проверка паттерна
func check_pattern(pattern: Array) -> bool:
	if pattern.size() != analysis_window:
		return false
	
	var total_beats = beat_history.size()
	if total_beats < analysis_window * 2:
		return false
	
	# Проверяем, совпадает ли последний интервал с заданным паттерном
	for i in range(analysis_window):
		if beat_history[total_beats - analysis_window + i] != pattern[i]:
			return false
	return true
