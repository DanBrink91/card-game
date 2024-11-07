# CardNode.gd
extends Area2D
class_name CardNode

signal card_clicked(card_node:CardNode)

var card_data: BaseCard = null  # Reference to the base card resource

# References to label nodes for displaying card information
@onready var name_label: RichTextLabel = $Name
@onready var description_label: RichTextLabel = $Description
@onready var cost_label: RichTextLabel = $EnergyCost
@onready var price_label: RichTextLabel = $Price
@onready var sprite: Sprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D  


func _ready():
	input_event.connect(_on_input_event)
	if card_data:
		card_data.stats_updated.connect(self.refresh_display)
	# Initialize the display when the node is ready
	refresh_display()

func set_card_data(new_card_data: BaseCard):
	card_data = new_card_data
	await self.ready # Make sure the children nodes are ready before we update them
	refresh_display()

func _on_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	# Emit the card_clicked signal only if it was a left-click
	if event is InputEventMouseButton and event.pressed:
		card_clicked.emit(self)

func refresh_display():
	# Update display based on card_data values
	if card_data:
		name_label.text = card_data.name
		description_label.text = card_data.description
		cost_label.text = str(card_data.cost)
		price_label.text = str(card_data.price)
		sprite.texture = card_data.texture

func play_card(player, target):
	if card_data:
		# Assume card_data has a play function you can pass the target to
		card_data.play(player, target)
