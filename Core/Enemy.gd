class_name Enemy
extends Node2D

signal turn_ended
signal enemy_death


@export var starting_health: int = 40
@export var starting_damage: int = 1

@onready var health_label:  RichTextLabel = $HealthLabel

var health:int
var damage:int

var turns_taken := 0

var player_name := "Fire Demon"

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
	var target := pick_target()
	# TODO: Damage animation?
	target.take_damage(damage)
	await get_tree().create_timer(2).timeout
	end_turn()

func end_turn() -> void:
	turns_taken += 1
	turn_ended.emit()

func pick_target() -> Player:
	var alive_players := get_tree().get_nodes_in_group("allies").filter(func(player): return player.life > 0)
	return alive_players.pick_random()
