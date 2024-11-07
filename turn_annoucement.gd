extends RichTextLabel

@export var fade_out_duration: float = 1.0
@export var enemy_color: Color = Color(1.0, 0.0, 0.0, 1.0)
@export var player_color: Color = Color(0.0, 1.0, 0.0, 1.0)

@onready var game: Game = get_parent_control().get_parent().get_node_or_null("Game")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_parent_control().get_parent().game_start.connect(setup)

func setup() -> void:
	self.visible = false
	game.turn_started.connect(_on_turn_start)

func _on_turn_start(current_player:Node2D) -> void:
	if current_player is Enemy:
		set("theme_override_colors/default_color", enemy_color)
	else:
		set("theme_override_colors/default_color", player_color)

	text = "%s Turn" % current_player.player_name
	self.modulate.a = 100
	self.visible = true
	var t: Tween = self.create_tween()
	await t.tween_property(self, "modulate:a", 0.0, fade_out_duration).finished 
	#await get_tree().create_timer(1.5).timeout
	self.visible = false
