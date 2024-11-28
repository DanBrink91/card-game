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
@export var buff_scene: PackedScene

@export var discard_threat: BaseThreat
@export var curse_card: BaseCard
@export var attack_projectile: Texture


@onready var health_label:  RichTextLabel = $HealthLabel
@onready var threat_container = $ThreatContainer
@onready var minion_container = $MinionContainer
@onready var buff_container  = $BuffContainer

@onready var game: Game = get_parent()

@export_category("Stage 1")
@export var stage_one_actions: Array[ENEMY_ACTION]
@export var stage_one_minions: Array[BaseMinion]
@export var stage_one_threats: Array[BaseThreat]

@export_category("Stage 2")
@export var stage_two_actions: Array[ENEMY_ACTION]
@export var stage_two_minions: Array[BaseMinion]
@export var stage_two_threats: Array[BaseThreat]

@export_category("Stage 3")
@export var stage_three_actions: Array[ENEMY_ACTION]
@export var stage_three_minions: Array[BaseMinion]
@export var stage_three_threats: Array[BaseThreat]


var health:int
var damage:int

var turns_taken := 0
var current_stage := 1

var player_name := "Fire Demon"
var is_host: bool = false
var remote_target_index: int = -1

enum ENEMY_ACTION { LIGHT_STRIKE, MEDIUM_STRIKE, HEAVY_STRIKE,
 CURSE_SINGLE, CURSE_ALL, LIGHT_STRIKE_ALL, MEDIUM_STRIKE_ALL,
 HEAVY_STRIKE_ALL, DISCARD_DAMAGE_THREAT, SUMMON_MINION, ADD_THREAT}

var actions : Array[ENEMY_ACTION] = []

var threats: Array = []

var minions: Array

var buffs: Array[BaseBuff]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health = starting_health
	damage = starting_damage
	update_ui()

func setup(player_count: int) -> void:
	health  = starting_health + (player_count - 1) * health_per_player
	stage_one_actions.shuffle()
	stage_one_minions.shuffle()
	stage_one_threats.shuffle()
	
	stage_two_minions.shuffle()
	stage_two_threats.shuffle()
	
	stage_three_minions.shuffle()
	stage_three_threats.shuffle()
	
	for minion in stage_one_minions + stage_two_minions + stage_three_minions:
		minion.set_player_count(player_count)
	for threat in stage_one_threats + stage_two_threats + stage_three_threats:
		threat.set_player_count(player_count)
	actions = stage_one_actions

func take_damage(amount: int, source: Player) -> void:
	for buff in buffs:
		amount = buff.on_damage_taking(source, amount)
	update_buffs()
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
	for buff in buffs:
		await buff.on_start_turn()
	update_buffs()
	# Handle any active threats
	var threats_to_remove = []
	for threat: Threat in threats:
		threat.turns_left -= 1
		if threat.turns_left <= 0:
			await threat.complete(game)
			threats_to_remove.append(threat)
		else:
			threat.update_ui()
	
	for remove in threats_to_remove:
		threats.erase(remove)
	
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
			await curse_all()
		ENEMY_ACTION.LIGHT_STRIKE_ALL:
			await damage_all(damage)
		ENEMY_ACTION.MEDIUM_STRIKE_ALL:
			await damage_all(damage + 1)
		ENEMY_ACTION.HEAVY_STRIKE_ALL:
			await damage_all(damage + 3)
		ENEMY_ACTION.ADD_THREAT:
			if current_stage == 1:
				await add_threat(stage_one_threats.pop_back())
			elif current_stage == 2:
				await add_threat(stage_two_threats.pop_back())
			else:
				await add_threat(stage_three_threats.pop_back())
		ENEMY_ACTION.SUMMON_MINION:
			if current_stage == 1:
				await add_minion(stage_one_minions.pop_back())
			elif current_stage == 2:
				await add_minion(stage_two_minions.pop_back())
			else:
				await add_minion(stage_three_minions.pop_back())
	
	end_turn()

func single_target_damage(damage: int) -> void:
	var target := await pick_target()
	if target == null:
		print("Players lose")
		# There are no alive targets the bad guy as won...
		return
	
	var calculated_damage: int = damage
	for buff in buffs:
		calculated_damage = buff.on_damage_dealing(target, calculated_damage)
	update_buffs()
	var sprite = Sprite2D.new()
	sprite.texture = attack_projectile
	sprite.global_position = global_position
	sprite.rotate(90)
	sprite.scale += (calculated_damage - 1) * Vector2(0.75, 0.75) # Scale sprite 0.25 more for every damage
	get_tree().root.add_child(sprite)
	
	var tween = get_tree().create_tween()
	tween.tween_property(sprite, "global_position", target.global_position, 1.5)
	await tween.finished
	sprite.queue_free()
	target.take_damage(calculated_damage)

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

func curse_all() -> void:
	for target: Player in game.players:
		var sprite = Sprite2D.new()
		sprite.texture = attack_projectile
		sprite.global_position = global_position
		sprite.rotate(90)
		sprite.modulate = Color(0, 0, 1)
		get_tree().root.add_child(sprite)
		
		var tween = get_tree().create_tween()
		tween.tween_property(sprite, "global_position", target.global_position, 0.5)
		await tween.finished
		sprite.queue_free()
		
		target.add_card(curse_card, Player.CARD_LOCATIONS.DISCARD)

func damage_all(damage: int) -> void:
	for target: Player in game.players.filter(func(player: Player): return player.life > 0):
		var calculated_damage:int = damage
		for buff in buffs:
			calculated_damage = buff.on_damage_dealing(target, calculated_damage)
		update_buffs()
		
		var sprite = Sprite2D.new()
		sprite.texture = attack_projectile
		sprite.global_position = global_position
		sprite.rotate(90)
		sprite.scale += (damage - 1) * Vector2(0.75, 0.75) # Scale sprite 0.25 more for every damage
		get_tree().root.add_child(sprite)
		
		var tween = get_tree().create_tween()
		tween.tween_property(sprite, "global_position", target.global_position, 0.5)
		await tween.finished
		sprite.queue_free()
		target.take_damage(damage)

func end_turn() -> void:
	print("Enemy Turn End")
	for buff in buffs:
		await buff.on_end_turn()
	update_buffs()
	turns_taken += 1
	turn_ended.emit()

func decide_action() -> ENEMY_ACTION:
	if actions.size() <= 0:
		if current_stage == 1:
			actions = stage_two_actions
			current_stage += 1
		elif current_stage == 2:
			actions = stage_three_actions
			current_stage += 1
		elif current_stage == 3:
			actions = [ENEMY_ACTION.HEAVY_STRIKE_ALL]
		actions.shuffle()
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

func add_buff(buff: BaseBuff, stacks: int) -> void:
	var new_buff := true
	print("adding buff, buffs length: %d " % buffs.size())
	for existing_buff in buffs:
		#print("Comparing existing %s to new %s" % [existing_buff.get_script(), buff.get])
		if existing_buff.get_script() == buff.get_script():
			print("Found existing buff, adding stacks")
			new_buff = false
			existing_buff.stacks += stacks
			update_buffs()
			break
	
	if new_buff:
		print("NEW BUFF: %s" % buff.get_class())
		var new_buff_obj: BaseBuff = buff.duplicate()
		new_buff_obj.owner = self
		var buff_ui: Buff = buff_scene.instantiate()
		new_buff_obj.stacks = stacks
		buff_ui.set_buff(new_buff_obj)
		buffs.append(new_buff_obj)
		buff_container.add_child(buff_ui)

func update_buffs() -> void:
	var buff_index := 0
	while buff_index < buffs.size():
		var buff_ui: Buff = buff_container.get_child(buff_index)
		if buffs[buff_index].expired():
			print("removing buff")
			buffs.remove_at(buff_index)
			buff_container.remove_child(buff_ui)
			buff_ui.queue_free()
		else:
			buff_ui.update()
			buff_index += 1
