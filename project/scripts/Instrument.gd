extends Area2D

@export var correct_sound_pattern: Array[AudioStream]
@export var fail_sound: AudioStream
@export var first_click_sound: AudioStream

var pattern_index := 0
var last_hit_time := 0.0

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		var current_time = Time.get_ticks_msec()
		if last_hit_time == 0.0:
			_handle_first_click()
		else:
			_handle_regular_click(current_time)
		last_hit_time = current_time

func _handle_first_click():
	$AudioStreamPlayer.stream = first_click_sound
	$AudioStreamPlayer.play()
	_add_points(GlobalBalanceManager.points_per_click)

func _handle_regular_click(current_time: float):
	var balance = get_node("/root/GlobalBalanceManager")
	var window = balance.rhythm_window_before_ms + balance.rhythm_window_after_ms
	var beat_time = (60.0 / get_node("/root/Game/BPM_Manager").bpm) * 1000
	
	if fmod(current_time - last_hit_time, beat_time) <= window:
		_play_correct_sound()
		_add_points(balance.points_per_click * balance.in_rhythm_multiplier)
	else:
		$AudioStreamPlayer.stream = fail_sound
		$AudioStreamPlayer.play()
		_add_points(balance.points_per_click)

func _play_correct_sound():
	if correct_sound_pattern.is_empty(): return
	$AudioStreamPlayer.stream = correct_sound_pattern[pattern_index % correct_sound_pattern.size()]
	$AudioStreamPlayer.play()
	pattern_index += 1

func _add_points(points: int):
	get_node("/root/GameManager").add_score(points)
	get_node("/root/Game").update_ui(get_node("/root/GameManager"))
