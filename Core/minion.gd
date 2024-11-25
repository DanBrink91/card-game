class_name Minion
extends Node2D

signal minion_take_damage(amount: int, source: Player)
signal minion_death

@onready var health_label = $Control/MarginContainer/VBoxContainer/HealthContainer/HealthLabel
@onready var texture_rect = $Control/MarginContainer/VBoxContainer/SpriteContainer/TextureRect
@onready var description_label = $Control/MarginContainer/VBoxContainer/DescriptionContainer/Label

var health: int = 10
# minion data
var base: BaseMinion

func set_minion(minion: BaseMinion) -> void:
	await ready
	base = minion.duplicate()
	texture_rect.texture = base.texture
	health = base.health
	update_ui()
	
func update_ui() -> void:
	health_label.text = str(base.health)
	description_label = base.get_description()

# Let the base decide how to take the damage so it can do things!
func take_damage(amount: int, source: Player) -> void:
	var new_health: int = base.take_damage(amount, source)
	var damage_done: int = health - new_health
	health = new_health
	
	Util.spawn_floating_text("-" + str(damage_done), global_position, Vector2(0, -45))
	minion_take_damage.emit(damage_done, source)
	if new_health <= 0:
		minion_death.emit()
	update_ui()

# Minion Performs its action
func take_turn(game: Game) -> void:
	await base.take_turn(game)
