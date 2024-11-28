class_name Player
extends Node2D

signal turn_ended
signal card_bought(card: BaseCard)
signal card_played(card: BaseCard)
signal damage_taken(amount: int)
signal player_died

@export var buff_scene: PackedScene

# Starting Data for our Class
@export var class_data: PlayerClassData

# Grab the Game
@onready var game: Game = get_parent()
# Visual Display of Hand
@onready var handNode: Node2D = $Hand as Hand
# UI Stuff
@onready var PlayerUI: Control = $PlayerUI
var HealthLabel: RichTextLabel
var ManaLabel: RichTextLabel
var MoneyLabel: RichTextLabel
@onready var buff_container = $BuffContainer

var player_name:String = "Player 1"
var life := 10
var mana := 3
var base_mana := 3
var money := 0

var hand_size := 5
# Actual Cards
var deck: Array[BaseCard] = []
var discard: Array[BaseCard] = []
var hand: Array[BaseCard]= []

enum CARD_LOCATIONS {DECK, HAND, DISCARD, NONE}

var steam_id: int
var is_remote: bool = false
var is_host: bool = false

var saved_order: Array # Save the order for deck shuffling when host

# Debuff live here too!
var buffs: Array[BaseBuff]

var is_alive: bool = true
func _ready() -> void:
	HealthLabel = PlayerUI.get_node_or_null('HealthLabel')
	ManaLabel = PlayerUI.get_node_or_null('ManaLabel')
	MoneyLabel = PlayerUI.get_node_or_null('MoneyLabel')
	update_ui()

func update_ui() -> void:
	HealthLabel.text = str(life)
	ManaLabel.text = str(mana)
	MoneyLabel.text = str(money)

# Use the class_data to setup our starting stats + cards
func setup_class():
	await self.ready
	life = class_data.starting_health
	hand_size = class_data.starting_hand_size
	
	base_mana = class_data.starting_mana
	mana = base_mana
	update_ui()
	var card_counter:int = 0
	for card in class_data.starting_cards:
		# Duplicate the BaseCard so each CardNode has a unique one
		if card_counter >= hand_size:
			add_card(card, CARD_LOCATIONS.DECK)
		else:
			add_card(card, CARD_LOCATIONS.HAND)
		card_counter += 1
	
	handNode.card_played.connect(_on_card_played)

# add a new card to deck, discard, or hand
func add_card(card: BaseCard, to: CARD_LOCATIONS) -> void:
	var dup_card: BaseCard = card.duplicate()
	dup_card.id = game.get_card_id()
	dup_card.owner = self
	match to:
		CARD_LOCATIONS.DECK:
			deck.append(dup_card)
		CARD_LOCATIONS.HAND: # Hand has special logic to make it show up
			add_to_hand(dup_card)
		CARD_LOCATIONS.DISCARD:
			discard.append(dup_card)

# Add a Card to Hand, from anywhere
func add_to_hand(card: BaseCard) -> void:
	var card_node = CardNode.new()
	card_node.set_card_data(card)
	handNode.add_card(card_node)
	hand.append(card)

func start_turn() -> void:
	for buff in buffs:
		await buff.on_start_turn()
	update_buffs()
	print("player start turn")
	if not is_remote:
		print("starting hand")
		handNode.start_turn()

func end_turn() -> void:
	print("player end turn called")
	if not is_remote:
		handNode.end_turn()
	discard_hand()
	var cardsToDraw := hand_size 
	var drawnCards := await draw(cardsToDraw)
	for card in drawnCards:
		add_to_hand(card)
	turn_ended.emit()
	mana = base_mana
	money = 0
	update_ui()
	for buff in buffs:
		await buff.on_end_turn()
	update_buffs()


# Discard ALL cards from hand
func discard_hand() -> void:
	discard += hand
	for card in hand:
		handNode.remove_card(card)
	hand = []

func _on_card_played(card: CardNode, target: Node2D) -> void:
	if not is_remote:
		var card_index: int = handNode.cards.find(card)
		var target_type: BaseCard.TargetType = BaseCard.TargetType.SELF
		var target_index: int = 0
		
		if target is Enemy:
			target_type = BaseCard.TargetType.SINGLE_ENEMY
		elif target is Player:
			target_type = BaseCard.TargetType.SINGLE_ALLY
			target_index = game.players.find(target)	
		GlobalSteam.send_p2p_packet(0, {"type": GlobalSteam.GAME_PACKET_TYPE.GAME_CARD_PLAY, "target_type": target_type, "target_index": target_index, "card_index": card_index})
	
	var data: BaseCard = card.card_data
	card.play_card(self, target)
	card_played.emit(data)
	mana -= data.cost
	update_ui()
	for buff in buffs:
		await buff.on_card_played(data)
	update_buffs()
	if find_card_location(data) == CARD_LOCATIONS.HAND: # Make sure card is still in hand before we discard it
		discard_card(data) # TODO: find it by ID or something??

# Discard a specific card from hand
func discard_card(card: BaseCard) -> void:
	var filtered_cards := hand.filter(func (other_card:BaseCard):  return other_card.id == card.id)
	if filtered_cards.size() > 0:
		print("Discarding found card")
		hand.erase(filtered_cards[0])
		discard.append(card)
		handNode.remove_card(card)
	else:
		print("Discard card not found: ", card)

# Find card in hand, deck, or discard and remove it
func destroy_card(card: BaseCard) -> void:
	var filtered_cards := hand.filter(func (other_card:BaseCard):  return other_card.id == card.id)
	if filtered_cards.size() > 0: # Card was in our hand
		hand.erase(filtered_cards[0])
		handNode.remove_card(card)
	else: # Card wasn't in our hand look elsewhere
		filtered_cards = deck.filter(func (other_card:BaseCard):  return other_card.id == card.id)
		if filtered_cards.size() > 0:
			deck.erase(filtered_cards[0])
		else:
			filtered_cards = discard.filter(func (other_card:BaseCard):  return other_card.id == card.id)
			if filtered_cards.size() > 0:
				discard.erase(filtered_cards[0])
			else:
				print("Tried to destroy card but did not find it anywhere on player")

func get_all_cards() -> Array[BaseCard]:
	return deck + discard + hand

func shuffle_discard_into_deck() -> void:
	deck += discard
	discard = []
	deck.shuffle()
	#if is_host: # We sorted this earlier
		#print("shuffle is_host")
		#if not is_remote: # If local we need to request the shuffle ourselves
			#print("shuffle is local")
			#game.host_shuffle(self)
		#var sorted_deck: Array[BaseCard] = []
		#for index in saved_order:
			#sorted_deck.append(deck[index])
		#deck = sorted_deck.duplicate()
		#saved_order = []			
	#else:
		#if not is_remote: # If we are local and not host, request the host to shuffle
			#GlobalSteam.send_p2p_packet(game.host_id, {"type": GlobalSteam.GAME_PACKET_TYPE.GAME_HOST_SHUFFLE_REQUEST,
			#"player": steam_id})
		#if saved_order.size() == 0: # Wait for the order command if we don't have it
			#saved_order = await game.remote_host_shuffle # Wait for deck to be shuffled
		## Put the deck in the order we got
		#var sorted_deck: Array[BaseCard] = []
		#for index in saved_order:
			#sorted_deck.append(deck[index])
		#deck = sorted_deck.duplicate()
		#saved_order = []

# Removes cards from deck and returns them as an array
func draw(amount:int) -> Array[BaseCard]:
	print("%s cards to draw" % amount)
	var drawn_cards: Array[BaseCard] = []
	if amount > deck.size():
		drawn_cards += deck
		amount -= deck.size()
		deck = []
		await shuffle_discard_into_deck()
		print("Shuffled discard into deck, continuing Deck size: %s" % deck.size())
	amount = min(amount, deck.size()) # can only draw as many as we have
	for i in range(amount):
		drawn_cards.append(deck.pop_front())
	return drawn_cards

func take_damage(amount:int) -> void:
	for buff in buffs:
		amount = buff.on_damage_taking(null, amount) # TODO: Add attacker here..
	update_buffs()
	Util.spawn_floating_text("-" + str(amount), global_position + Vector2(50, -50), Vector2(0, -45), 1.5)
	damage_taken.emit(amount)
	print("Player taking %s damage" % amount)
	life -= amount
	if life <= 0 and is_alive:
		is_alive = false
		player_died.emit()
		print("Player died...")
		# Death Penalties, TODO: Buff / Debuff replace this
		hand_size = max(hand_size - 2, 3)
		base_mana = max(base_mana - 1, 1)
		
	update_ui()

func deal_damage(target: Node2D, amount: int) -> int:
	for buff in buffs:
		amount = buff.on_damage_dealing(target, amount)
	update_buffs()
	return amount

func gain_money(amount: int) -> void:
	for buff in buffs:
		amount = buff.on_money_gain(amount)
	update_buffs() 
	money += amount
	update_ui()

func buy_card(card: BaseCard) -> void:
	card_bought.emit(card)
	Util.spawn_floating_text("-" + str(card.price), global_position + Vector2(50, -30), Vector2(0, -45), 1.0, Color.GOLD)
	money -= card.price
	add_card(card, CARD_LOCATIONS.DISCARD)
	card.on_buy(self)
	update_ui()

func find_card_location(card: BaseCard) -> CARD_LOCATIONS:
	var filtered_cards := hand.filter(func (other_card:BaseCard):  return other_card.id == card.id)
	if filtered_cards.size() > 0:
		return CARD_LOCATIONS.HAND
	filtered_cards = deck.filter(func (other_card:BaseCard):  return other_card.id == card.id)
	if filtered_cards.size() > 0:
		return CARD_LOCATIONS.DECK
	filtered_cards = discard.filter(func (other_card:BaseCard):  return other_card.id == card.id)
	if filtered_cards.size() > 0:
		return CARD_LOCATIONS.DISCARD
	return CARD_LOCATIONS.NONE

func add_buff(buff: BaseBuff, stacks: int) -> void:
	var new_buff := true
	for existing_buff in buffs:
		if existing_buff == buff:
			new_buff = false
			existing_buff.stacks += stacks
			break
	
	if new_buff:
		var new_buff_obj: BaseBuff = buff.duplicate()
		var buff_ui: Buff = buff_scene.instantiate()
		new_buff_obj.stacks = stacks
		buff_ui.set_buff(new_buff_obj)
		buffs.append(new_buff_obj)
		buff_container.add_child(buff_ui)

func update_buffs() -> void:
	var buff_index := 0
	while buff_index < buffs.size():
		var buff_ui: Buff = buff_container.get_child(buff_index)
		if buffs[buff_index].expired():
			buffs.remove_at(buff_index)
			buff_container.remove_child(buff_ui)
			buff_ui.queue_free()
		else:
			buff_ui.update()
			buff_index += 1
