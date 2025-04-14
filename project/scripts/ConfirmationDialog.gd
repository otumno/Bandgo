extends ConfirmationDialog

@onready var message_label: Label = $VBoxContainer/MessageLabel
@onready var cancel_button: Button = $VBoxContainer/HBoxContainer/CancelButton
@onready var confirm_button: Button = $VBoxContainer/HBoxContainer/ConfirmButton

func _ready() -> void:
	# Настройка кнопок
	cancel_button.pressed.connect(_on_cancel_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)

func show_confirmation(message: String) -> void:
	message_label.text = message
	popup_centered()

func _on_cancel_pressed() -> void:
	hide()

func _on_confirm_pressed() -> void:
	confirmed.emit()
	hide()
