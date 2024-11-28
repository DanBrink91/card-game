class_name BaseBuff
extends Resource

@export var name: String
@export_multiline var description: String
@export var icon: Texture2D

var stacks: int = 0

var owner: Node2D

func expired() -> bool:
	return stacks <= 0

# Interaction points
func on_start_turn() -> void:
	pass

func on_end_turn() -> void:
	pass

func on_card_played(card: BaseCard) -> void:
	pass

# modify damage dealt
func on_damage_dealing(target: Node2D, amount: int, simulate: bool = false) -> int:
	return amount

# modify damage taken
func on_damage_taking(attacker: Node2D, amount: int, simulate: bool = false) -> int:
	return amount

# Modify Price or what?
func on_card_buying(card: BaseCard) -> void:
	pass

# Modify money gains
func on_money_gain(amount: int) -> int:
	return amount
