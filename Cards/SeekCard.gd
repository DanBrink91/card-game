extends BaseCard
class_name SeekCard

@export var cards_to_draw: int = 1
@export var cardModalScene: PackedScene

func play(player:Player, target) -> void:
	print("Seek Card Played")
	if player.deck.size() == 0:
		return # You won't have any options!
		#if player.discard.size() == 0:
			#return # There's nothing you could possibly draw...
		#else:
			#await player.shuffle_discard_into_deck() # Shuffle discard
	
	var card_modal = cardModalScene.instantiate() as CardModal
	card_modal.active_player = player
	card_modal.game = player.game

	player.get_tree().root.add_child(card_modal)
	
	card_modal.global_position -= card_modal.size / 2
	var modal_data = await card_modal.show_modal("Pick a card to add it to your hand", player.deck, cards_to_draw)
	var modal_success: bool = modal_data[0]
	var cards: Array[BaseCard] = modal_data[1]
	var card_to_grab: BaseCard = cards[0]
	# remove card from 
	player.deck.erase(card_to_grab)
	player.add_to_hand(card_to_grab)
	card_modal.queue_free()
