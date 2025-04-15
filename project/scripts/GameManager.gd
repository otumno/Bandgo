extends Node

signal score_updated(new_score)
signal player_name_updated(new_name)

var player_name: String = "Player":
	set(value):
		player_name = value
		emit_signal("player_name_updated", value)

var score: int = 0:
	set(value):
		score = value
		emit_signal("score_updated", value)

var current_slot: int = 1

func reset():
	player_name = "Player"
	score = 0
	emit_signal("score_updated", score)

func add_score(points: int):
	score += points
	emit_signal("score_updated", score)
