extends BaseCard
class_name StrikeCard

@export var damage: int = 5  # Default value

func _init() -> void:
	pass

func get_description() -> String:
	return description % damage
	
func play(player, target) -> void:
	print("Strike Card Played")
	if target and target.has_method("take_damage"):
		target.take_damage(damage, player)
