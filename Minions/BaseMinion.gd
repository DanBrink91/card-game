class_name BaseMinion
extends Resource

@export var health: int
@export var base_health: int = 0
@export_multiline var description: String
@export var texture: Texture2D

func set_player_count(count: int) -> void:
	health = base_health + health * count

func take_damage(amount: int, source: Player) -> int:
	health -= amount
	return health

func take_turn(game: Game) -> void:
	pass
	
func get_description() -> String:
	return description
