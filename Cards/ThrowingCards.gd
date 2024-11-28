class_name ThrowingCards
extends BaseCard
@export var damage: int = 2

func get_description() -> String:
	return description % damage


func play(player: Player, target) -> void:
	var cards_in_hand: int = player.hand.size() - 1 # don't count this card
	player.discard_hand()
	if target and target.has_method("take_damage"):
		var calculated_damage: int = damage * cards_in_hand
		calculated_damage = player.deal_damage(target, calculated_damage)
		target.take_damage(calculated_damage, player)
