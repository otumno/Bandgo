extends ConfirmationDialog

# Переименованный сигнал, чтобы избежать конфликта с родительским классом
signal confirmation_accepted

func _ready() -> void:
	# Настройка диалога
	dialog_autowrap = true
	get_label().horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Настройка текста кнопок
	get_ok_button().text = "Подтвердить"
	get_cancel_button().text = "Отмена"
	
	# Подключаем сигналы кнопок
	confirmed.connect(_on_confirmed)
	get_cancel_button().pressed.connect(_on_cancel_pressed)

func show_confirmation(message: String) -> void:
	dialog_text = message
	popup_centered()

func _on_confirmed() -> void:
	# Испускаем наш кастомный сигнал
	confirmation_accepted.emit()
	hide()

func _on_cancel_pressed() -> void:
	hide()
