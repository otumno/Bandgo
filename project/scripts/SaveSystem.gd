extends Node

const SAVE_PATH = "user://saves/"

func save_game(slot: int) -> bool:
	if not DirAccess.dir_exists_absolute(SAVE_PATH):
		DirAccess.make_dir_recursive_absolute(SAVE_PATH)

	var file = FileAccess.open(_get_save_path(slot), FileAccess.WRITE)
	if not file:
		push_error("Ошибка создания файла сохранения!")
		return false

	var save_data = {
		"version": 2,
		"player_name": GameManager.player_name,
		"score": GameManager.score,
		"unlocked_instruments": GameManager.unlocked_instruments,
		"upgrade_levels": GameManager.upgrade_levels,
		"unlocked_combo_lines": GameManager.unlocked_combo_lines
	}
	
	file.store_var(save_data)
	return true

func load_game(slot: int) -> bool:  # <-- Основной метод (была лишняя вложенная версия)
	var path = _get_save_path(slot)
	if not FileAccess.file_exists(path):
		return false

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Ошибка открытия файла сохранения!")
		return false

	if file.get_length() < 4:
		push_error("Файл сохранения повреждён (слишком маленький)")
		return false

	var save_data = file.get_var()
	if typeof(save_data) != TYPE_DICTIONARY:
		push_error("Неверный формат данных сохранения")
		return false

	var gm = get_node("/root/GameManager")
	gm.player_name = save_data.get("player_name", "Player")
	gm.score = save_data.get("score", 0)
	gm.unlocked_instruments = save_data.get("unlocked_instruments", [])
	gm.upgrade_levels = save_data.get("upgrade_levels", {})
	gm.unlocked_combo_lines = save_data.get("unlocked_combo_lines", {})
	gm.current_slot = slot
	
	return true

func get_save_info(slot: int) -> Dictionary:
	var path = _get_save_path(slot)
	if not FileAccess.file_exists(path):
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}

	if file.get_length() < 4:
		return {}

	var data = file.get_var()
	if typeof(data) != TYPE_DICTIONARY:
		return {}

	return data

func delete_save(slot: int) -> bool:
	var path = _get_save_path(slot)
	if FileAccess.file_exists(path):
		var dir = DirAccess.open("user://")
		if dir:
			var err = dir.remove(path)
			if err == OK:
				return true
			else:
				push_error("Ошибка удаления файла: ", err)
	return false

func _get_save_path(slot: int) -> String:
	return SAVE_PATH + "save_%d.dat" % slot
