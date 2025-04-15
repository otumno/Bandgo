extends Control
class_name PlayerUI

@export_category("UI Elements")
@export var player_name_label: Label
@export var score_label: Label

@export_category("Animation")
@export var score_animation: bool = true
@export var animation_scale: float = 1.2
@export var animation_duration: float = 0.3

var _game_manager: GameManager

func _ready():
	# Получаем GameManager
	_game_manager = get_node("/root/GameManager")
	
	# Подключаем сигналы
	_game_manager.connect("score_updated", _on_score_updated)
	_game_manager.connect("player_name_updated", _on_player_name_updated)
	
	# Инициализация значений
	_update_all_info()

func _update_all_info():
	player_name_label.text = _game_manager.player_name
	score_label.text = str(_game_manager.score)

func _on_score_updated(new_score: int):
	score_label.text = str(new_score)
	if score_animation:
		_play_score_animation()

func _on_player_name_updated(new_name: String):
	player_name_label.text = new_name

func _play_score_animation():
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(score_label, "scale", Vector2(animation_scale, animation_scale), animation_duration * 0.5)
	tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), animation_duration * 0.5)
