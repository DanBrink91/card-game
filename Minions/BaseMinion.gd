class_name BaseMinion
extends Resource

@export var health: int
@export_multiline var description: String
@export var texture: Texture2D

func take_damage(amount: int, source: Player) -> int:
	health -= amount
	return health

func take_turn(game: Game) -> void:
	pass
	
func get_description() -> String:
	return description
