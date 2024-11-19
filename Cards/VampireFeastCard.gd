class_name VampireFeastCard
extends BaseCard

@export var cards_to_destroy: int = 1
@export var cardModalScene: PackedScene

func play(player:Player, target) -> void:
	print("Vampire Feast Card Played")
	if player.hand.size() <= 1: # You need a card besides this one
		return # You won't have any options!
	
	var card_modal = cardModalScene.instantiate() as CardModal
	card_modal.active_player = player
	card_modal.game = player.game

	player.get_tree().root.add_child(card_modal)
	
	card_modal.global_position -= card_modal.size / 2
	# Discard before showing hand to pick destroy
	player.discard_card(self)
	var modal_data = await card_modal.show_modal("Pick a card to destroy and gain energy", player.hand, cards_to_destroy)
	var modal_success: bool = modal_data[0]
	var cards: Array[BaseCard] = modal_data[1]
	var card_to_grab: BaseCard = cards[0]
	
	# Destroy the card picked and give 1 energy
	player.destroy_card(card_to_grab)
	player.mana += 1
	player.update_ui()
	card_modal.queue_free()
