extends Control

signal game_loaded(slot_number: int)
signal save_deleted(slot_number: int)

# Элементы UI с альтернативной инициализацией
@onready var slot_buttons: Array[Button] = [
	find_child("Slot1Button"),
	find_child("Slot2Button"),
	find_child("Slot3Button")
]

@onready var delete_buttons: Array[Button] = [
	find_child("DeleteSlot1"),
	find_child("DeleteSlot2"),
	find_child("DeleteSlot3")
]

@onready var back_button: Button = find_child("BackButton")
@onready var confirm_dialog: ConfirmationDialog = find_child("ConfirmDialog")
@onready var name_dialog: Window = find_child("NameDialog")
@onready var name_input: LineEdit = find_child("NameEdit")
@onready var name_ok_button: Button = find_child("OKButton")

var current_slot := 0

func _ready() -> void:
	# Проверка инициализации
	if not _validate_ui_elements():
		push_error("Не удалось инициализировать все UI элементы!")
		print_uninitialized_elements()
		queue_free()
		return
	
	# Настройка
	_setup_dialogs()
	_connect_signals()
	update_slots_display()

func _validate_ui_elements() -> bool:
	# Проверяем кнопки слотов
	for i in 3:
		if not is_instance_valid(slot_buttons[i]):
			return false
		if not is_instance_valid(delete_buttons[i]):
			return false
	
	# Проверяем остальные элементы
	return (is_instance_valid(back_button) and
			is_instance_valid(confirm_dialog) and
			is_instance_valid(name_dialog) and
			is_instance_valid(name_input) and
			is_instance_valid(name_ok_button))

func print_uninitialized_elements() -> void:
	var missing := []
	
	for i in 3:
		if not is_instance_valid(slot_buttons[i]):
			missing.append("Slot%dButton" % (i+1))
		if not is_instance_valid(delete_buttons[i]):
			missing.append("DeleteSlot%d" % (i+1))
	
	if not is_instance_valid(back_button):
		missing.append("BackButton")
	if not is_instance_valid(confirm_dialog):
		missing.append("ConfirmDialog")
	if not is_instance_valid(name_dialog):
		missing.append("NameDialog")
	if not is_instance_valid(name_input):
		missing.append("NameEdit")
	if not is_instance_valid(name_ok_button):
		missing.append("OKButton")
	
	push_error("Отсутствующие элементы: ", missing)

func _setup_dialogs() -> void:
	# Настройка диалога подтверждения
	confirm_dialog.dialog_autowrap = true
	confirm_dialog.get_label().horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_dialog.get_ok_button().text = "Удалить"
	confirm_dialog.get_cancel_button().text = "Отмена"
	
	# Настройка диалога ввода имени
	name_dialog.title = "Введите имя игрока"
	name_dialog.size = Vector2(300, 150)

func _connect_signals() -> void:
	# Подключаем кнопки слотов
	for i in 3:
		slot_buttons[i].pressed.connect(_on_slot_pressed.bind(i + 1))
		delete_buttons[i].pressed.connect(_on_delete_pressed.bind(i + 1))
	
	# Другие элементы
	back_button.pressed.connect(_on_back_pressed)
	name_ok_button.pressed.connect(_on_name_confirmed)
	name_input.text_submitted.connect(_on_name_submitted)

func update_slots_display() -> void:
	for i in 3:
		var slot_num := i + 1
		var save_info := SaveSystem.get_save_info(slot_num)
		
		if save_info.is_empty():
			slot_buttons[i].text = "Slot %d" % slot_num
			delete_buttons[i].visible = false
		else:
			slot_buttons[i].text = "%s\n%d Fame" % [
				save_info["player_name"], 
				save_info["fame"]
			]
			delete_buttons[i].visible = true

func _on_slot_pressed(slot_number: int) -> void:
	var save_info := SaveSystem.get_save_info(slot_number)
	if save_info.is_empty():
		current_slot = slot_number
		name_input.text = ""
		name_dialog.popup_centered()
		name_input.grab_focus()
	else:
		if SaveSystem.load_game(slot_number):
			game_loaded.emit(slot_number)

func _on_delete_pressed(slot_number: int) -> void:
	confirm_dialog.dialog_text = "Удалить сохранение в слоте %d?\nЭто действие нельзя отменить!" % slot_number
	confirm_dialog.popup_centered()
	
	var confirmed: bool = await confirm_dialog.confirmed
	if confirmed and SaveSystem.delete_save(slot_number):
		save_deleted.emit(slot_number)
		update_slots_display()

func _on_name_confirmed() -> void:
	_process_name_input()

func _on_name_submitted(_text: String) -> void:
	_process_name_input()

func _process_name_input() -> void:
	var player_name := name_input.text.strip_edges()
	if not player_name.is_empty():
		SaveSystem.player_name = player_name
		SaveSystem.fame = 0
		if SaveSystem.save_game(current_slot):
			name_dialog.hide()
			game_loaded.emit(current_slot)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
