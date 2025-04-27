extends Control
@export_category("Transition Settings")
@export var transition_sound: AudioStream
@export var fade_duration: float = 0.5
@export var fade_color: Color = Color.BLACK
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
			if slot_buttons[i]:
				slot_buttons[i].text = "Слот %d" % (i + 1)
				delete_buttons[i].visible = false
		else:
			if slot_buttons[i]:
				slot_buttons[i].text = "%s\nОчки: %d" % [
					save_info.get("player_name", ""),
					save_info.get("score", 0)
				]
				delete_buttons[i].visible = true

func _on_slot_pressed(slot_number: int):
	if _is_transitioning: return
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
	if input_name.is_empty(): return
	var game_manager = get_node("/root/GameManager")
	if game_manager:
		game_manager.player_name = input_name
		game_manager.score = 0
		game_manager.current_slot = current_slot
		if SaveSystem.save_game(current_slot):
			name_dialog.hide()
			_start_game_transition()

func _start_game_transition():
	if _is_transitioning: return
	_is_transitioning = true
	if not SaveSystem.load_game(current_slot):
		push_error("Ошибка загрузки сохранения!")
		_is_transitioning = false
		return
	var fade_rect = _create_fade_rect()
	var audio_player = _create_audio_player()
	var tween = create_tween().set_parallel(true)
	if audio_player:
		tween.tween_property(audio_player, "volume_db", 0.0, 0.1)
	tween.tween_property(fade_rect, "color:a", 1.0, fade_duration)
	await tween.finished
	var target_scene = "res://project/scenes/Game.tscn"
	if has_node("/root/SceneTransitionManager"):
		get_node("/root/SceneTransitionManager").transition_to_scene(target_scene)
	else:
		if get_tree().change_scene_to_file(target_scene) != OK:
			push_error("Ошибка загрузки сцены!")
	if is_instance_valid(fade_rect):
		fade_rect.queue_free()

func _create_fade_rect() -> ColorRect:
	var fade_rect = ColorRect.new()
	fade_rect.color = fade_color
	fade_rect.color.a = 0.0
	fade_rect.size = get_tree().root.size
	fade_rect.z_index = 1000
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().root.add_child(fade_rect)
	return fade_rect

func _create_audio_player() -> AudioStreamPlayer:
	if not transition_sound: return null
	var player = AudioStreamPlayer.new()
	player.stream = transition_sound
	player.volume_db = -80.0
	add_child(player)
	player.play()
	return player
