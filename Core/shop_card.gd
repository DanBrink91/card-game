class_name Shop_Card
extends Area2D

signal card_clicked(card_node:Shop_Card)

var card_data: BaseCard = null  # Reference to the base card resource

# References to label nodes for displaying card information
@onready var name_label: RichTextLabel = $Name
@onready var description_label: RichTextLabel = $Description
@onready var cost_label: RichTextLabel = $EnergyCost
@onready var price_label: RichTextLabel = $Price
@onready var stock_label: RichTextLabel = $Stock

@onready var sprite: Sprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D 

var stock := 8 :
	get:
		return stock
	set(value):
		stock = value
		refresh_display()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	input_event.connect(_on_input_event)
	if card_data:
		card_data.stats_updated.connect(self.refresh_display)
	# Initialize the display when the node is ready
	refresh_display()

func set_card_data(new_card_data: BaseCard):
	card_data = new_card_data
	await self.ready # Make sure the children nodes are ready before we update them
	refresh_display()

func refresh_display():
	# Update display based on card_data values
	if card_data:
		name_label.text = card_data.name
		description_label.text = card_data.description
		cost_label.text = str(card_data.cost)
		price_label.text = str(card_data.price)
		stock_label.text = str(stock)
		sprite.texture = card_data.texture

func _on_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	# Emit the card_clicked signal only if it was a left-click
	if event is InputEventMouseButton and event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
		card_clicked.emit(self)
