extends Node

signal lobby_join(lobby_id: int)
signal network_packet(sender, data)

const PACKET_READ_LIMIT: int = 32

var app_id:int = 480

var is_on_steam_deck: bool
var is_online: bool
var is_owned: bool
var steam_id: int
var steam_username: String

var lobby_id: int = 0
var lobby_members: Array

enum GAME_PACKET_TYPE {LOBBY_CHARACTER_UPDATE, GAME_CARD_PLAY, GAME_MODAL_UPDATE, GAME_CARD_BUY}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initialize_steam()
	check_command_line()
	Steam.p2p_session_request.connect(_on_p2p_session_request)
	Steam.p2p_session_connect_fail.connect(_on_p2p_session_connect_fail)
	#Steam.lobby_joined.connect(_on_lobby_joined)
	#Steam.lobby_chat_update.connect(_on_lobby_chat_update)

func check_command_line() -> void:
	var these_arguments: Array = OS.get_cmdline_args()
	if these_arguments.size() > 0:
		if these_arguments[0] == '+connect_lobby':
			if int(these_arguments[1]) > 0:
				# Join the lobby now...
				print("Command line lobby id: %s" % these_arguments[1])
				lobby_join.emit(these_arguments[1])

func _process(delta: float) -> void:
	Steam.run_callbacks()
	
	if lobby_id > 0:
		read_all_p2p_packets()

func _init() -> void:
	# Set your game's Steam app ID here
	OS.set_environment("SteamAppId", str(app_id))
	OS.set_environment("SteamGameId", str(app_id))
	
func initialize_steam() -> void:
	var initialize_response: Dictionary = Steam.steamInitEx()
	print("Did Steam initialize?: %s " % initialize_response)
	
	if initialize_response['status'] > 0:
		print("Failed to initialize Steam, shutting down: %s" % initialize_response)
		get_tree().quit()
	
	is_on_steam_deck = Steam.isSteamRunningOnSteamDeck()
	is_online = Steam.loggedOn()
	is_owned = Steam.isSubscribed()
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()

func read_all_p2p_packets(read_count: int = 0):
	if read_count >= PACKET_READ_LIMIT:
		return
	
	if Steam.getAvailableP2PPacketSize(0) > 0:
		read_p2p_packet()
		read_all_p2p_packets(read_count + 1)

func _on_p2p_session_request(remote_id: int) -> void:
	# Get the requester's name
	var this_requester: String = Steam.getFriendPersonaName(remote_id)
	print("%s is requesting a P2P session" % this_requester)

	# Accept the P2P session; can apply logic to deny this request if needed
	Steam.acceptP2PSessionWithUser(remote_id)

	# Make the initial handshake
	make_p2p_handshake()

func read_p2p_packet() -> void:
	var packet_size: int = Steam.getAvailableP2PPacketSize(0)

	# There is a packet
	if packet_size > 0:
		var this_packet: Dictionary = Steam.readP2PPacket(packet_size, 0)

		if this_packet.is_empty() or this_packet == null:
			print("WARNING: read an empty packet with non-zero size!")

		# Get the remote user's ID
		var packet_sender: int = this_packet['remote_steam_id']

		# Make the packet data readable
		var packet_code: PackedByteArray = this_packet['data']

		# Decompress the array before turning it into a useable dictionary
		var readable_data: Dictionary = bytes_to_var(packet_code.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP))

		# Print the packet to output
		print("Packet: %s" % readable_data)

		# Append logic here to deal with packet data
		network_packet.emit(packet_sender, readable_data)

func send_p2p_packet(target: int, packet_data: Dictionary) -> void:
	# Set the send_type and channel
	var send_type: int = Steam.P2P_SEND_RELIABLE
	var channel: int = 0

	# Create a data array to send the data through
	var this_data: PackedByteArray

	# Compress the PackedByteArray we create from our dictionary  using the GZIP compression method
	var compressed_data: PackedByteArray = var_to_bytes(packet_data).compress(FileAccess.COMPRESSION_GZIP)
	this_data.append_array(compressed_data)

	# If sending a packet to everyone
	if target == 0:
		# If there is more than one user, send packets
		if lobby_members.size() > 1:
			# Loop through all members that aren't you
			for this_member in lobby_members:
				if this_member['steam_id'] != steam_id:
					Steam.sendP2PPacket(this_member['steam_id'], this_data, send_type, channel)

	# Else send it to someone specific
	else:
		Steam.sendP2PPacket(target, this_data, send_type, channel)

func make_p2p_handshake() -> void:
	print("Sending P2P handshake to the lobby")

	send_p2p_packet(0, {"message": "handshake", "from": steam_id})

func _on_p2p_session_connect_fail(steam_id: int, session_error: int) -> void:
	# If no error was given
	if session_error == 0:
		print("WARNING: Session failure with %s: no error given" % steam_id)

	# Else if target user was not running the same game
	elif session_error == 1:
		print("WARNING: Session failure with %s: target user not running the same game" % steam_id)

	# Else if local user doesn't own app / game
	elif session_error == 2:
		print("WARNING: Session failure with %s: local user doesn't own app / game" % steam_id)

	# Else if target user isn't connected to Steam
	elif session_error == 3:
		print("WARNING: Session failure with %s: target user isn't connected to Steam" % steam_id)

	# Else if connection timed out
	elif session_error == 4:
		print("WARNING: Session failure with %s: connection timed out" % steam_id)

	# Else if unused
	elif session_error == 5:
		print("WARNING: Session failure with %s: unused" % steam_id)

	# Else no known error
	else:
		print("WARNING: Session failure with %s: unknown error %s" % [steam_id, session_error])


func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	# If joining was successful
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		# Set this lobby ID as your lobby ID
		lobby_id = this_lobby_id
		get_lobby_members()
	# Else it failed for some reason
	else:
		pass

func _on_lobby_chat_update(this_lobby_id: int, change_id: int, making_change_id: int, chat_state: int) -> void:
	# Update the lobby now that a change has occurred
	get_lobby_members()

func get_lobby_members() -> void:
	lobby_members.clear()
	
	var num_of_members: int = Steam.getNumLobbyMembers(lobby_id)
	
	for this_member in range(0, num_of_members):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(lobby_id, this_member)
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		
		lobby_members.append({"steam_id": member_steam_id, "steam_name": member_steam_name})
