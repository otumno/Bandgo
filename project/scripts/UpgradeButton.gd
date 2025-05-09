extends Button

@onready var name_label: Label = $HBoxContainer/VBoxContainer/NameLabel
@onready var level_label: Label = $HBoxContainer/VBoxContainer/LevelLabel
@onready var cost_label: Label = $HBoxContainer/VBoxContainer/CostLabel
@onready var lock_icon: ColorRect = $HBoxContainer/LockOverlay

var upgrade_id: String = ""
var current_level: int = 0
var gm: Node

func _ready():
	# Ждем полной инициализации
	await get_tree().process_frame
	gm = get_node("/root/GameManager") if has_node("/root/GameManager") else null
	
	# Принудительно показываем элементы
	if name_label: 
		name_label.show()
		name_label.text = "Loading..."
	if level_label: level_label.show()
	if cost_label: cost_label.show()
	if lock_icon: lock_icon.hide()

func setup(id: String, settings: Dictionary, level: int):
	upgrade_id = id
	current_level = level
	
	# Устанавливаем текст
	if name_label:
		name_label.text = settings.get("name", "NO NAME")
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	if level_label:
		level_label.text = "Lv.%d" % (level + 1)
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var costs = settings.get("cost_per_level", [])
	if cost_label:
		cost_label.text = "%d pts" % costs[level] if level < costs.size() else "MAX"
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Настройка видимости
	self.text = ""
	self.custom_minimum_size = Vector2(250, 80)
	
	# Обновляем доступность
	if gm:
		_update_affordability(costs[level] if level < costs.size() else 0)

func _update_affordability(cost: int):
	if not gm:
		return
	
	var can_afford = gm.score >= cost
	modulate = Color.WHITE if can_afford else Color(0.6, 0.6, 0.6, 0.8)
	if lock_icon:
		lock_icon.visible = not can_afford
	if cost_label:
		cost_label.modulate = Color.GREEN if can_afford else Color.RED

func _on_pressed():
	if not gm:
		return
	
	var settings = GlobalBalanceManager.upgrades_settings.get(upgrade_id, {})
	var costs = settings.get("cost_per_level", [])
	
	if current_level >= costs.size():
		return
	
	if gm.upgrade(upgrade_id, costs[current_level]):
		queue_free()
