extends Panel

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var upgrades_container: HBoxContainer = $ScrollContainer/HBoxContainer
@onready var close_button: Button = $CloseButton
@onready var purchase_sound: AudioStreamPlayer = $PurchaseSound
@onready var error_sound: AudioStreamPlayer = $ErrorSound

var upgrade_button_scene = preload("res://project/scenes/UpgradeButton.tscn")

const BUTTON_MARGIN := 10
const SECTION_HEADER_MARGIN := 20

func _ready():
	# Инициализация GameManager
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		push_error("GameManager not found!")
		return
	
	# Настройка контейнера
	if not upgrades_container:
		upgrades_container = HBoxContainer.new()
		scroll_container.add_child(upgrades_container)
	
	upgrades_container.add_theme_constant_override("separation", BUTTON_MARGIN)
	close_button.pressed.connect(hide)
	gm.upgrades_updated.connect(update_upgrades_list)
	update_upgrades_list()

func update_upgrades_list():
	# Очистка только кнопок (сохраняем заголовки)
	for child in upgrades_container.get_children():
		if not (child is Label or child.get_class() == "Control"):
			child.queue_free()
	
	await get_tree().process_frame
	
	# Создаем разделы
	_add_section_header("Unlock Instruments")
	_create_unlock_buttons()
	
	_add_section_header("Upgrade Instruments")
	for instrument in GameManager.unlocked_instruments:
		_create_instrument_upgrades(instrument)
	
	_add_section_header("Global Upgrades")
	_create_global_upgrades()

func _add_section_header(title: String):
	var header = Label.new()
	header.text = title
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color.GOLDENROD)
	upgrades_container.add_child(header)
	
	var margin = Control.new()
	margin.custom_minimum_size.y = SECTION_HEADER_MARGIN
	upgrades_container.add_child(margin)

func _create_unlock_buttons():
	for inst_type in GlobalBalanceManager.initial_instruments:
		if not GameManager.unlocked_instruments.has(inst_type):
			var settings = GlobalBalanceManager.initial_instruments[inst_type]
			var button = upgrade_button_scene.instantiate()
			
			button.setup(
				inst_type + "_unlock",
				{
					"name": "Unlock " + settings["display_name"],
					"cost_per_level": [settings["initial_cost"]],
					"bonus_per_level": [1]
				},
				0
			)
			button.pressed.connect(_on_upgrade_pressed.bind(inst_type + "_unlock"))
			upgrades_container.add_child(button)

func _create_instrument_upgrades(instrument: String):
	var current_level = GameManager.get_instrument_level(instrument)
	
	# Улучшение уровня инструмента
	if current_level < GlobalBalanceManager.get_max_instrument_level(instrument):
		var button = upgrade_button_scene.instantiate()
		button.setup(
			instrument + "_unlock",
			GlobalBalanceManager.upgrades_settings.get(instrument + "_unlock", {}),
			current_level
		)
		button.pressed.connect(_on_upgrade_pressed.bind(instrument + "_unlock"))
		upgrades_container.add_child(button)
	
	# Улучшение комбо
	var combo_level = GameManager.upgrade_levels.get(instrument + "_combo", 0)
	if combo_level < 5:  # Максимум 5 уровней комбо
		var button = upgrade_button_scene.instantiate()
		button.setup(
			instrument + "_combo",
			{
				"name": instrument.capitalize() + " Combo",
				"cost_per_level": [500, 1000, 2000, 4000, 8000],
				"bonus_per_level": [2, 4, 6, 8, 10]
			},
			combo_level
		)
		button.pressed.connect(_on_upgrade_pressed.bind(instrument + "_combo"))
		upgrades_container.add_child(button)

func _create_global_upgrades():
	for upgrade_id in GlobalBalanceManager.global_upgrades:
		var current_level = GameManager.upgrade_levels.get(upgrade_id, 0)
		if current_level < GlobalBalanceManager.global_upgrades[upgrade_id]["cost_per_level"].size():
			var button = upgrade_button_scene.instantiate()
			button.setup(
				upgrade_id,
				GlobalBalanceManager.global_upgrades[upgrade_id],
				current_level
			)
			button.pressed.connect(_on_upgrade_pressed.bind(upgrade_id))
			upgrades_container.add_child(button)

func _on_upgrade_pressed(upgrade_id: String):
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		error_sound.play()
		return
	
	var settings: Dictionary
	if upgrade_id in GlobalBalanceManager.global_upgrades:
		settings = GlobalBalanceManager.global_upgrades[upgrade_id]
	elif upgrade_id.ends_with("_combo"):
		settings = {
			"cost_per_level": [500, 1000, 2000, 4000, 8000],
			"bonus_per_level": [2, 4, 6, 8, 10]
		}
	else:
		settings = GlobalBalanceManager.upgrades_settings.get(upgrade_id, {})
	
	var current_level = gm.upgrade_levels.get(upgrade_id, 0)
	var costs = settings.get("cost_per_level", [])
	
	if current_level >= costs.size():
		error_sound.play()
		return
	
	if gm.upgrade(upgrade_id, costs[current_level]):
		purchase_sound.play()
	else:
		error_sound.play()
		_animate_error_feedback()

func _animate_error_feedback():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 0.5, 0.5), 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.4)
