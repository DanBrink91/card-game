class_name Events
extends RefCounted

signal player_hurt(player:Player)
signal player_dead(player:Player)
signal player_buy(player:Player, card:BaseCard)
signal player_gain(player:Player, card:BaseCard) # Player was given a card
signal player_give(player:Player, card:BaseCard) # Player gives a card
signal player_idle(player:Player)
