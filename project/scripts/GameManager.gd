extends Node

signal score_updated(new_score)

var player_name: String = "Player"
var score: int = 0
var current_slot: int = 1

func reset():
	player_name = "Player"
	score = 0
	emit_signal("score_updated", score)

func add_score(points: int):
	score += points
	emit_signal("score_updated", score)
