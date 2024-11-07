extends Control


@export var characters: Array[PlayerClassData] = []

@onready var PlayerContainer: Container = $PlayerContainer
@onready var CharacterContainer: Container = $ScrollContainer/CharacterContainer
@onready var ExitButton: Button = $ExitButton

var lobby_id: int = 0
var steam_id: int = -1
var lobby_members: Array = []

var main_menu_scene

var is_ready: bool = false
var character_selected: PlayerClassData

var steamid_to_avatar: Dictionary = {}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	steam_id = GlobalSteam.steam_id
	addCharacters()
	get_lobby_members()
	updateLobbyMembers()
	ExitButton.pressed.connect(leave_lobby)
	Steam.avatar_loaded.connect(_on_loaded_avatar)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	Steam.lobby_data_update.connect(_on_lobby_data_update)
	#Steam.lobby_message.connect(_on_lobby_message)
	GlobalSteam.network_packet.connect(_handle_network_packet)

func addCharacters() -> void:
	for character in characters:
		# Overall container for background + label
		var container: Container = Container.new()
		container.custom_minimum_size = Vector2(100, 100)
		# Center container for label
		var center:CenterContainer = CenterContainer.new()
		center.set_anchors_preset(Control.PRESET_FULL_RECT)
		
		# TODO: Replace this with sprites or something later...
		var label: Label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.set_anchors_preset(Control.PRESET_CENTER)
		label.text = character.name
		label.set("theme_override_colors/font_color",Color.BLACK)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Background Color Rect
		var color_rect: ColorRect = ColorRect.new()
		color_rect.color = Color.ALICE_BLUE
		color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		color_rect.mouse_filter =Control.MOUSE_FILTER_IGNORE
		
		# Add all the containers and children
		center.add_child(label)
		color_rect.add_child(center)
		container.add_child(color_rect)
		CharacterContainer.add_child(container)
		# Some events
		container.mouse_entered.connect(Callable(_on_character_hover).bind(container, character))
		container.mouse_exited.connect(Callable(_on_character_hover_exit).bind(container, character))
		container.gui_input.connect(_on_character_click.bind(container, character))

func _handle_network_packet(sender, data):
	match data.type:
		GlobalSteam.GAME_PACKET_TYPE.LOBBY_CHARACTER_UPDATE:
			pass

func createLobbyMember(member) -> void:
	# Send request for their avatar
	Steam.getPlayerAvatar(Steam.AVATAR_LARGE, member.steam_id)
	
	var grid_container: VBoxContainer = VBoxContainer.new()
	var name_container: MarginContainer = MarginContainer.new()
	name_container.set_anchors_preset(Control.PRESET_FULL_RECT)

	var name_label: Label = Label.new()
	name_label.size_flags_vertical = Control.SIZE_FILL
	name_label.size_flags_horizontal = Control.SIZE_FILL
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text = member.steam_name
	name_container.add_child(name_label)
	
	var sprite_container: MarginContainer = MarginContainer.new()
	sprite_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	var avatar: TextureRect = TextureRect.new()
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	if steamid_to_avatar.has(member.steam_id):
		avatar.set_texture(steamid_to_avatar[member.steam_id])
	else :
		avatar.set_texture(load("res://icon.svg")) # load a default avatar, to be replaced later
	sprite_container.add_child(avatar)
	
	var character_container: CenterContainer = CenterContainer.new()
	character_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	var character_label: Label = Label.new()
	character_label.size_flags_vertical = Control.SIZE_FILL
	character_label.size_flags_horizontal = Control.SIZE_FILL
	character_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_label.text = member.character
	
	character_container.add_child(character_label)
	
	grid_container.add_child(name_container)
	grid_container.add_child(sprite_container)
	grid_container.add_child(character_container)
	
	PlayerContainer.add_child(grid_container)

func removeLobbyMember(member) -> void:
	# find index in lobby_members
	var member_index: int = 0
	for other_member in lobby_members:
		if other_member.steam_id == member.steam_id:
			break
		member_index += 1
	PlayerContainer.get_child(member_index).queue_free()

func updateLobbyMembers() -> void:
	# clear current list
	for child in PlayerContainer.get_children():
		child.queue_free()
		
	for member in lobby_members:
		createLobbyMember(member)

func _on_loaded_avatar(user_id: int, avatar_size: int, avatar_buff: PackedByteArray) -> void:
	var avatar_image: Image = Image.create_from_data(avatar_size, avatar_size, false, Image.FORMAT_RGBA8, avatar_buff)
	
	if avatar_size > 128:
		avatar_image.resize(128, 128, Image.INTERPOLATE_LANCZOS)
	
	var avatar_texture: ImageTexture = ImageTexture.create_from_image(avatar_image)
	
	steamid_to_avatar[user_id] = avatar_texture
	# find index in lobby_members
	var member_index: int = 0
	var found_member := false
	for member in lobby_members:
		if member.steam_id == user_id:
			found_member = true
			break
		member_index += 1
	
	# Update the avatar
	if found_member :
		PlayerContainer.get_child(member_index).get_child(1).get_child(0).set_texture(avatar_texture)
	
func _on_character_hover(container: Container, character: PlayerClassData) -> void:
	print("Hovering over class: %s" % character.name)

func _on_character_hover_exit(container: Container, character: PlayerClassData) -> void:
	print("No longer hovering over class: %s" % character.name)

func _on_character_click(event: InputEvent, container: Container, character: PlayerClassData):
	if event is InputEventMouseButton and event.pressed:
		var updated: bool = false
		if character_selected == character: # unselect
			if character_selected != null:
				updated = true
			character_selected = null
			container.get_child(0).color = Color.ALICE_BLUE
		else:
			if character_selected != character:
				updated = true
			character_selected = character
			container.get_child(0).color = Color.AQUAMARINE
		if updated:
			var updated_character := character_selected.resource_path if character_selected else ""
			print("Updating lobby with %s" % updated_character)
			Steam.setLobbyMemberData(lobby_id, "character", updated_character)
			GlobalSteam.send_p2p_packet(0, {"type": GlobalSteam.GAME_PACKET_TYPE.LOBBY_CHARACTER_UPDATE, "character": updated_character })
	
func get_lobby_members() -> void:
	lobby_members.clear()
	
	var num_of_members: int = Steam.getNumLobbyMembers(lobby_id)
	
	for this_member in range(0, num_of_members):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, this_member)
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		var member_character: String = Steam.getLobbyMemberData(lobby_id, member_steam_id, "character")
		lobby_members.append({"steam_id": member_steam_id, "steam_name": member_steam_name, "character": member_character})

func _on_lobby_chat_update(this_lobby_id: int, change_id: int, making_change_id: int, chat_state: int) -> void:
	# Get the user who has made the lobby change
	var changer_name: String = Steam.getFriendPersonaName(change_id)

	# If a player has joined the lobby
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		createLobbyMember({"steam_id": change_id, "steam_name": changer_name, "character": ""})
		print("%s has joined the lobby." % changer_name)

	# Else if a player has left the lobby
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
		print("%s has left the lobby." % changer_name)

	# Else if a player has been kicked
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
		print("%s has been kicked from the lobby." % changer_name)

	# Else if a player has been banned
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
		print("%s has been banned from the lobby." % changer_name)

	# Else there was some unknown change
	else:
		print("%s did... something." % changer_name)

	# Update the lobby now that a change has occurred
	get_lobby_members()

func _on_lobby_data_update(success: int, this_lobby_id: int, member_id: int) -> void:
	if success == 1 and this_lobby_id == lobby_id:
		print("Lobby updated")
		var updated_character = Steam.getLobbyMemberData(this_lobby_id, member_id, "character")
		
		get_lobby_members()
		updateLobbyMembers()
		

# A user's information has changed
func _on_persona_change(this_steam_id: int, _flag: int) -> void:
	# Make sure you're in a lobby and this user is valid or Steam might spam your console log
	if lobby_id > 0:
		print("A user (%s) had information change, update the lobby list" % this_steam_id)

		# Update the player list
		get_lobby_members()

func leave_lobby() -> void:
	# If in a lobby, leave it
	if lobby_id != 0:
		# Send leave request to Steam
		Steam.leaveLobby(lobby_id)

		# Wipe the Steam lobby ID then display the default lobby ID and player list title
		lobby_id = 0

		# Close session with all users
		for this_member in lobby_members:
			# Make sure this isn't your Steam ID
			if this_member['steam_id'] != steam_id:
				# Close the P2P session
				Steam.closeP2PSessionWithUser(this_member['steam_id'])

		# Clear the local lobby list
		lobby_members.clear()
		
		# Go back to main menu
		get_tree().root.add_child(main_menu_scene)
		main_menu_scene.lobby_id = 0
		main_menu_scene._on_lobby_match_list([])
		self.queue_free()
		
