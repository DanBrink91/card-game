class_name HiveMind
extends BaseCard

@export var damage: int = 3

func get_description() -> String:
	return description % damage

func play(player: Player, target: Node2D) -> void:
	print("Hivemind Card Played")
	var foundCards: int = 0
	var game: Game = player.game
	for other: Player in game.players:
		if other != player:
			var other_hiveminds: Array[BaseCard] = other.hand.filter(func(card): return card is HiveMind)
			foundCards += other_hiveminds.size()
			for card in other_hiveminds:
				other.discard_card(card)
	var calculated_damage: int = damage * foundCards
	calculated_damage = player.deal_damage(target, calculated_damage)
	target.take_damage(calculated_damage, player)
