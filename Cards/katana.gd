class_name katana
extends BaseCard

@export var damage: int =  1
@export var upgrade: int = 1

func get_description() -> String:
	return description % [damage, upgrade]
	
func play(player, target) -> void:
	print("Katana Card Played")
	if target and target.has_method("take_damage"):
		target.take_damage(damage, player)
		damage += upgrade
