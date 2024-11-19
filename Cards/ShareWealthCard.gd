class_name ShareWealthCard
extends BaseCard

@export var value: int = 3  # Default value
@export var money_to_give: int = 1

func get_description() -> String:
	return description % [value, money_to_give]
	
func play(player: Player, target) -> void:
	print("Iron Card Played")
	player.money += value
	
	for playerIter in player.game.players:
		if playerIter != player:
			player.money += money_to_give
