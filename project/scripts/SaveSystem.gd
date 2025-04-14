extends Node

const SAVE_PATH := "user://save_data_%d.dat"  # Используем := для типизированных констант

var current_slot : int = 0
var player_name : String = ""
var fame : int = 0

func save_game(slot: int) -> bool:
	var save_data := {
		"player_name": player_name,
		"fame": fame,
		"timestamp": Time.get_unix_time_from_system()  # Заменяем OS на Time
	}
	
	var file := FileAccess.open(SAVE_PATH % slot, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		return true
	else:
		push_error("Error saving game: ", FileAccess.get_open_error())
		return false

func load_game(slot: int) -> bool:
	if not FileAccess.file_exists(SAVE_PATH % slot):
		return false
		
	var file := FileAccess.open(SAVE_PATH % slot, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		player_name = save_data["player_name"]
		fame = save_data["fame"]
		current_slot = slot
		return true
	else:
		push_error("Error loading game: ", FileAccess.get_open_error())
		return false

func delete_save(slot: int) -> bool:
	if FileAccess.file_exists(SAVE_PATH % slot):
		DirAccess.remove_absolute(SAVE_PATH % slot)  # Заменяем Directory на DirAccess
		return true
	return false

func get_save_info(slot: int) -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH % slot):
		return {}
		
	var file := FileAccess.open(SAVE_PATH % slot, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		return {
			"player_name": save_data["player_name"],
			"fame": save_data["fame"],
			"timestamp": save_data.get("timestamp", 0)
		}
	return {}
