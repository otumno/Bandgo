extends Node

@onready var background: TextureRect = $Background  # Укажите путь к вашему фону

func _ready():
	GameManager.upgrades_updated.connect(_on_upgrades_updated)

func _on_upgrades_updated():
	if GameManager.upgrade_levels.has("global_multiplier"):
		var level = GameManager.upgrade_levels["global_multiplier"]
		# Меняем фон (пример)
		if GlobalBalanceManager.global_upgrades["global_multiplier"].get("affects_background", false):
			background.modulate = Color(1, 1 - level * 0.1, 1 - level * 0.1)  # Краснеет с уровнем
