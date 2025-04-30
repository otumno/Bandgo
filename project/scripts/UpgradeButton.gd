extends Button

@onready var name_label: Label = $HBoxContainer/VBoxContainer/NameLabel
@onready var level_label: Label = $HBoxContainer/VBoxContainer/LevelLabel
@onready var cost_label: Label = $HBoxContainer/VBoxContainer/CostLabel
@onready var lock_icon: ColorRect = $HBoxContainer/LockOverlay

var upgrade_id: String = ""
var current_level: int = 0

func _ready():
	if not _validate_nodes():
		queue_free()
		return
	
	lock_icon.visible = false
	add_theme_stylebox_override("normal", get_theme_stylebox("panel"))
	add_theme_stylebox_override("hover", get_theme_stylebox("panel_hover"))
	add_theme_stylebox_override("pressed", get_theme_stylebox("panel_pressed"))
	
	# Подключаем сигнал обновления очков
	if has_node("/root/GameManager"):
		GameManager.score_updated.connect(_on_score_updated)

func setup(id: String, settings: Dictionary, level: int):
	upgrade_id = id
	current_level = level
	
	if not _validate_settings(settings):
		return
	
	name_label.text = settings["name"]
	level_label.text = "Ур. %d/%d" % [level + 1, settings["cost_per_level"].size()]
	
	var costs = settings["cost_per_level"]
	if level < costs.size():
		cost_label.text = "%d очков" % costs[level]
		_update_affordability(costs[level])
	else:
		cost_label.text = "MAX"
		lock_icon.visible = true
		modulate = Color(0.7, 0.7, 0.7)

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
	return true

func _on_score_updated(_new_score: int):
	# Обновляем доступность при изменении очков
	var settings = GlobalBalanceManager.upgrades_settings.get(upgrade_id, {})
	var costs = settings.get("cost_per_level", [])
	if current_level < costs.size():
		_update_affordability(costs[current_level])

func _update_affordability(cost: int):
	if not has_node("/root/GameManager"):
		return
	
	var can_afford = GameManager.score >= cost
	print("Upgrade: ", upgrade_id, " | Cost: ", cost, " | Score: ", GameManager.score, " | Can afford: ", can_afford)  # Отладочный вывод
	
	modulate = Color.WHITE if can_afford else Color(0.6, 0.6, 0.6, 0.8)
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
