extends Panel

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var upgrades_container: HBoxContainer = $ScrollContainer/HBoxContainer
@onready var close_button: Button = $CloseButton
@onready var purchase_sound: AudioStreamPlayer = $PurchaseSound
@onready var error_sound: AudioStreamPlayer = $ErrorSound

var upgrade_button_scene = preload("res://project/scenes/UpgradeButton.tscn")

# Настройки размера кнопок
const BUTTON_WIDTH := 300
const BUTTON_HEIGHT := 120
const BUTTON_MARGIN := 15

func _ready():
	# Настройка контейнера
	upgrades_container.custom_minimum_size.y = BUTTON_HEIGHT + 20
	upgrades_container.add_theme_constant_override("separation", BUTTON_MARGIN)
	
	close_button.pressed.connect(hide)
	GameManager.upgrades_updated.connect(update_upgrades_list)
	update_upgrades_list()

func update_upgrades_list():
	# Очистка старых кнопок
	for child in upgrades_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame  # Ждем завершения очистки
	
	# Отладочный вывод данных
	print("Available upgrades: ", GlobalBalanceManager.upgrades_settings)
	
	# Создаем новые кнопки
	for upgrade_id in GlobalBalanceManager.upgrades_settings:
		var settings = GlobalBalanceManager.upgrades_settings[upgrade_id]
		var current_level = GameManager.upgrade_levels.get(upgrade_id, 0)
		print("Processing upgrade_id: ", upgrade_id, " | settings: ", settings, " | current_level: ", current_level)
		
		if current_level < settings["cost_per_level"].size():
			var button = upgrade_button_scene.instantiate()
			
			# Настройка размера и положения
			button.custom_minimum_size = Vector2(BUTTON_WIDTH, BUTTON_HEIGHT)
			button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			
			upgrades_container.add_child(button)
			
			# Небольшая задержка для инициализации
			await get_tree().process_frame
			
			# Проверяем наличие метода setup
			if button.has_method("setup"):
				button.setup(upgrade_id, settings, current_level)
				button.pressed.connect(_on_upgrade_pressed.bind(upgrade_id))
				print("Setup called for upgrade_id: ", upgrade_id, " with name: ", settings.get("name", "Unknown"))
			else:
				# Вызываем напрямую как обходной путь
				print("WARNING: has_method('setup') returned false for ", upgrade_id)
				button.setup(upgrade_id, settings, current_level)
				button.pressed.connect(_on_upgrade_pressed.bind(upgrade_id))
				print("Setup called directly for upgrade_id: ", upgrade_id, " with name: ", settings.get("name", "Unknown"))

func _on_upgrade_pressed(upgrade_id: String):
	var settings = GlobalBalanceManager.upgrades_settings.get(upgrade_id, {})
	var current_level = GameManager.upgrade_levels.get(upgrade_id, 0)
	var costs = settings.get("cost_per_level", [])
	
	if current_level >= costs.size():
		return
	
	var cost = costs[current_level]
	
	if GameManager.upgrade(upgrade_id, cost):
		purchase_sound.play()
	else:
		error_sound.play()
		animate_error()

func animate_error():
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
