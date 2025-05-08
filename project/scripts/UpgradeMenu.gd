extends Panel

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var upgrades_container: VBoxContainer = $ScrollContainer/HBoxContainer
@onready var close_button: Button = $CloseButton
@onready var purchase_sound: AudioStreamPlayer = $PurchaseSound
@onready var error_sound: AudioStreamPlayer = $ErrorSound

var upgrade_button_scene = preload("res://project/scenes/UpgradeButton.tscn")

const BUTTON_MARGIN := 10
const SECTION_HEADER_MARGIN := 20

func _ready():
	# Проверка на случай отсутствия нод
	if not upgrades_container:
		upgrades_container = VBoxContainer.new()
		if scroll_container:
			var margin = MarginContainer.new()
			margin.add_child(upgrades_container)
			scroll_container.add_child(margin)
	
	upgrades_container.add_theme_constant_override("separation", BUTTON_MARGIN)
	close_button.pressed.connect(hide)
	GameManager.upgrades_updated.connect(update_upgrades_list)
	update_upgrades_list()

func update_upgrades_list():
	if not is_instance_valid(upgrades_container):
		push_error("Upgrades container not initialized!")
		return
	
	# Очистка старых кнопок (кроме заголовков)
	for child in upgrades_container.get_children():
		if not (child is Label or child is Control):
			child.queue_free()
	
	await get_tree().process_frame
	
	_add_section_header("Unlock Instruments")
	_create_unlock_buttons()
	
	_add_section_header("Upgrade Instruments")
	for instrument in GameManager.unlocked_instruments:
		_create_instrument_upgrades(instrument)
	
	_add_section_header("Global Upgrades")
	_create_global_upgrades()

func _add_section_header(title: String):
	if not upgrades_container:
		return
	
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
	for _instrument_type in GlobalBalanceManager.initial_instruments:
		if not GameManager.unlocked_instruments.has(_instrument_type):
			var settings = GlobalBalanceManager.initial_instruments[_instrument_type]
			var button = upgrade_button_scene.instantiate()
			
			button.setup(
				_instrument_type + "_unlock",
				{
					"name": "Unlock " + settings["display_name"],
					"cost_per_level": [settings["initial_cost"]],
					"bonus_per_level": [1]
				},
				0
			)
			
			button.pressed.connect(_on_upgrade_pressed.bind(_instrument_type + "_unlock"))
			upgrades_container.add_child(button)

func _create_instrument_upgrades(instrument: String):
	var current_level = GameManager.get_instrument_level(instrument)
	var max_level = GlobalBalanceManager.get_max_instrument_level(instrument)
	
	if current_level < max_level:
		var level_settings = GlobalBalanceManager.upgrades_settings.get(instrument + "_unlock", {})
		var button = upgrade_button_scene.instantiate()
		
		button.setup(
			instrument + "_unlock",
			level_settings,
			current_level
		)
		
		button.pressed.connect(_on_upgrade_pressed.bind(instrument + "_unlock"))
		upgrades_container.add_child(button)
	
	var combo_level = GameManager.upgrade_levels.get(instrument + "_combo", 0)
	var max_combo_level = 5
	
	if combo_level < max_combo_level:
		var combo_settings = {
			"name": instrument.capitalize() + " Combo",
			"cost_per_level": [500, 1000, 2000, 4000, 8000],
			"bonus_per_level": [2, 4, 6, 8, 10],
			"unlocks_pattern_line": [1, 2, 3, 4, 5]
		}
		
		var button = upgrade_button_scene.instantiate()
		button.setup(
			instrument + "_combo",
			combo_settings,
			combo_level
		)
		
		button.pressed.connect(_on_upgrade_pressed.bind(instrument + "_combo"))
		upgrades_container.add_child(button)

func _create_global_upgrades():
	for upgrade_id in GlobalBalanceManager.global_upgrades:
		var current_level = GameManager.upgrade_levels.get(upgrade_id, 0)
		var settings = GlobalBalanceManager.global_upgrades[upgrade_id]
		
		if current_level < settings["cost_per_level"].size():
			var button = upgrade_button_scene.instantiate()
			button.setup(upgrade_id, settings, current_level)
			button.pressed.connect(_on_upgrade_pressed.bind(upgrade_id))
			upgrades_container.add_child(button)

func _on_upgrade_pressed(upgrade_id: String):
	var settings: Dictionary
	var current_level: int
	
	if upgrade_id in GlobalBalanceManager.global_upgrades:
		settings = GlobalBalanceManager.global_upgrades[upgrade_id]
	elif upgrade_id.ends_with("_combo"):
		settings = {
			"cost_per_level": [500, 1000, 2000, 4000, 8000],
			"bonus_per_level": [2, 4, 6, 8, 10]
		}
	else:
		settings = GlobalBalanceManager.upgrades_settings.get(upgrade_id, {})
	
	current_level = GameManager.upgrade_levels.get(upgrade_id, 0)
	
	if current_level >= settings["cost_per_level"].size():
		error_sound.play()
		return
	
	var cost = settings["cost_per_level"][current_level]
	
	if GameManager.upgrade(upgrade_id, cost):
		purchase_sound.play()
	else:
		error_sound.play()
		_animate_error_feedback()

func _animate_error_feedback():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 0.5, 0.5), 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.4)
