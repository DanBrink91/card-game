class_name HeavyStrikeCard
extends BaseCard


@export var damage: int = 5  # Default value
func get_description() -> String:
	return description % damage

func play(player, target) -> void:
	print("Heavy Strike Card Played")
	if target and target.has_method("take_damage"):
		target.take_damage(damage, player)
