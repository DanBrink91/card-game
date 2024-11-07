extends BaseCard
class_name SeekCard

@export var cards_to_draw: int = 1
@export var cardModalScene: PackedScene

func play(player:Player, target) -> void:
	print("Seek Card Played")
	var card_modal = cardModalScene.instantiate() as CardModal
	player.get_tree().current_scene.add_child(card_modal)
	card_modal.global_position -= card_modal.size / 2
	# TODO Add a path where this information is given w/o showing the modal for network play?
	var modal_data = await card_modal.show_modal("Pick a card to add it to your hand", player.deck, cards_to_draw)
	var modal_success: bool = modal_data[0]
	var cards: Array[BaseCard] = modal_data[1]
	var card_to_grab: BaseCard = cards[0]
	# remove card from 
	player.deck.erase(card_to_grab)
	player.add_to_hand(card_to_grab)
	card_modal.queue_free()
