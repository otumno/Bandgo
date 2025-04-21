extends Node
class_name PatternAnalyzer

signal pattern_verified(recorded_pattern: Array[bool], instrument_map: Dictionary)

@export var bpm_manager: Node
@export var auto_repeat_count: int = 2
@export var required_matches: int = 1

var pattern_length: int = 0
var input_buffer: Array[bool] = []
var instrument_buffer: Array[String] = []

var reference_pattern: Array[bool] = []
var reference_instruments: Array[String] = []

var match_count: int = 0
var state := "IDLE"
var beat_index := 0

func _ready():
	if bpm_manager == null:
		bpm_manager = get_parent().find_child("BPM_Manager", true, false)
	if bpm_manager:
		bpm_manager.beat_triggered.connect(_on_beat)
		pattern_length = bpm_manager.metronome_pattern.size()

func register_input(instrument_name: String):
	while instrument_buffer.size() <= beat_index:
		instrument_buffer.append("")
	instrument_buffer[beat_index] = instrument_name
	while input_buffer.size() <= beat_index:
		input_buffer.append(false)
	input_buffer[beat_index] = true

func _on_beat(_beat: int):
	beat_index += 1
	var _current := false
	if beat_index < input_buffer.size():
		_current = input_buffer[beat_index]

	match state:
		"IDLE":
			if beat_index >= pattern_length:
				var slice = input_buffer.slice(beat_index - pattern_length, beat_index)
				if slice.any(func(x): return x):
					reference_pattern = slice.duplicate()
					reference_instruments = instrument_buffer.slice(beat_index - pattern_length, beat_index)
					match_count = 0
					state = "CHECKING"

		"CHECKING":
			if beat_index >= pattern_length:
				var slice = input_buffer.slice(beat_index - pattern_length, beat_index)
				if slice == reference_pattern:
					match_count += 1
					if match_count >= required_matches:
						state = "AUTOMATING"
						emit_signal("pattern_verified", reference_pattern, reference_instruments)
				else:
					match_count = 0
					reference_pattern = slice.duplicate()
					reference_instruments = instrument_buffer.slice(beat_index - pattern_length, beat_index)

		"AUTOMATING":
			pass
