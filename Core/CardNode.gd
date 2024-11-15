# CardNode.gd
extends Control
class_name CardNode

signal card_clicked(card_node:CardNode)
signal card_hovered(card_node:CardNode)
signal card_double_clicked(card_node:CardNode)

var card_data: BaseCard = null  # Reference to the base card resource

# References to label nodes for displaying card information
@onready var name_label: RichTextLabel = $NameContainer/Name
@onready var description_label: RichTextLabel = $DescriptionContainer/Description
@onready var cost_label: RichTextLabel = $VBoxContainer/EnergyContainer/EnergyCost
@onready var price_label: RichTextLabel = $VBoxContainer/PriceContainer/Price
@onready var sprite: Sprite2D = $Sprite
@onready var area: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D


var old_position: Vector2
var old_scale: Vector2

var in_preview_mode: bool = false

func _ready():
	#area.input_event.connect()
	gui_input.connect(_on_gui_input_event)
	if card_data:
		card_data.stats_updated.connect(self.refresh_display)
	# Initialize the display when the node is ready
	refresh_display()
	old_position = global_position
	old_scale = scale

func set_card_data(new_card_data: BaseCard):
	card_data = new_card_data
	await self.ready # Make sure the children nodes are ready before we update them
	refresh_display()


# TODO Change old_position or disable this for certain modes like card modal
func _on_gui_input_event(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.double_click:
		if in_preview_mode:
			in_preview_mode = false
			global_position = old_position
			scale = old_scale
		card_double_clicked.emit(self)
	elif event is InputEventMouseButton and event.pressed and event.button_index == 1:
		if in_preview_mode:
			in_preview_mode = false
			global_position = old_position
			scale = old_scale
		card_clicked.emit(self)
	elif event is InputEventMouseButton and event.pressed and event.button_index == 2:
		if not in_preview_mode:
			old_position = global_position
		# Move to center screen and Scale it way up
		global_position = -size - Vector2(0, 300)
		scale = Vector2(5, 5)
		in_preview_mode = true
	elif event is InputEventMouseButton  and event.button_index == 2:
		if in_preview_mode:
			global_position = old_position
			scale = old_scale
			in_preview_mode = false

func refresh_display():
	# Update display based on card_data values
	if card_data:
		name_label.text = card_data.name
		description_label.text = card_data.get_description()
		cost_label.text = str(card_data.cost)
		price_label.text = str(card_data.price)
		sprite.texture = card_data.texture

func play_card(player, target):
	if card_data:
		# Assume card_data has a play function you can pass the target to
		card_data.play(player, target)
