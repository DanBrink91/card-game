extends BaseCard
class_name StrikeCard

@export var damage: int = 5  # Default value

func get_description() -> String:
	return description % damage
	
func play(player: Player, target) -> void:
	print("Strike Card Played")
	if target and target.has_method("take_damage"):
		var calculated_damage: int = damage
		calculated_damage = player.deal_damage(target, calculated_damage)
		target.take_damage(calculated_damage, player)
