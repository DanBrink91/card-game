class_name deal_health
extends BaseMinion

func take_turn(game: Game) -> void:
	# find random Alive Player
	var alive_players = game.players.filter(func (player: Player): return player.life > 0)
	var target: Player = alive_players.pick_random()
	target.take_damage(health)
	
func get_description() -> String:
	return description

func take_damage(amount: int, source: Player) -> int:
	health -= 1
	return health
