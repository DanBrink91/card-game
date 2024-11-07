# Hand.gd
extends Node2D
class_name Hand

signal card_played(card: CardNode, target: Node2D)
signal card_cannot_play(card: CardNode)
signal card_bad_target(card: CardNode)

@export var card_scene: PackedScene  # Reference to the CardNode scene
@export var card_spacing := 75

@onready var player: Player = get_parent() as Player
@onready var drop_area: Area2D = get_node('/root/Battle Node/Card Play Area')

var dragged_card: CardNode = null
var drag_offset: Vector2 = Vector2.ZERO
var start_pos: Vector2 = Vector2.ZERO
var cards: Array[CardNode] = []

var active: bool = false

func _ready():
	pass
	#drop_area.input_event.connect(_on_drop_area_input_event)

func start_turn() -> void:
	active = true

func end_turn() -> void:
	active = false
	
func add_card(card: CardNode) -> void:
	 # WTF???? FIXME: these get passed in as Area2D and we must make them CardNode..
	var card_instance = card_scene.instantiate() as CardNode
	card_instance.card_data = card.card_data
	card = card_instance
	card.position = Vector2(cards.size() * card_spacing, 0)
	card.card_clicked.connect(_on_card_clicked)
	cards.append(card)
	add_child(card)

func remove_card(card: BaseCard) -> void:
	# Find matching CardNode for BaseCard(card_data)
	var filtered_cards := cards.filter(func (card_node:CardNode):  return card_node.card_data.id == card.id)
	print("Filtered Cards Size: %s" % filtered_cards.size())
	var selected_card :CardNode = filtered_cards[0]
	cards.erase(selected_card)
	selected_card.queue_free()
	reorder_cards()

func reorder_cards() -> void:
	var i:int = 0
	for card in cards:
		card.position = Vector2(i * card_spacing, 0)
		i += 1



func _input(event):
	# Check for drag-and-drop logic within the hand
	if event is InputEventMouseMotion and dragged_card:
		update_drag()
	elif event is InputEventMouseButton and not event.pressed and dragged_card:
		end_drag(event.position)

#func _on_drop_area_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	#if event is InputEventMouseButton and event.is_released and dragged_card:
		#emit_signal("card_dropped", dragged_card)
		#dragged_card = null # clean up?

func _on_card_clicked(card: CardNode) -> void:
	# Based on Targetting Type of the Card do different things here...
	if dragged_card == null and card.card_data.can_play(player) and active:
		dragged_card = card
		drag_offset = get_global_mouse_position() - card.global_position
		start_pos = card.global_position
	else:
		card_cannot_play.emit(card)

func update_drag():
	# Move the card as it’s dragged
	dragged_card.global_position =  get_global_mouse_position() - drag_offset

func end_drag(endPosition:Vector2) -> void:
	#enum TargetType {SINGLE_ENEMY, SINGLE_ALLY, ALL_ENEMIES, ALL_ALLIES, ALL, SELF, RANDOM_ENEMY, RANDOM_ALLY, RANDOM_ALL}
	var target_type_group := "enemies"
	print(dragged_card.card_data.target_type)
	match dragged_card.card_data.target_type:
		BaseCard.TargetType.SINGLE_ENEMY:
			target_type_group = "enemies"
		BaseCard.TargetType.SINGLE_ALLY:
			target_type_group = "allies"
		BaseCard.TargetType.SELF:
			target_type_group = "none"
	
	var found_target := true
	var target: Node2D = null
	if target_type_group != 'none':
		target = find_target(target_type_group)
		if target == null:
			found_target = false
			print("Null Target for ", dragged_card)
	
	if found_target:
		card_played.emit(dragged_card, target)
	else: # Released on a bad play target!
		card_bad_target.emit(dragged_card)
	reset_drag()

func reset_drag():
	# Reset the drag-related variables
	dragged_card.global_position = start_pos
	dragged_card = null
	drag_offset = Vector2.ZERO

# Find clicked on target in either enemies or allies group
func find_target(group: String) -> Node2D:
	for target in get_tree().get_nodes_in_group(group):
		var target_area := target.get_node('Area2D')
		if target_area and dragged_card.overlaps_area(target_area):
			return target
	return null
