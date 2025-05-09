extends Node
# Полностью безопасная система сохранений с проверкой типов

const SAVE_PATH := "user://saves/"
const SAVE_VERSION := 2
const MAX_SLOTS := 3

# Типизированные структуры данных
class SaveData:
	var version: int
	var player_name: String
	var score: int
	var unlocked_instruments: Array[String]
	var upgrade_levels: Dictionary
	var unlocked_combo_lines: Dictionary
	
	func _init() -> void:
		version = SAVE_VERSION
		player_name = ""
		score = 0
		unlocked_instruments = []
		upgrade_levels = {}
		unlocked_combo_lines = {}

func _init() -> void:
	_ensure_save_directory_exists()

func _ensure_save_directory_exists() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_PATH):
		var err = DirAccess.make_dir_recursive_absolute(SAVE_PATH)
		if err != OK:
			push_error("Failed to create save directory: ", SAVE_PATH, " Error: ", err)

# Основной метод сохранения
func save_game(slot: int) -> bool:
	if slot < 1 or slot > MAX_SLOTS:
		push_error("Invalid slot number: ", slot)
		return false
	
	var file_path := _get_save_path(slot)
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	
	if not file:
		push_error("Failed to open save file for writing: ", file_path)
		return false
	
	var save_data := _prepare_save_data()
	if not _validate_save_data(save_data):
		push_error("Save data validation failed!")
		return false
	
	file.store_var(save_data)
	file.close()
	print("Game saved to slot ", slot)
	return true

# Основной метод загрузки
func load_game(slot: int) -> bool:
	if slot < 1 or slot > MAX_SLOTS:
		push_error("Invalid slot number: ", slot)
		return false
	
	var file_path := _get_save_path(slot)
	if not FileAccess.file_exists(file_path):
		print("Save file doesn't exist: ", file_path)
		return false
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Failed to open save file for reading: ", file_path)
		return false
	
	var loaded_data = file.get_var()
	file.close()
	
	if not _validate_loaded_data(loaded_data):
		push_error("Loaded data validation failed!")
		return false
	
	return _apply_loaded_data(loaded_data)

# Получение информации о сохранении (для UI)
func get_save_info(slot: int) -> Dictionary:
	if slot < 1 or slot > MAX_SLOTS:
		return {}
	
	var file_path := _get_save_path(slot)
	if not FileAccess.file_exists(file_path):
		return {}
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return {}
	
	var data = file.get_var()
	file.close()
	
	if not _validate_loaded_data(data):
		return {}
	
	return {
		"player_name": str(data.get("player_name", "")),
		"score": int(data.get("score", 0)),
		"version": int(data.get("version", 0))
	}

# Удаление сохранения
func delete_save(slot: int) -> bool:
	if slot < 1 or slot > MAX_SLOTS:
		return false
	
	var file_path := _get_save_path(slot)
	if not FileAccess.file_exists(file_path):
		return true
	
	var dir := DirAccess.open("user://")
	if not dir:
		return false
	
	var err := dir.remove(file_path)
	return err == OK

# Формирование данных для сохранения
func _prepare_save_data() -> Dictionary:
	var gm := _get_game_manager()
	if not gm:
		return {}
	
	return {
		"version": SAVE_VERSION,
		"player_name": str(gm.player_name),
		"score": int(gm.score),
		"unlocked_instruments": _ensure_string_array(gm.unlocked_instruments),
		"upgrade_levels": gm.upgrade_levels.duplicate(true),
		"unlocked_combo_lines": gm.unlocked_combo_lines.duplicate(true)
	}

# Применение загруженных данных
func _apply_loaded_data(data: Dictionary) -> bool:
	var gm := _get_game_manager()
	if not gm:
		return false
	
	gm.player_name = str(data.get("player_name", "Player"))
	gm.score = int(data.get("score", 0))
	gm.unlocked_instruments = _ensure_string_array(data.get("unlocked_instruments", []))
	gm.upgrade_levels = data.get("upgrade_levels", {}).duplicate(true)
	gm.unlocked_combo_lines = data.get("unlocked_combo_lines", {}).duplicate(true)
	
	gm.emit_signal("score_updated", gm.score)
	gm.emit_signal("upgrades_updated")
	return true

# Валидация данных перед сохранением
func _validate_save_data(data: Dictionary) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	
	var required_fields := [
		"version", "player_name", "score", 
		"unlocked_instruments", "upgrade_levels", "unlocked_combo_lines"
	]
	
	for field in required_fields:
		if not data.has(field):
			return false
	
	# Проверка типов
	return (
		typeof(data.player_name) == TYPE_STRING and
		typeof(data.score) == TYPE_INT and
		typeof(data.unlocked_instruments) == TYPE_ARRAY and
		typeof(data.upgrade_levels) == TYPE_DICTIONARY and
		typeof(data.unlocked_combo_lines) == TYPE_DICTIONARY
	)

# Валидация загруженных данных
func _validate_loaded_data(data) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	
	if data.get("version", 0) != SAVE_VERSION:
		push_warning("Save version mismatch!")
		return false
	
	return _validate_save_data(data)

# Вспомогательные методы
func _get_save_path(slot: int) -> String:
	return SAVE_PATH + "save_%d.dat" % slot

func _ensure_string_array(array: Array) -> Array[String]:
	var result: Array[String] = []
	for item in array:
		if item is String:
			result.append(item)
		else:
			result.append(str(item))
	return result

func _get_game_manager() -> Node:
	return get_node_or_null("/root/GameManager")
