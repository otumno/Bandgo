extends Node
class_name PatternAnalyzer

signal pattern_verified(pattern: Array[bool])

@export var bpm_manager: BPM_Manager
@export var analysis_window: int = 4
@export var required_matches: int = 2
@export var auto_repeat_count: int = 3

enum State { IDLE, RECORDING, CHECKING, AUTOMATING }

var state: State = State.IDLE
var current_beat := 0
var beat_inputs: Dictionary = {}  # beat_number -> bool
var input_buffer: Array[bool] = []
var recorded_pattern: Array[bool] = []
var match_count := 0

func _ready():
	if not bpm_manager:
		bpm_manager = BPM_GlobalManager
	if bpm_manager:
		bpm_manager.beat_triggered.connect(_on_beat)
	else:
		push_error("No BPM_Manager assigned or found!")

func register_input(beat: int):
	beat_inputs[beat] = true

func _on_beat(beat_number: int):
	current_beat = beat_number

	var was_pressed: bool = beat_inputs.get(beat_number, false)
	input_buffer.append(was_pressed)
	while input_buffer.size() > analysis_window:
		input_buffer.remove_at(0)

	# Удаляем старые события, чтобы не накапливались
	beat_inputs.erase(beat_number - analysis_window)

	match state:
		State.IDLE:
			if input_buffer.size() == analysis_window and _has_any_true(input_buffer):
				recorded_pattern = input_buffer.duplicate()
				match_count = 0
				state = State.CHECKING
				print("Recorded pattern:", recorded_pattern)

		State.CHECKING:
			if input_buffer == recorded_pattern:
				match_count += 1
				print("Pattern matched. Match count:", match_count)
			else:
				match_count = 0
				print("Pattern mismatch. Resetting count.")

			if match_count >= required_matches:
				state = State.AUTOMATING
				emit_signal("pattern_verified", recorded_pattern)

		State.AUTOMATING:
			pass

func _has_any_true(arr: Array[bool]) -> bool:
	for value in arr:
		if value:
			return true
	return false

func reset():
	input_buffer.clear()
	recorded_pattern.clear()
	match_count = 0
	state = State.IDLE
