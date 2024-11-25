class_name DiscardOrDamage
extends BaseThreat

@export var cards_to_discard: int
@export var damage_to_take: int
@export var card_modal_scene: PackedScene

func get_description() -> String:
	return description % [cards_to_discard, damage_to_take]

# Pay a single
func pay(player: Player) -> void:
	if player.hand.size() <= 1: # You need a card besides this one
		return # You won't have any options!

	var card_modal = card_modal_scene.instantiate() as CardModal
	card_modal.active_player = player
	card_modal.game = player.game

	player.get_tree().root.add_child(card_modal)
	
	card_modal.global_position -= card_modal.size / 2
	var modal_data = await card_modal.show_modal("Pick card(s) to discard", player.hand, 1, cards_to_discard)
	var modal_success: bool = modal_data[0]
	var cards: Array[BaseCard] = modal_data[1]
	for card_to_discard in cards:
		player.discard_card(card_to_discard)
	cards_to_discard -= cards.size()
	print("Cards to discard: %d" % cards_to_discard)
	player.update_ui()
	card_modal.queue_free()

func is_paid() -> bool:
	return cards_to_discard <= 0

# If its not paid off in time and triggers
func complete(game: Game) -> void:
	for player in game.players:
		player.take_damage(damage_to_take)
