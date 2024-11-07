extends Node2D

signal game_start

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game_start.emit()
