class_name Game
extends Node2D

signal turn_started(current_player)
signal turn_ended

signal remote_card_buy(player: Player, card_index: int)
signal remote_modal_select(card_index: int)
signal remote_modal_confirm
signal remote_enemy_decide(target_index: int)
signal remote_host_shuffle(deck: Array)

var player_characters: Array[PlayerClassData] = []
@export var player_scene: PackedScene  # Scene file for each player
@export var enemy_scene: PackedScene  # Scene file for each enemy
@export var enemy_count: int = 3  # Define the number of enemies

@export var end_game_scene: PackedScene

var players: Array[Player] = []
var enemies: Array[Enemy] = []

@onready var player_spawn: Node2D = $PlayerSpawn
@onready var enemy_spawn: Node2D = $EnemySpawn
@onready var end_turn_button: TextureButton = $EndTurnButton
@onready var stats: Stats = $Stats

var player_count := 0
var current_player_index: int = 0

var card_count :int = 0
var is_multiplayer:bool = true

var lobby_id:int = 0
var steamid_to_player: Dictionary = {}
var is_host: bool = false

var host_id: int
var game_start_time: float

var main_menu_scene

func get_card_id() -> int:
	card_count += 1
	return card_count

func _ready():
	player_count = player_characters.size()
	get_parent().game_start.connect(setup)
	GlobalSteam.network_packet.connect(_handle_network_data)

func setup() -> void:
	game_start_time = Time.get_unix_time_from_system()
	setup_game()
	connect_signals()
	start_turn()
	end_turn_button.pressed.connect(_on_turn_ended)

func setup_game():
	host_id = Steam.getLobbyOwner(lobby_id)
	is_host =  host_id == GlobalSteam.steam_id
	# Seed the random generator
	if is_host:
		randomize()
		var random_seed = randi()
		seed(random_seed)
		GlobalSteam.send_p2p_packet(0, {"type": GlobalSteam.GAME_PACKET_TYPE.GAME_SEED, "seed": random_seed})
		
		
	# Create players based on player_count
	generate_players_from_lobby()
	
	# Create enemies based on enemy_count
	for i in range(enemy_count):
		var enemy = enemy_scene.instantiate() as Enemy
		enemy.position = enemy_spawn.position
		enemy.is_host = is_host
		
		enemy.setup(players.size()) # Adjust enemy for player count
		enemies.append(enemy)
		add_child(enemy)
		enemy.add_to_group("enemies")
		stats.add_enemy_entry(enemy)
		enemy.enemy_death.connect(check_end_game)

func connect_signals():
	#for player in players:
		#player.turn_ended.connect(_on_turn_ended)
	for enemy in enemies:
		enemy.turn_ended.connect(_on_turn_ended)

func start_turn():
	var current_entity = get_current_entity()
	end_turn_button.visible = current_entity is Player and not current_entity.is_remote

	turn_started.emit(current_entity)  # Signal to start the turn
	await current_entity.start_turn()
	

func get_current_entity() -> Node:
	if current_player_index < players.size():
		return players[current_player_index]
	return enemies[(current_player_index - players.size()) % enemies.size()]

# When the button is pressed this fires
func _on_turn_ended():
	print("_on_turn_ended")
	var current_entity = get_current_entity()
	# you cant end on someone elses turn
	if current_entity is Player and current_entity.is_remote: return
	await end_turn()

# This handles actually ending the turn, can be called remotely
func end_turn() -> void:
	print("Game end_turn")
	var current_entity = get_current_entity()
	turn_ended.emit()
	if current_entity is Player:
		# If the player is local
		if not current_entity.is_remote:
			GlobalSteam.send_p2p_packet(0, {"type": GlobalSteam.GAME_PACKET_TYPE.GAME_END_TURN})
		await current_entity.end_turn()
	
	# Start the next turn!
	current_player_index += 1
	if current_player_index >= (players.size() + enemies.size()):
		current_player_index = 0  # Reset for new round
	print("Turn ending, starting next one... %d" % current_player_index)
	await start_turn()
	
func _handle_network_data(sender, data):
	var player: Player = steamid_to_player[sender]
	#if not player.is_remote: return
	if data.has("type"):
		match data.type:
			# Play a Card
			GlobalSteam.GAME_PACKET_TYPE.GAME_CARD_PLAY:
				print("Got Remote Card Play: %s " % data)
				var card: CardNode = player.handNode.cards[data.card_index]
				var target: Node2D = null
				match data.target_type:
					BaseCard.TargetType.SINGLE_ENEMY:
						var enemies = get_tree().get_nodes_in_group("enemies")
						target = enemies[data.target_index]
					BaseCard.TargetType.SINGLE_ALLY:
						var allies = get_tree().get_nodes_in_group("enemies")
						target = allies[data.target_index]
					_:
						pass
				player._on_card_played(card, target)
			# Interact with the Card Modal
			GlobalSteam.GAME_PACKET_TYPE.GAME_MODAL_UPDATE:
				print("Got Remote Modal Update: %s " % data)
				if data.has("card_index"):
					remote_modal_select.emit(data.card_index)
				else:
					remote_modal_confirm.emit()
			# Buy a card from the shop
			GlobalSteam.GAME_PACKET_TYPE.GAME_CARD_BUY:
				print("Got Remote Card Buy: %s " % data)
				remote_card_buy.emit(player, data.card)
			# Player Ends Turn
			GlobalSteam.GAME_PACKET_TYPE.GAME_END_TURN:
				end_turn()
			# In progress, host deciding enemy turn
			GlobalSteam.GAME_PACKET_TYPE.GAME_ENEMY_DECIDE:
				enemies[0].remote_target_index = data.target_index
				remote_enemy_decide.emit(data.target_index)
			GlobalSteam.GAME_PACKET_TYPE.GAME_SEED:
				print("game seed %d" % data.seed)
				seed(data.seed)
			GlobalSteam.GAME_PACKET_TYPE.GAME_HOST_SHUFFLE_REQUEST:
				print("got game host shuffle request")
				var target_player: Player = steamid_to_player[data.player]
				host_shuffle(target_player)
			GlobalSteam.GAME_PACKET_TYPE.GAME_HOST_SHUFFLE_RESPONSE:
				print("Got game host shuffle response")
				var deck_owner: Player = steamid_to_player[data.player]
				var order: Array = data.order
				deck_owner.saved_order = order
				remote_host_shuffle.emit(order)
			GlobalSteam.GAME_PACKET_TYPE.GAME_ENEMY_THREAT_PAID:
				# Assume the enemy with all the threats is 0 index
				if enemies.size() > 0:
					enemies[0].on_remote_threat_paid(player, data.threat_index)

func generate_players_from_lobby():
	var lobby_num_members: int = Steam.getNumLobbyMembers(lobby_id)
	for i in range(lobby_num_members):
		var member_id = Steam.getLobbyMemberByIndex(lobby_id, i)
		var member_name = Steam.getFriendPersonaName(member_id)
		var member_character = Steam.getLobbyMemberData(lobby_id, member_id, "character")
		
		var character: PlayerClassData = player_characters[int(member_character)]
		var is_remote: bool = member_id != GlobalSteam.steam_id
		var player = player_scene.instantiate() as Player
		player.position = player_spawn.position + Vector2(480 * i, 0)
		player.class_data = character.duplicate()
		player.is_remote = is_remote
		player.setup_class()
		players.append(player)
		add_child(player)
		player.add_to_group("allies")
		player.player_name = member_name
		player.is_host = is_host
		player.steam_id = member_id
		player.player_died.connect(check_end_game)
		steamid_to_player[member_id] = player
		stats.add_player_entry(player)

# Currently only kills / deaths are win/lose condition
func check_end_game() -> void:
	var alive_players = get_tree().get_nodes_in_group("allies").filter(func (player): return player.life > 0)
	if alive_players.size() == 0:
		end_game(false)
	var alive_enemies = get_tree().get_nodes_in_group("enemies").filter(func (enemy): return enemy.health > 0)
	if alive_enemies.size() == 0:
		end_game(true)
	
func end_game(victory: bool) -> void:	
	var end_game_s = end_game_scene.instantiate()
	end_game_s.victory = victory
	end_game_s.create_table(stats.player_data)
	end_game_s.main_menu_scene = main_menu_scene
	await get_tree().create_timer(0.75).timeout

	get_tree().root.add_child(end_game_s)	
	# Need to delay this... or something
	Steam.leaveLobby(lobby_id)
	# Close session with all users
	for player in players:
		# Make sure this isn't your Steam ID
		if player['steam_id'] != GlobalSteam.steam_id:
			# Close the P2P session
			Steam.closeP2PSessionWithUser(player['steam_id'])
	get_parent().queue_free()
	
# This should only be called on the host
func host_shuffle(player: Player):
	var random_order = range(player.deck.size())
	random_order.shuffle()
	print("Host Shuffling for player %s, random order: %s" % [player.player_name, random_order])
	print("Current Card IDs: %s" % str(player.deck.map(func(card): return card.id)))
	GlobalSteam.send_p2p_packet(0, {"type": GlobalSteam.GAME_PACKET_TYPE.GAME_HOST_SHUFFLE_RESPONSE,
	"order": random_order, "player": player.steam_id})
	

	if player.is_host: # We don't get this packet as we are the host, sort in place right here
		player.saved_order = random_order
