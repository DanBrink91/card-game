class_name Enemy
extends Node2D

signal turn_ended
signal enemy_death


@export var starting_health: int = 40
@export var starting_damage: int = 1

@onready var health_label:  RichTextLabel = $HealthLabel
@onready var game: Game = get_parent()

var health:int
var damage:int

var turns_taken := 0

var player_name := "Fire Demon"
var is_host: bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health = starting_health
	damage = starting_damage
	update_ui()
	
func take_damage(amount:int) -> void:
	health -= amount
	if health <= 0:
		print("Enemy died!")
		enemy_death.emit()
	update_ui()


func update_ui() -> void:
	health_label.text = str(health)

func start_turn() -> void:
	var target := await pick_target()
	if target == null:
		print("Players lose")
		# There are no alive targets the bad guy as won...
	# TODO: Damage animation?
	target.take_damage(damage)
	await get_tree().create_timer(2).timeout
	end_turn()

func end_turn() -> void:
	turns_taken += 1
	turn_ended.emit()

func pick_target() -> Player:
	if is_host:
		var alive_players := get_tree().get_nodes_in_group("allies").filter(func(player): return player.life > 0)
		var target = alive_players.pick_random()
		var target_index = get_tree().get_nodes_in_group("allies").find(target)
		GlobalSteam.send_p2p_packet(0, {"type": GlobalSteam.GAME_PACKET_TYPE.GAME_ENEMY_DECIDE, "target_index": target_index})
		return target
	else: # Wait for game packet to decide!
		var players = get_tree().get_nodes_in_group("allies")
		var target_index = await game.remote_enemy_decide
		players.pick_random() # Garbage, just keep the random in sync
		return players[target_index]
