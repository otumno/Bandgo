extends Button

@onready var name_label: Label = $HBoxContainer/VBoxContainer/NameLabel
@onready var level_label: Label = $HBoxContainer/VBoxContainer/LevelLabel
@onready var cost_label: Label = $HBoxContainer/VBoxContainer/CostLabel
@onready var lock_icon: ColorRect = $HBoxContainer/LockOverlay

var upgrade_id: String = ""
var current_level: int = 0

func _ready():
	await get_tree().process_frame  # Ждем завершения загрузки сцены
	if not _validate_nodes():
		queue_free()
		return
	
	# Инициализация текста по умолчанию для диагностики
	if name_label: name_label.text = "Loading..."
	if level_label: level_label.text = "Ур. 0"
	if cost_label: cost_label.text = "0 очков"
	
	if lock_icon: lock_icon.visible = false
	add_theme_stylebox_override("normal", get_theme_stylebox("panel"))
	add_theme_stylebox_override("hover", get_theme_stylebox("panel_hover"))
	add_theme_stylebox_override("pressed", get_theme_stylebox("panel_pressed"))
	
	# Подключаем сигнал обновления очков
	if has_node("/root/GameManager"):
		GameManager.score_updated.connect(_on_score_updated)
	print("UpgradeButton _ready: name_label=", name_label, " level_label=", level_label, " cost_label=", cost_label, " lock_icon=", lock_icon)

func setup(id: String, settings: Dictionary, level: int):
	upgrade_id = id
	current_level = level
	
	if not _validate_settings(settings):
		return
	
	# Установка текста с проверкой на null
	if name_label:
		var display_name = settings.get("name", "Unknown Upgrade")
		name_label.text = display_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		print("Setting name_label to: ", display_name, " for upgrade_id: ", id)
	
	if level_label:
		var max_level = settings["cost_per_level"].size()
		level_label.text = "Ур. %d/%d" % [level + 1, max_level]
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		print("Setting level_label to: Ур. %d/%d for upgrade_id: ", id, level + 1, max_level)
	
	if cost_label:
		var costs = settings["cost_per_level"]
		if level < costs.size():
			cost_label.text = "%d очков" % costs[level]
			cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_update_affordability(costs[level])
			print("Setting cost_label to: %d очков for upgrade_id: ", id, costs[level])
		else:
			cost_label.text = "MAX"
			cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			if lock_icon:
				lock_icon.visible = true
				modulate = Color(0.7, 0.7, 0.7)
			print("Setting cost_label to: MAX for upgrade_id: ", id)
	
	# Отладочный вывод
	print("UpgradeButton setup: id=%s, name=%s, level=%d, cost=%s" % [id, name_label.text if name_label else "N/A", level + 1, cost_label.text if cost_label else "N/A"])

func _validate_nodes() -> bool:
	var valid = true
	
	if not name_label:
		push_error("NameLabel not found!")
		valid = false
	if not level_label:
		push_error("LevelLabel not found!")
		valid = false
	if not cost_label:
		push_error("CostLabel not found!")
		valid = false
	if not lock_icon:
		push_error("LockOverlay not found!")
		valid = false
	
	return valid

func _validate_settings(settings: Dictionary) -> bool:
	if settings.is_empty():
		push_error("Empty upgrade settings!")
		return false
	if not settings.has("cost_per_level"):
		push_error("Missing cost_per_level in settings!")
		return false
	if not settings.has("name"):
		push_warning("Missing name in settings for upgrade_id: ", upgrade_id)
	return true

func _on_score_updated(_new_score: int):
	var settings = GlobalBalanceManager.upgrades_settings.get(upgrade_id, {})
	var costs = settings.get("cost_per_level", [])
	if current_level < costs.size() and cost_label:
		_update_affordability(costs[current_level])

func _update_affordability(cost: int):
	if not has_node("/root/GameManager") or not cost_label:
		return
	
	var can_afford = GameManager.score >= cost
	print("Upgrade: ", upgrade_id, " | Cost: ", cost, " | Score: ", GameManager.score, " | Can afford: ", can_afford)
	
	modulate = Color.WHITE if can_afford else Color(0.6, 0.6, 0.6, 0.8)
	if lock_icon:
		lock_icon.visible = not can_afford
	cost_label.modulate = Color.GREEN if can_afford else Color.RED

func _on_pressed():
	if not has_node("/root/GameManager"):
		return
	
	var settings = GlobalBalanceManager.upgrades_settings.get(upgrade_id, {})
	var costs = settings.get("cost_per_level", [])
	
	if current_level >= costs.size():
		return
	
	if GameManager.upgrade(upgrade_id, costs[current_level]):
		queue_free()
