class_name CardModal
extends Panel

signal modal_finished(finished: bool, cards: Array[BaseCard])

@onready var label = $Label
@onready var container = $ScrollContainer/HBoxContainer
@onready var button = $Button

var cardOptions: Array[BaseCard]
var cardNodes: Array[CardNode] = []
var selected: Array[bool]
var cardsRequired: int = 0
var cardsSelected: int = 0

@export var card_scene: PackedScene
@export var inactiveCardOpacity: float = 0.5

# Set when used
var active_player: Player = null
# not great, when we set game value make sure we connect the signals if they aren't already connected
var game: Game = null :
	set(value):
		game = value
		if not game.remote_modal_confirm.is_connected(_handle_remote_confirm):
			game.remote_modal_confirm.connect(_handle_remote_confirm)
			game.remote_modal_select.connect(_handle_remote_select)
	get:
		return game
		

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button.pressed.connect(_on_button_press)

func show_modal(text:String, cards: Array[BaseCard], numCardsRequired: int):
	# Reset everything
	cardOptions.clear()
	cardNodes.clear()
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
		
		# change these visually somehow to mark them as not selected
		var control = MarginContainer.new()
		control.add_theme_constant_override("margin_left", 1)
		control.add_theme_constant_override("margin_right", 1)
		control.custom_minimum_size = Vector2(120, 175)
		
		#control.LayoutPreset = PRESET_FULL_RECT
		control.add_child(card_node)
		container.add_child(control)
		selected.append(false)
		cardNodes.append(card_node)
	
	return await modal_finished
		
# Mark card as selected or unselected, update
func _on_card_click(card: CardNode) -> void:
	var card_index = cardOptions.find(card.card_data)
	var is_selected = selected[card_index]
	if is_selected:
		selected[card_index] = false
		cardsSelected -= 1
		card.modulate.a = inactiveCardOpacity
		if not active_player.is_remote:
			GlobalSteam.send_p2p_packet(0, {"type": GlobalSteam.GAME_PACKET_TYPE.GAME_MODAL_UPDATE, "card_index": card_index})
	else:
		if cardsSelected >= cardsRequired: # We don't need to select anymore cards...
			return
		else:
			selected[card_index] = true
			cardsSelected += 1
			card.modulate.a = 100
			if not active_player.is_remote:
				GlobalSteam.send_p2p_packet(0, {"type": GlobalSteam.GAME_PACKET_TYPE.GAME_MODAL_UPDATE, "card_index": card_index})

	update_ui()
			
	
func update_ui() -> void:
	button.disabled = cardsSelected < cardsRequired and not active_player.is_remote

func _on_button_press() -> void:
	if active_player.is_remote: return
	GlobalSteam.send_p2p_packet(0, {"type": GlobalSteam.GAME_PACKET_TYPE.GAME_MODAL_UPDATE})
	
	# Gather selected
	var cards: Array[BaseCard] = []
	for index in range(cardOptions.size()):
		if selected[index]:
			cards.append(cardOptions[index])
	modal_finished.emit(true, cards)

func _handle_remote_select(card_index: int) -> void:
	if card_index < cardNodes.size():
		var card: CardNode = cardNodes[card_index]
		_on_card_click(card)
	else:
		print("out of bounds card modal")

func _handle_remote_confirm() -> void:
	var cards: Array[BaseCard] = []
	for index in range(cardOptions.size()):
		if selected[index]:
			cards.append(cardOptions[index])
	modal_finished.emit(true, cards)
