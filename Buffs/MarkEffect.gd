class_name MarkEffect
extends BaseBuff

@export var bonus_damage :int = 1

# modify damage taken
func on_damage_taking(attacker: Node2D, amount: int, simulate: bool = false) -> int:
	stacks -= 1
	return amount + bonus_damage
