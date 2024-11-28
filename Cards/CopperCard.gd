extends BaseCard
class_name CopperCard

@export var value: int = 1

func get_description() -> String:
	return description % value


func play(player: Player, target) -> void:
	print("Copper Card Played")
	if player:
		player.gain_money(value)
