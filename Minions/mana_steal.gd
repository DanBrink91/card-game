class_name mana_steal
extends BaseMinion

@export var damage: int = 1

func take_turn(game: Game) -> void:
	# All players
	for target: Player in game.players:
		target.mana -= 1
		if target.life > 0:
			target.take_damage(damage)
		else:
			target.update_ui()
	
func get_description() -> String:
	return description % damage
