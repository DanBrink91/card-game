class_name PainfulCoin
extends BaseCard

@export var value: int = 1
@export var damage:int = 2

func get_description() -> String:
	return description % [value, damage]

func on_buy(player: Player) -> void:
	player.take_damage(damage)

func play(player: Player, target) -> void:
	print("Painful Card Played")
	if player:
		player.gain_money(value)
