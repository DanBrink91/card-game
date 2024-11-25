class_name BaseThreat
extends Resource

@export_multiline var description: String
@export var turn_limit: int = 3

# Anything that extends this will implement this to fill in variables
func get_description() -> String:
	return description

# Pay a single
func pay(player: Player) -> void:
	pass

func is_paid() -> bool:
	return false

# If its not paid off in time and triggers
func complete(game: Game) -> void:
	pass
