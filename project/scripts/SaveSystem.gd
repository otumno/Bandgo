extends Node
# Система сохранения/загрузки игры

const SAVE_PATH = "user://saves/"
const SAVE_VERSION = 2

func _init():
	# Создаем папку для сохранений при инициализации
	if not DirAccess.dir_exists_absolute(SAVE_PATH):
		DirAccess.make_dir_recursive_absolute(SAVE_PATH)

# Сохранение игры в указанный слот
func save_game(slot: int) -> bool:
	var file_path = _get_save_path(slot)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if not file:
		push_error("Ошибка создания файла сохранения: ", file_path)
		return false
	
	var save_data = GameManager.get_save_data()
	file.store_var(save_data)
	file.close()
	print("Игра сохранена в слот ", slot, ": ", save_data)
	return true

# Загрузка игры из слота
func load_game(slot: int) -> bool:
	var file_path = _get_save_path(slot)
	
	if not FileAccess.file_exists(file_path):
		print("Файл сохранения не существует: ", file_path)
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Ошибка открытия файла сохранения: ", file_path)
		return false
	
	var save_data = file.get_var()
	file.close()
	
	if typeof(save_data) != TYPE_DICTIONARY:
		push_error("Неверный формат данных в файле: ", file_path)
		return false
	
	# Проверка версии сохранения
	if save_data.get("version", 0) != SAVE_VERSION:
		push_warning("Версия сохранения не совпадает!")
		return false
	
	GameManager.load_save_data(save_data)
	GameManager.current_slot = slot
	print("Игра загружена из слота ", slot, ": ", save_data)
	return true

# Получение информации о сохранении
func get_save_info(slot: int) -> Dictionary:
	var file_path = _get_save_path(slot)
	
	if not FileAccess.file_exists(file_path):
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return {}
	
	var data = file.get_var()
	file.close()
	
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	
	return data

# Удаление сохранения
func delete_save(slot: int) -> bool:
	var file_path = _get_save_path(slot)
	
	if FileAccess.file_exists(file_path):
		var dir = DirAccess.open("user://")
		if dir:
			var err = dir.remove(file_path)
			if err == OK:
				print("Сохранение удалено: ", file_path)
				return true
			else:
				push_error("Ошибка удаления файла: ", err)
	return false

# Принудительное сохранение (используется при выходе)
func force_save() -> bool:
	return save_game(GameManager.current_slot)

# Формирование пути к файлу сохранения
func _get_save_path(slot: int) -> String:
	return SAVE_PATH + "save_%d.dat" % slot
