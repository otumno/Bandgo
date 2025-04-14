extends Window

signal name_entered(player_name: String)

@onready var name_edit: LineEdit = %NameEdit
@onready var ok_button: Button = %OKButton

func _ready() -> void:
	ok_button.pressed.connect(_on_ok_pressed)
	name_edit.text_submitted.connect(_on_text_submitted)

func show_input() -> void:
	name_edit.text = ""
	popup_centered()
	name_edit.grab_focus()

func _on_ok_pressed() -> void:
	_submit_name()

func _on_text_submitted(_new_text: String) -> void:
	_submit_name()

func _submit_name() -> void:
	var player_name = name_edit.text.strip_edges()
	if !player_name.is_empty():
		name_entered.emit(player_name)
		hide()
