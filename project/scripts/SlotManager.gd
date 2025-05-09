extends Control

@onready var slot_buttons: Array[Button] = [
	$SlotUI/HBoxContainer/Slot1Button,
	$SlotUI/HBoxContainer2/Slot2Button,
	$SlotUI/HBoxContainer3/Slot3Button
]

@onready var delete_buttons: Array[Button] = [
	$SlotUI/HBoxContainer/DeleteSlot1,
	$SlotUI/HBoxContainer2/DeleteSlot2,
	$SlotUI/HBoxContainer3/DeleteSlot3
]

@onready var confirm_dialog: ConfirmationDialog = $ConfirmDialog
@onready var name_dialog: Window = $NameDialog
@onready var name_input: LineEdit = $NameDialog/VBoxContainer/NameEdit
@onready var name_ok_button: Button = $NameDialog/VBoxContainer/HBoxContainer/OKButton

var current_slot := 0
var _is_transitioning := false

func _ready():
	_setup_dialogs()
	_connect_signals()
	update_slots_display()
	confirm_dialog.confirmed.connect(_on_confirm_delete)

func _setup_dialogs():
	confirm_dialog.dialog_text = "Удалить сохранение?"
	name_dialog.title = "Введите имя игрока"

func _connect_signals():
	for i in slot_buttons.size():
		if slot_buttons[i]:
			slot_buttons[i].pressed.connect(_on_slot_pressed.bind(i + 1))
		if delete_buttons[i]:
			delete_buttons[i].pressed.connect(_on_delete_pressed.bind(i + 1))
	
	name_input.text_submitted.connect(_on_name_confirmed)
	name_ok_button.pressed.connect(_on_name_confirmed)

func update_slots_display():
	for i in 3:
		var save_info = SaveSystem.get_save_info(i + 1)
		if save_info.is_empty():
			slot_buttons[i].text = "Слот %d" % (i + 1)
			delete_buttons[i].visible = false
		else:
			slot_buttons[i].text = "%s\nОчки: %d" % [
				str(save_info.get("player_name", "")),
				int(save_info.get("score", 0))
			]
			delete_buttons[i].visible = true

func _on_slot_pressed(slot_number: int):
	if _is_transitioning: 
		return
	
	current_slot = slot_number
	var save_info = SaveSystem.get_save_info(slot_number)
	
	if save_info.is_empty():
		name_input.clear()
		name_dialog.popup_centered()
		name_input.grab_focus()
	else:
		_start_game_transition()

func _on_delete_pressed(slot_number: int):
	current_slot = slot_number
	confirm_dialog.popup_centered()

func _on_confirm_delete():
	if SaveSystem.delete_save(current_slot):
		update_slots_display()
	else:
		push_error("Не удалось удалить сохранение!")

func _on_name_confirmed(_text = ""):
	var input_name = name_input.text.strip_edges()
	if input_name.is_empty(): 
		return
	
	var gm = get_node("/root/GameManager")
	if gm:
		# Создаем новый массив строк для инструментов
		var initial_instruments: Array[String] = ["xylophone"]
		
		gm.reset()
		gm.player_name = input_name
		gm.score = 0
		gm.current_slot = current_slot
		gm.unlocked_instruments = initial_instruments
		
		if SaveSystem.save_game(current_slot):
			name_dialog.hide()
			_start_game_transition()

func _start_game_transition():
	if _is_transitioning: 
		return
	
	_is_transitioning = true
	
	var save_data = SaveSystem.get_save_info(current_slot)
	if save_data.is_empty():
		# Создаём новый массив с явным указанием типа
		var initial_instruments: Array[String] = ["xylophone"]
		
		GameManager.reset()
		GameManager.player_name = "Player"
		GameManager.score = 0
		GameManager.current_slot = current_slot
		GameManager.unlocked_instruments = initial_instruments
	else:
		# Загружаем через SaveSystem с гарантией преобразования типов
		if not SaveSystem.load_game(current_slot):
			push_error("Ошибка загрузки сохранения!")
			_is_transitioning = false
			return
	
	# Переход на сцену
	var target_scene = "res://project/scenes/Game.tscn"
	if has_node("/root/SceneTransitionManager"):
		get_node("/root/SceneTransitionManager").transition_to_scene(target_scene)
	else:
		if get_tree().change_scene_to_file(target_scene) != OK:
			push_error("Ошибка загрузки сцены!")
	
	_is_transitioning = false
