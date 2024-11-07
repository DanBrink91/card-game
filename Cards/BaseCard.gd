# BaseCard.gd
extends Resource
class_name BaseCard

signal stats_updated # Signal for when any stat is updated
enum TargetType {SINGLE_ENEMY, SINGLE_ALLY, ALL_ENEMIES, ALL_ALLIES, ALL, SELF, RANDOM_ENEMY, RANDOM_ALLY, RANDOM_ALL}

@export var name: String
@export var description: String
@export var cost: int = 0
@export var price: int = 0
@export var texture: Texture
@export var target_type:TargetType

var id :int = -1
var modifiers = []

# Example function to update modifiers and emit signal
func add_modifier(modifier):
	modifiers.append(modifier)
	# Recalculate stats based on modifiers if needed
	calculate_modified_stats()
	emit_signal("stats_updated")

func calculate_modified_stats():
	# Calculate and apply modifiers to stats (e.g., cost adjustments)
	pass

func can_play(player) -> bool:
	return player.mana >= cost

# Abstract method for subclasses to implement
func play(_player, _target) -> void:
	push_error("play() method not implemented in BaseCard subclass.")
