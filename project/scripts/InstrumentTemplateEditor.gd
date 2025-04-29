extends Control

@onready var tab_container: TabContainer = $VBoxContainer/TabContainer
@onready var copy_button: Button = $VBoxContainer/HBoxContainer/CopyButton

func _ready():
	# Принудительно устанавливаем минимальный размер
	custom_minimum_size = Vector2(500, 400)
	
	# Ждем готовности всех узлов
	await get_tree().process_frame
	
	# Загружаем шаблоны
	_load_templates()
	copy_button.pressed.connect(_on_copy_pressed)

func _load_templates():
	# Явно получаем все TextEdit
	var instrument_text = _get_textedit("Instrument")
	var upgrades_text = _get_textedit("Upgrades")
	
	if instrument_text and upgrades_text:
		instrument_text.text = """{
	"example_instrument": {
		"points_per_click": 10,
		"combo_window_seconds": 2.0,
		"combo_multipliers": [1, 2, 3, 5, 8],
		"allow_multiple_hits": false
	}
}"""
		
		upgrades_text.text = """{
	"example_instrument_unlock": {
		"name": "Название апгрейда",
		"cost_per_level": [500, 1000, 2000],
		"bonus_per_level": [1, 2, 3],
		"unlocks_pattern_line": [0, 1, 2]
	}
}"""

func _get_textedit(tab_name: String) -> TextEdit:
	for i in range(tab_container.get_tab_count()):
		if tab_container.get_tab_title(i) == tab_name:
			var tab = tab_container.get_tab_control(i)
			return tab.get_node("TextEdit")
	return null

func _on_copy_pressed():
	var current_tab = tab_container.get_current_tab_control()
	var text_edit = current_tab.get_node("TextEdit")
	
	if text_edit:
		DisplayServer.clipboard_set(text_edit.text)
		print("Текст скопирован в буфер обмена!")
		# Визуальная обратная связь
		copy_button.text = "Скопировано!"
		await get_tree().create_timer(1.5).timeout
		copy_button.text = "Копировать"
