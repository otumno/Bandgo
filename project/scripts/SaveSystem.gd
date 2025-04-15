extends Node

const SAVE_PATH = "user://saves/"

func save_game(slot: int) -> bool:
	if not DirAccess.dir_exists_absolute(SAVE_PATH):
		DirAccess.make_dir_recursive_absolute(SAVE_PATH)

	var file = FileAccess.open(_get_save_path(slot), FileAccess.WRITE)
	if not file:
		push_error("Ошибка создания файла сохранения!")
		return false

	var gm = get_node("/root/GameManager")
	file.store_var({
		"player_name": gm.player_name,
		"score": gm.score,
		"timestamp": Time.get_unix_time_from_system()
	})
	return true

func load_game(slot: int) -> bool:
	var path = _get_save_path(slot)
	if not FileAccess.file_exists(path):
		return false

	var file = FileAccess.open(path, FileAccess.READ)
	var save_data = file.get_var()

	var gm = get_node("/root/GameManager")
	gm.player_name = save_data.get("player_name", "Player")
	gm.score = save_data.get("score", 0)
	gm.current_slot = slot
	return true

func get_save_info(slot: int) -> Dictionary:
	var path = _get_save_path(slot)
	if not FileAccess.file_exists(path):
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	var data = file.get_var()
	return data if typeof(data) == TYPE_DICTIONARY else {}

func delete_save(slot: int) -> bool:
	var path = _get_save_path(slot)
	if FileAccess.file_exists(path):
		var dir = DirAccess.open("user://")
		if dir:
			return dir.remove(path) == OK
	return false

func _get_save_path(slot: int) -> String:
	return SAVE_PATH + "save_%d.dat" % slot
