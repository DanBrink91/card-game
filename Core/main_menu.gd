extends Control

# lobby stuff
var lobby_data
var lobby_id: int = 0
var lobby_members: Array = []
var lobby_members_max: int = 4
var lobby_vote_kick: bool = false

@export var join_button: Button
@export var host_button: Button

@onready var lobby_container: Container = $ScrollContainer/LobbyListContainer

var lobby_scene = preload("res://Scenes/lobby.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	join_button.pressed.connect(_on_open_lobby_list_pressed)
	host_button.pressed.connect(create_lobby)
	
	Steam.join_requested.connect(_on_lobby_join_requested)
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_invite.connect(_on_lobby_invite)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.persona_state_change.connect(_on_persona_change)
	
	Steam.avatar_loaded.connect(_on_loaded_avatar)
	Steam.getPlayerAvatar(Steam.AVATAR_LARGE, GlobalSteam.steam_id)
	
func _on_loaded_avatar(user_id: int, avatar_size: int, avatar_buff: PackedByteArray) -> void:
	print("Avata for user: %s" % user_id)
	
	var avatar_image: Image = Image.create_from_data(avatar_size, avatar_size, false, Image.FORMAT_RGBA8, avatar_buff)
	
	if avatar_size > 128:
		avatar_image.resize(128, 128, Image.INTERPOLATE_LANCZOS)
	
	var avatar_texture: ImageTexture = ImageTexture.create_from_image(avatar_image)
	$PartyContainer/HBoxContainer/PlayerAvatarContainer/PlayerAvatar.set_texture(avatar_texture)

func create_lobby() -> void:
	if lobby_id == 0:
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, lobby_members_max)

func _on_lobby_created(connect: int, this_lobby_id: int) -> void:
	if connect == 1:
		lobby_id = this_lobby_id
		print("Created a lobby: %s" % lobby_id)
		
		Steam.setLobbyJoinable(lobby_id, true) # this should already be done but just in case..
		
		# Setup some lobby data
		Steam.setLobbyData(lobby_id, "name", "Zieth Game Lobby")
		Steam.setLobbyData(lobby_id, "mode", "Single Boss")
		
		# Allow P2P connections to fallback through Steam if needed
		var set_relay: bool = Steam.allowP2PPacketRelay(true)
		print("Allowing Steam to be relay backup: %s" % set_relay)
		
func _on_open_lobby_list_pressed() -> void:
	   # Set distance to worldwide
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	# TODO: Remove this once we have our own app id
	Steam.addRequestLobbyListStringFilter("name", "Zieth Game Lobby", Steam.LOBBY_COMPARISON_EQUAL)
	print("Requesting a lobby list")
	Steam.requestLobbyList()

func _on_lobby_match_list(these_lobbies: Array) -> void:
	# Clear lobby list
	for child in lobby_container.get_children():
		# Do i have to remove the child first or just removing fine?
		child.queue_free()
		
	if these_lobbies.size() == 0:
		var message_label: Label = Label.new()
		message_label.text = "No lobbies found"
		# Create a new container for the button
		var button_container: MarginContainer = MarginContainer.new()
		button_container.add_child(message_label)
		lobby_container.add_child(button_container)
		# Make message go away after time
		await get_tree().create_timer(2.0).timeout
		button_container.queue_free()
		
	for this_lobby in these_lobbies:
		# Pull lobby data from Steam, these are specific to our example
		var lobby_name: String = Steam.getLobbyData(this_lobby, "name")
		var lobby_mode: String = Steam.getLobbyData(this_lobby, "mode")

		# Get the current number of members
		var lobby_num_members: int = Steam.getNumLobbyMembers(this_lobby)

		# Create a button for the lobby
		var lobby_button: Button = Button.new()
		lobby_button.set_text("Lobby %s: %s [%s] - %s Player(s)" % [this_lobby, lobby_name, lobby_mode, lobby_num_members])
		lobby_button.set_size(Vector2(800, 50))
		lobby_button.set_name("lobby_%s" % this_lobby)
		lobby_button.connect("pressed", Callable(self, "join_lobby").bind(this_lobby))
		
		# Create a new container for the button
		var button_container: MarginContainer = MarginContainer.new()
		button_container.add_child(lobby_button)
		# Add the container with the button 
		lobby_container.add_child(button_container)

func join_lobby(this_lobby_id: int) -> void:
	print("Attempting to join lobby %s" % this_lobby_id)
	lobby_members.clear()
	Steam.joinLobby(this_lobby_id)

 #When getting a lobby invitation, TODO: Add popup to handle this..

func _on_lobby_invite(inviter: int, this_lobby_id: int, game_id: int) -> void:
	pass
	#get_node("%Output").add_new_text("You have received an invite from %s to join lobby %s / game %s" % [Steam.getFriendPersonaName(inviter), this_lobby_id, game_id])

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	# If joining was successful
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		# Set this lobby ID as your lobby ID
		lobby_id = this_lobby_id
		var lobby_nodes = lobby_scene.instantiate()
		lobby_nodes.lobby_id = lobby_id
		lobby_nodes.main_menu_scene = self
		get_tree().root.add_child(lobby_nodes)
		get_tree().root.remove_child(self)
	# Else it failed for some reason
	else:
		# Get the failure reason
		var fail_reason: String

		match response:
			Steam.CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST: fail_reason = "This lobby no longer exists."
			Steam.CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED: fail_reason = "You don't have permission to join this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_FULL: fail_reason = "The lobby is now full."
			Steam.CHAT_ROOM_ENTER_RESPONSE_ERROR: fail_reason = "Uh... something unexpected happened!"
			Steam.CHAT_ROOM_ENTER_RESPONSE_BANNED: fail_reason = "You are banned from this lobby."
			Steam.CHAT_ROOM_ENTER_RESPONSE_LIMITED: fail_reason = "You cannot join due to having a limited account."
			Steam.CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED: fail_reason = "This lobby is locked or disabled."
			Steam.CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN: fail_reason = "This lobby is community locked."
			Steam.CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU: fail_reason = "A user in the lobby has blocked you from joining."
			Steam.CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER: fail_reason = "A user you have blocked is in the lobby."

		print("Failed to join this chat room: %s" % fail_reason)

		#Reopen the lobby list
		_on_open_lobby_list_pressed()

# accepts a steam invite or clicking on friend list join game
func _on_lobby_join_requested(this_lobby_id: int, friend_id: int) -> void:
	# Get the lobby owner's name
	var owner_name: String = Steam.getFriendPersonaName(friend_id)

	print("Joining %s's lobby..." % owner_name)

	# Attempt to join the lobby
	join_lobby(this_lobby_id)

func _on_persona_change(this_steam_id: int, _flag: int) -> void:
	if lobby_id > 0:
		print("A user (%s) had information change, update the lobby list" % this_steam_id)

#func make_p2p_handshake() -> void:
	#send_p2p_packet(0, {"message": "handshake", "from": steam_id})
