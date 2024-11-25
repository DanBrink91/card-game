class_name Enemy
extends Node2D

signal turn_ended
signal enemy_death
signal enemy_take_damage(amount: int, source: Player)



@export var starting_health: int = 40
@export var health_per_player: int = 30

@export var starting_damage: int = 1
@export var max_threats: int = 3

@export var threat_scene: PackedScene
@export var minion_scene: PackedScene

@export var discard_threat: BaseThreat
@export var curse_card: BaseCard
@export var attack_projectile: Texture

@export var first_minions: Array[BaseMinion]

@onready var health_label:  RichTextLabel = $HealthLabel
@onready var threat_container = $ThreatContainer
@onready var minion_container = $MinionContainer
@onready var game: Game = get_parent()

var health:int
var damage:int

var turns_taken := 0

var player_name := "Fire Demon"
var is_host: bool = false
var remote_target_index: int = -1

enum ENEMY_ACTION { LIGHT_STRIKE, MEDIUM_STRIKE, HEAVY_STRIKE,
 CURSE_SINGLE, CURSE_ALL, LIGHT_STRIKE_ALL, MEDIUM_STRIKE_ALL,
 HEAVY_STRIKE_ALL, DISCARD_DAMAGE_THREAT, SUMMON_MINION}

var actions : Array[ENEMY_ACTION] = []

var threats: Array = []

var minions: Array

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health = starting_health
	damage = starting_damage
	update_ui()
	actions = [ENEMY_ACTION.SUMMON_MINION]

func setup(player_count: int) -> void:
	health  = starting_health + (player_count - 1) * health_per_player

func take_damage(amount: int, source: Player) -> void:
	Util.spawn_floating_text("-" + str(amount), global_position, Vector2(0, -45))
	enemy_take_damage.emit(amount, source)
	health -= amount
	if health <= 0:
		print("Enemy died!")
		enemy_death.emit()
	update_ui()

func update_ui() -> void:
	health_label.text = str(health)

func start_turn() -> void:
	print("Enemy Turn Start")
	# Handle any active threats
	var threats_to_remove = []
	for threat in threats:
		threat.turn_limit -= 1
		if threat.turn_limit <= 0:
			await threat.complete(game)
			threats_to_remove.append(threat)
	# Handle minions
	for minion in minions:
		await minion.take_turn(game)
	
	var action = decide_action()
	match action:
		ENEMY_ACTION.LIGHT_STRIKE:
			await single_target_damage(damage)
		ENEMY_ACTION.MEDIUM_STRIKE:
			await single_target_damage(damage + 1)
		ENEMY_ACTION.HEAVY_STRIKE:
			await single_target_damage(damage + 3)
		ENEMY_ACTION.CURSE_SINGLE:
			await single_target_curse()
		ENEMY_ACTION.CURSE_ALL:
			pass
		ENEMY_ACTION.LIGHT_STRIKE_ALL:
			pass
		ENEMY_ACTION.MEDIUM_STRIKE_ALL:
			pass
		ENEMY_ACTION.HEAVY_STRIKE_ALL:
			pass
		ENEMY_ACTION.DISCARD_DAMAGE_THREAT:
			await add_threat(discard_threat)
		ENEMY_ACTION.SUMMON_MINION:
			await add_minion(first_minions.pick_random())
	
	end_turn()

func single_target_damage(damage: int) -> void:
	var target := await pick_target()
	if target == null:
		print("Players lose")
		# There are no alive targets the bad guy as won...
		return
	
	var sprite = Sprite2D.new()
	sprite.texture = attack_projectile
	sprite.global_position = global_position
	sprite.rotate(90)
	sprite.scale += (damage - 1) * Vector2(0.75, 0.75) # Scale sprite 0.25 more for every damage
	get_tree().root.add_child(sprite)
	
	var tween = get_tree().create_tween()
	tween.tween_property(sprite, "global_position", target.global_position, 1.5)
	await tween.finished
	sprite.queue_free()
	target.take_damage(damage)

func single_target_curse() -> void:
	var target := await pick_target()
	if target == null:
		print("Players lose")
	
	var sprite = Sprite2D.new()
	sprite.texture = attack_projectile
	sprite.global_position = global_position
	sprite.rotate(90)
	sprite.modulate = Color(0, 0, 1)
	get_tree().root.add_child(sprite)
	
	var tween = get_tree().create_tween()
	tween.tween_property(sprite, "global_position", target.global_position, 1.5)
	await tween.finished
	sprite.queue_free()
	
	target.add_card(curse_card, Player.CARD_LOCATIONS.DISCARD)

func end_turn() -> void:
	print("Enemy Turn End")
	turns_taken += 1
	turn_ended.emit()

func decide_action() -> ENEMY_ACTION:
	if actions.size() <= 1:
		var action = actions.pop_back()
		actions = [ENEMY_ACTION.LIGHT_STRIKE, ENEMY_ACTION.MEDIUM_STRIKE, ENEMY_ACTION.HEAVY_STRIKE, ENEMY_ACTION.CURSE_SINGLE]
		actions.shuffle()
		return action
	return actions.pop_back()

func pick_target() -> Player:
	if is_host:
		var alive_players := get_tree().get_nodes_in_group("allies").filter(func(player): return player.life > 0)
		var target = alive_players.pick_random()
		var target_index = get_tree().get_nodes_in_group("allies").find(target)
		GlobalSteam.send_p2p_packet(0, {"type": GlobalSteam.GAME_PACKET_TYPE.GAME_ENEMY_DECIDE, "target_index": target_index})
		return target
	else: # Wait for game packet to decide!
		var players = get_tree().get_nodes_in_group("allies")
		print("Waiting for enemy decide packet...")
		var target_index
		if remote_target_index == -1: # Didnt get a target index, wait for it
			target_index = await game.remote_enemy_decide
		else:
			target_index = remote_target_index # Dont have to wait, set and continue
		remote_target_index = -1 # reset this to -1, which means no target got yet
		players.pick_random() # Garbage, just keep the random in sync
		return players[target_index]

func add_threat(base: BaseThreat) -> void:
	var threat = threat_scene.instantiate() as Threat
	threat.set_threat(base)
	threat.cost_paid.connect(on_threat_paid)
	threat.cost_paidoff.connect(on_local_threat_paidoff)
	threat_container.add_child(threat)
	threats.append(threat)
	# TODO animation or something, for now just delay
	await get_tree().create_timer(2).timeout

func on_threat_paid(player: Player, threat: BaseThreat):
	# Find index of threat in array so we can send packet
	var threat_index: int = 0
	for _threat in threats:
		if _threat.threat == threat:
			print("Found threat")
			break
		threat_index += 1
	
	GlobalSteam.send_p2p_packet(0, 
		{"type": GlobalSteam.GAME_PACKET_TYPE.GAME_ENEMY_THREAT_PAID,
		"threat_index": threat_index}
	)

func on_local_threat_paidoff(threat: BaseThreat) -> void:
	# Find index of threat in array so we can send packet
	var threat_index: int = 0
	for _threat in threats:
		if _threat.threat == threat:
			print("Found threat")
			break
		threat_index += 1
	
	threats[threat_index].queue_free()
	threats.remove_at(threat_index)
	
func on_remote_threat_paid(player: Player, threat_index: int):
	var threat : BaseThreat = threats[threat_index].threat
	await threat.pay(player)
	
	# TODO Animation??
	if threat.is_paid():
		threats[threat_index].queue_free()
		threats.remove_at(threat_index)

func add_minion(base: BaseMinion) -> void:
	var minion = minion_scene.instantiate() as Minion
	minion.set_minion(base)
	minion.minion_death.connect(remove_minion.bind(base, minion))
	minion_container.add_child(minion)
	minions.append(base)
	minion.add_to_group("enemies")
	#minion.take_damage.connect()
	# TODO animation or something, for now just delay
	await get_tree().create_timer(2).timeout

func remove_minion(base: BaseMinion, object) -> void:
	minions.erase(base)
	object.queue_free()
