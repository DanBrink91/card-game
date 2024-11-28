class_name PillageEffect
extends BaseBuff

func on_damage_dealing(target: Node2D, amount: int, simulate: bool = false) -> int:
	if owner and owner is Player:
		owner.gain_money(1)
	stacks -= 1
	return amount
