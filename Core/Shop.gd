class_name Shop
extends Node2D


@export var ShopNodeScene: PackedScene # The Scene we use to represent a card to buy

@export var MoneyCards: Array[BaseCard] # The Money / Coin cards avaiable to buy
@export var SpellCards: Array[BaseCard] #  The rest of the cards avaiable to buy

@export var cardRowCount: int = 3 # How many cards per row
@export var cardXSpacing: int = 80 # How much space X
@export var cardYSpacing: int = 175 # How much space Y

@onready var game: Game = get_parent()

var shop_cards: Array[Shop_Card] = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	placeShopCards()
	game.remote_card_buy.connect(_handle_remote_card_buy)
	

func placeShopCards() -> void:
	var x := 0
	var y := 0
	for card in MoneyCards + SpellCards:
		var card_instance = ShopNodeScene.instantiate() as Shop_Card
		card_instance.card_data = card.duplicate()
		card_instance.position = Vector2(x * cardXSpacing, y * cardYSpacing)
		card_instance.card_clicked.connect(_handle_card_click)
		shop_cards.append(card_instance)
		add_child(card_instance)
		if x + 1 >= cardRowCount:
			y += 1
			x = 0
		else:
			x += 1

func _handle_card_click(card: Shop_Card) -> void:
	var buyer: Node2D = game.get_current_entity()
	if buyer is Enemy or card.stock <= 0: return # ignore attempts to buy during the enemy's turn
	if buyer.is_remote: return # you can't buy
	var card_data = card.card_data
	print("Buyer has %s money, Price is %s" % [buyer.money, card_data.price])
	# Buy the card
	if buyer.money >= card_data.price:
		var card_index = shop_cards.find(card)
		GlobalSteam.send_p2p_packet(0, {"type": GlobalSteam.GAME_PACKET_TYPE.GAME_CARD_BUY, "card": card_index})
		buyer.buy_card(card_data)
		card.stock -= 1
		card.refresh_display()
		

func _handle_remote_card_buy(player: Player, card_index: int) -> void:
	var shop_card:Shop_Card = shop_cards[card_index]
	var card: BaseCard = shop_card.card_data
	player.buy_card(card)
	shop_card.stock -= 1
	shop_card.refresh_display()
	
