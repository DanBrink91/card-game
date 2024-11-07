class_name CardModal
extends Panel

signal modal_finished(finished: bool, cards: Array[BaseCard])

@onready var label = $Label
@onready var container = $HBoxContainer
@onready var button = $Button

var cardOptions: Array[BaseCard]
var selected: Array[bool]
var cardsRequired: int = 0
var cardsSelected: int = 0

@export var card_scene: PackedScene
@export var inactiveCardOpacity: float = 0.5
var active_player: Player = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button.pressed.connect(_on_button_press)

func show_modal(text:String, cards: Array[BaseCard], numCardsRequired: int):
	# Reset everything
	cardOptions.clear()
	selected.clear()
	for n in container.get_children():
		container.remove(n)
		n.queue_free()
	# ====
	label.text = text
	cardOptions = cards
	cardsRequired = numCardsRequired
	
	for card in cardOptions:
		var card_node = card_scene.instantiate() as CardNode
		card_node.set_card_data(card)
		card_node.modulate.a = inactiveCardOpacity
		# Remote players cannot click modals not for them
		if active_player and not active_player.is_remote:
			card_node.card_clicked.connect(_on_card_click)
		card_node.scale = Vector2(0.02, 0.09)
		# change these visually somehow to mark them as not selected
		var control = MarginContainer.new()
		control.add_theme_constant_override("margin_left", 1)
		control.add_theme_constant_override("margin_right", 1)

		#control.LayoutPreset = PRESET_FULL_RECT
		control.add_child(card_node)
		container.add_child(control)
		selected.append(false)
	
	return await modal_finished
		
# Mark card as selected or unselected, update
func _on_card_click(card: CardNode) -> void:
	var card_index = cardOptions.find(card.card_data)
	var is_selected = selected[card_index]
	if is_selected:
		selected[card_index] = false
		cardsSelected -= 1
		card.modulate.a = inactiveCardOpacity
	else:
		if cardsSelected >= cardsRequired: # We don't need to select anymore cards...
			return
		else:
			selected[card_index] = true
			cardsSelected += 1
			card.modulate.a = 100
	update_ui()
			
	
func update_ui() -> void:
	button.disabled = cardsSelected < cardsRequired and not active_player.is_remote

func _on_button_press() -> void:
	if not active_player.is_remote: return
	# Gather selected
	var cards: Array[BaseCard] = []
	for index in range(cardOptions.size()):
		if selected[index]:
			cards.append(cardOptions[index])
	modal_finished.emit(true, cards)
