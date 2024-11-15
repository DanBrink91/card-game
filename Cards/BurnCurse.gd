class_name BurnCurse
extends BaseCard
@export var damage: int = 1

func get_description() -> String:
	return description % damage

func play(player: Player, target) -> void:
	print("Burn Curse Card")
	if player:
		player.take_damage(damage)
		player.destroy_card(self)
