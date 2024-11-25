class_name hit_lowest
extends BaseMinion

@export var damage: int = 2

func take_turn(game: Game) -> void:
	# find lowest HP Alive Player
	var alive_players = game.players.filter(func (player: Player): return player.life > 0)
	alive_players.sort_custom(func(a: Player, b: Player): return a.life < b.life)
	
	var target: Player = alive_players.pop_front()
	target.take_damage(damage)
	
func get_description() -> String:
	return description % damage
