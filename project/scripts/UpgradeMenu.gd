extends Control

@onready var upgrades_container = $ScrollContainer/VBoxContainer
@onready var upgrade_button_scene = preload("res://project/scenes/UpgradeButton.tscn")

func _ready():
	update_upgrades_list()

func update_upgrades_list():
	# Очищаем старые кнопки
	for child in upgrades_container.get_children():
		child.queue_free()
	
	var gm = get_node("/root/GameManager")
	var balance = get_node("/root/GlobalBalanceManager")
	
	# Создаем кнопки для каждого апгрейда
	for upgrade_id in balance.upgrades_settings:
		var settings = balance.upgrades_settings[upgrade_id]
		var current_level = gm.upgrade_levels.get(upgrade_id, 0)
		
		# Если апгрейд не достиг максимального уровня
		if current_level < settings["cost_per_level"].size():
			var button = upgrade_button_scene.instantiate()
			button.setup(upgrade_id, settings, current_level)
			button.pressed.connect(_on_upgrade_pressed.bind(upgrade_id))
			upgrades_container.add_child(button)

func _on_upgrade_pressed(upgrade_id: String):
	var gm = get_node("/root/GameManager")
	var balance = get_node("/root/GlobalBalanceManager")
	var settings = balance.upgrades_settings[upgrade_id]
	var current_level = gm.upgrade_levels.get(upgrade_id, 0)
	var cost = settings["cost_per_level"][current_level]
	
	if gm.upgrade(upgrade_id, cost):
		update_upgrades_list()
