extends Node

# Объявление сигнала
signal pattern_detected(pattern: Array)

@export var required_matches: int = 2  # Сколько раз должен повториться паттерн
@export var bpm_manager: BPM_Manager

var current_sequence: Array = []
var pattern_buffer: Array = []
var match_count: int = 0

func _ready():
	# Получаем BPM_GlobalManager из автозагрузки
	bpm_manager = BPM_GlobalManager as BPM_Manager
	
	if bpm_manager:
		print("BPM Manager connected successfully")
		bpm_manager.beat_triggered.connect(_on_beat)
	else:
		push_error("BPM Manager not found in autoload!")

func _on_beat(beat_number: int):
	current_sequence.append(beat_number)
	
	if current_sequence.size() > bpm_manager.analysis_window:
		current_sequence.remove_at(0)
	
	if current_sequence.size() == bpm_manager.analysis_window:
		var is_match = bpm_manager.check_pattern(current_sequence)
		
		if is_match:
			match_count += 1
			pattern_buffer = current_sequence.duplicate()
			print("Pattern match detected in PatternAnalyzer! Match count:", match_count)
		else:
			match_count = 0
			print("No pattern match in PatternAnalyzer. Resetting match count.")
		
		if match_count >= required_matches:
			emit_signal("pattern_detected", pattern_buffer)
			match_count = 0
			print("Emitting signal 'pattern_detected' with pattern:", pattern_buffer)

func _on_pattern_detected(pattern: Array):
	print("Pattern detected in PatternAnalyzer:", pattern)
