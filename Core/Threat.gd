class_name Threat
extends Control

signal cost_paid(player: Player, threat: BaseThreat)
signal cost_paidoff(threat: BaseThreat)
signal remote_cost_paid
signal threat_activated

@onready var description_label: RichTextLabel = $MarginContainer/VBoxContainer/MarginContainer/DescriptionLabel
@onready var turns_label: RichTextLabel = $MarginContainer/VBoxContainer/MarginContainer3/TurnsLabel
@onready var game: Game = get_parent().get_parent().get_parent() # change this..
# /root/Battle Node/Game
var turns_left: int = 3
var progress: int = 0
var cost: int = 3

var threat: BaseThreat

func _ready() -> void:
	gui_input.connect(_handle_input)

func update_ui() -> void:
	await ready
	if threat:
		description_label.text = threat.get_description()
		turns_label.text = "Turns Left: %d" % turns_left

func set_threat(thrt: BaseThreat) -> void:
	threat = thrt.duplicate()
	turns_left = threat.turn_limit
	update_ui()

func progress_threat() -> void:
	turns_left -= 1
	if turns_left <= 0:
		await threat.complete(game)
		# TODO: Didn't pay off animation
		self.queue_free()
	else:
		update_ui()

func _handle_input(event: InputEvent) -> void:
	# Handle left click
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		var player = game.get_current_entity()
		
		if player is Player:
			if not player.is_remote: # Local
				cost_paid.emit(player as Player, threat)
				await threat.pay(player)
				if threat.is_paid():
					cost_paidoff.emit(threat)
		else: # Its not the clicker's turn
			pass
