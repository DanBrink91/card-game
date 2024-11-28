class_name PosionEffect
extends BaseBuff

func on_end_turn() -> void:
	if owner:
		if owner is Player:
			owner.take_damage(stacks)
			stacks -= 1
		else:
			owner.take_damage(stacks, null)
			stacks -= 1
