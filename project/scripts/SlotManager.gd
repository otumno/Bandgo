extends Control

signal game_loaded(slot_number: int)
signal save_deleted(slot_number: int)

# Элементы UI
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

# Настройки перехода
@export var transition_sound: AudioStream
@export var fade_duration: float = 0.5
@export var target_scene: String = "res://Game.tscn"

var current_slot := 0

func _ready() -> void:
	_setup_dialogs()
	_connect_signals()
	update_slots_display()

func _setup_dialogs() -> void:
	# Настройка ConfirmDialog (встроенный ConfirmationDialog)
	confirm_dialog.dialog_autowrap = true
	confirm_dialog.get_label().horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_dialog.get_ok_button().text = "Да"
	confirm_dialog.get_cancel_button().text = "Отмена"
	
	# Настройка NameDialog
	name_dialog.title = "Введите имя игрока"

func _connect_signals() -> void:
	for i in 3:
		slot_buttons[i].pressed.connect(_on_slot_pressed.bind(i + 1))
		delete_buttons[i].pressed.connect(_on_delete_pressed.bind(i + 1))
	
	name_ok_button.pressed.connect(_on_name_confirmed)
	name_input.text_submitted.connect(_on_name_submitted)
	
	# Подключаем сигналы ConfirmationDialog
	confirm_dialog.confirmed.connect(_on_confirm_dialog_confirmed)

func update_slots_display() -> void:
	for i in 3:
		var slot_num := i + 1
		var save_info := SaveSystem.get_save_info(slot_num)
		
		if save_info.is_empty():
			slot_buttons[i].text = "Slot %d" % slot_num
			delete_buttons[i].visible = false
		else:
			slot_buttons[i].text = "%s\n%d Fame" % [save_info["player_name"], save_info["fame"]]
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
			_transition_to_game(slot_number)

func _on_delete_pressed(slot_number: int) -> void:
	confirm_dialog.dialog_text = "Удалить сохранение в слоте %d?" % slot_number
	confirm_dialog.popup_centered()
	var confirmed: bool = await confirm_dialog.confirmed
	if confirmed and SaveSystem.delete_save(slot_number):
		save_deleted.emit(slot_number)
		update_slots_display()

func _on_confirm_dialog_confirmed() -> void:
	# Обработка подтверждения в диалоге
	pass

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
			_transition_to_game(current_slot)

func _transition_to_game(slot_number: int) -> void:
	# Воспроизведение звука перехода
	if transition_sound:
		var audio_player = AudioStreamPlayer.new()
		add_child(audio_player)
		audio_player.stream = transition_sound
		audio_player.play()
		await audio_player.finished
		audio_player.queue_free()
	
	# Анимация затемнения
	var fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.size = get_viewport_rect().size
	fade_rect.modulate.a = 0.0
	add_child(fade_rect)
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, fade_duration)
	await tween.finished
	
	# Переход на сцену
	get_tree().change_scene_to_file(target_scene)
	
	# Оповещение о загрузке игры
	game_loaded.emit(slot_number)
