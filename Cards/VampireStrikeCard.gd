extends BaseCard
class_name VampireStrikeCard

@export var damage: int = 3  # Default value
@export var blood_card: BaseCard

func _init() -> void:
	pass

func get_description() -> String:
	return description % damage
	
func play(player: Player, target) -> void:
	print("Vampire Strike Card Played")
	player.add_card(blood_card, Player.CARD_LOCATIONS.DISCARD)
	if target and target.has_method("take_damage"):
		var calculated_damage: int = damage
		calculated_damage = player.deal_damage(target, calculated_damage)
		target.take_damage(calculated_damage, player)
