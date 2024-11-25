class_name heal_enemies
extends BaseMinion

@export var heal: int = 2

func take_turn(game: Game) -> void:
	var target: Enemy = game.enemies[0]
	# TODO: We need a health method on players + enemies
	target.health += heal
	target.update_ui()
	
func get_description() -> String:
	return description % heal
