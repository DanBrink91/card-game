class_name RallyStrikeCard

extends BaseCard

@export var damage: int = 5  # Default value
@export var cards_to_draw: int = 1

func get_description() -> String:
	return description % damage
	
func play(player: Player, target) -> void:
	print("Rally Strike Card Played")
	if target and target.has_method("take_damage"):
		var calculated_damage: int = damage
		calculated_damage = player.deal_damage(target, calculated_damage)
		target.take_damage(calculated_damage, player)
	
	for playerIter in player.game.players:
		var drawnCards = await playerIter.draw(cards_to_draw)
		for card in drawnCards:
			playerIter.add_to_hand(card)
