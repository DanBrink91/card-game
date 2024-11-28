class_name RestorativePurge
extends BaseCard

@export var cardModalScene: PackedScene
@export var heal: int = 2

func get_description() -> String:
	return description % heal

func on_buy(player: Player) -> void:
	for playa: Player in player.game.players:
		playa.life += heal
		playa.update_ui()

func play(player:Player, target) -> void:
	print("RestorativePurge Card Played")
	
	var card_modal = cardModalScene.instantiate() as CardModal
	card_modal.active_player = player
	card_modal.game = player.game

	player.get_tree().root.add_child(card_modal)
	
	card_modal.global_position -= card_modal.size / 2
	var modal_data = await card_modal.show_modal("Pick a card to destroy", player.hand)
	var modal_success: bool = modal_data[0]
	var cards: Array[BaseCard] = modal_data[1]
	var card_to_grab: BaseCard = cards[0]
	
	# Destroy picked card
	player.destroy_card(card_to_grab)
	card_modal.queue_free()
