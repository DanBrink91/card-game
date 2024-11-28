class_name Stats
extends Node

var rounds_played: int = 0
var player_data: Dictionary = {}

func add_player_entry(player: Player) -> void:
	player_data[player.player_name] = {
		"name": player.player_name,
		"damage_done": 0,
		"damage_taken": 0,
		"max_damage_done": 0,
		"max_damage_taken": 0,
		"mana_spent": 0,
		"mana_unspent": 0,
		"money_spent": 0,
		"money_unspent": 0,
		"cards_bought": 0,
		"cards_played": 0,
		"turns_taken": 0,
		"times_damage_taken": 0 # How many times the player was hit
	}
	player.turn_ended.connect(player_turn_ended.bind(player))
	player.card_bought.connect(player_card_bought.bind(player))
	player.damage_taken.connect(player_damage_taken.bind(player))
	player.card_played.connect(player_card_played.bind(player))

func add_enemy_entry(enemy: Enemy) -> void:
	enemy.enemy_take_damage.connect(player_deal_damage)

func player_turn_ended(player: Player) -> void:
	player_data[player.player_name]["mana_unspent"] += player.mana
	player_data[player.player_name]["money_unspent"] += player.money
	player_data[player.player_name]["turns_taken"] += 1

func player_card_bought(card: BaseCard, player: Player) -> void:
	print("player card bought")
	player_data[player.player_name]["money_spent"] += card.price
	player_data[player.player_name]["cards_bought"] += 1
	# TODO Save purchase history per player here

func player_damage_taken(amount: int, player: Player) -> void:
	if player:
		player_data[player.player_name]["max_damage_taken"] = max(player_data[player.player_name]["max_damage_taken"], amount)
		player_data[player.player_name]["damage_taken"] += amount
		player_data[player.player_name]["times_damage_taken"] += 1
	


func player_card_played(card: BaseCard, player: Player) -> void:
	player_data[player.player_name]["cards_played"] += 1
	player_data[player.player_name]["mana_spent"] += card.cost
	# TODO Save play history here per player

func player_deal_damage(amount: int, player: Player) -> void:
	if player:
		player_data[player.player_name]["damage_done"] += amount
		player_data[player.player_name]["max_damage_done"] = max(player_data[player.player_name]["max_damage_done"], amount)
