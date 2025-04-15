extends ConfirmationDialog

signal confirmed

func _ready() -> void:
	# Настройка диалога
	dialog_autowrap = true
	get_label().horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Подключаем сигналы кнопок
	confirmed.connect(_on_confirmed)
	cancel_button.pressed.connect(_on_cancel_pressed)

func show_confirmation(message: String) -> void:
	dialog_text = message
	popup_centered()

func _on_confirmed() -> void:
	confirmed.emit()
	hide()

func _on_cancel_pressed() -> void:
	hide()
