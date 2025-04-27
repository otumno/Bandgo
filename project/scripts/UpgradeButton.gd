extends Button

func setup(upgrade_id: String, settings: Dictionary, current_level: int):
	var cost = settings["cost_per_level"][current_level]
	text = "%s (Level %d) - Cost: %d" % [settings["name"], current_level + 1, cost]
