class_name util
extends Node

# TODO Re-use Labels for spawning floating combat text

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func spawn_floating_text(text: String, pos: Vector2, movement: Vector2, duration: float = 1.0, color: Color = Color.RED):
	var label = Label.new()
	label.text = text
	label.pivot_offset = label.size / 2
	label.global_position = pos
	label.set("theme_override_font_sizes/font_size", 36)
	label.set("theme_override_colors/font_color", color)

	get_tree().root.add_child(label)
	
	var tween = label.create_tween()
	tween.tween_property(label, "global_position", pos + movement , duration).set_ease(tween.EASE_OUT)
	await tween.finished
	label.queue_free()
	
	
