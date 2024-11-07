class_name Game
extends Node2D

signal turn_started(current_player)
signal turn_ended
signal remote_card_buy(player: Player, card_index: int)

@export var player_characters: Array[PlayerClassData] = []
@export var player_scene: PackedScene  # Scene file for each player
@export var enemy_scene: PackedScene  # Scene file for each enemy
@export var enemy_count: int = 3  # Define the number of enemies

var players: Array[Player] = []
var enemies: Array[Enemy] = []

@onready var player_spawn: Node2D = $PlayerSpawn
@onready var enemy_spawn: Node2D = $EnemySpawn
@onready var end_turn_button: TextureButton = $EndTurnButton


var player_count := 0
var current_player_index: int = 0

var card_count :int = 0
var is_multiplayer:bool = true

var lobby_id:int = 0
var steamid_to_player: Dictionary = {}

func get_card_id() -> int:
	card_count += 1
	return card_count

func _ready():
	player_count = player_characters.size()
	get_parent().game_start.connect(setup)
	GlobalSteam.network_packet.connect(_handle_network_data)

func setup() -> void:
	setup_game()
	connect_signals()
	start_turn()
	end_turn_button.pressed.connect(_on_turn_ended)

func setup_game():
	# Create players based on player_count
	var player_index :int = 0
	# TODO: Check if we are a local or networked player
	for character in player_characters:
		var player = player_scene.instantiate() as Player
		player.position = player_spawn.position + Vector2(480 * player_index, 0)
		player.class_data = character
		player.setup_class()
		players.append(player)
		add_child(player)
		player.add_to_group("allies")
		player.player_name = "Player %d" % (player_index + 1)
		player_index += 1
		
		
	# Create enemies based on enemy_count
	for i in range(enemy_count):
		var enemy = enemy_scene.instantiate() as Enemy
		enemy.position = enemy_spawn.position
		enemies.append(enemy)
		add_child(enemy)
		enemy.add_to_group("enemies")

func connect_signals():
	for player in players:
		player.turn_ended.connect(_on_turn_ended)
	for enemy in enemies:
		enemy.turn_ended.connect(_on_turn_ended)

func start_turn():
	var current_entity = get_current_entity()
	turn_started.emit(current_entity)  # Signal to start the turn
	current_entity.start_turn()
	
	end_turn_button.visible = current_entity is Player

func get_current_entity() -> Node:
	if current_player_index < players.size():
		return players[current_player_index]
	return enemies[(current_player_index - players.size()) % enemies.size()]

func _on_turn_ended():
	turn_ended.emit()
	var current_entity = get_current_entity()
	if current_entity is Player:
		current_entity.end_turn()
	# Start the next turn!
	current_player_index += 1
	if current_player_index >= (players.size() + enemies.size()):
		current_player_index = 0  # Reset for new round
	start_turn()

func _handle_network_data(sender, data):
	var player: Player = steamid_to_player[sender]
	
	match data.type:
		GlobalSteam.GAME_PACKET_TYPE.GAME_CARD_PLAY:
			pass
		GlobalSteam.GAME_PACKET_TYPE.GAME_MODAL_UPDATE:
			pass
		GlobalSteam.GAME_PACKET_TYPE.GAME_CARD_BUY:
			remote_card_buy.emit(player, data.card)

func add_remote_player_signals(player) -> void:
	pass

func generate_players_from_lobby():
	var lobby_num_members: int = Steam.getNumLobbyMembers(lobby_id)
	for i in range(lobby_num_members):
		var member_id = Steam.getLobbyMemberByIndex(lobby_id, i)
		var member_name = Steam.getFriendPersonaName(member_id)
		var member_character = Steam.getLobbyMemberData(lobby_id, member_id, "character")
		
		var is_remote: bool = member_id != GlobalSteam.steam_id
		var player = player_scene.instantiate() as Player
		player.position = player_spawn.position + Vector2(480 * i, 0)
		player.class_data = load(member_character) # TODO switch to enums...
		player.is_remote = is_remote
		player.setup_class()
		players.append(player)
		add_child(player)
		player.add_to_group("allies")
		player.player_name = member_name
		add_remote_player_signals(player)
		steamid_to_player[member_id] = player

	
	
