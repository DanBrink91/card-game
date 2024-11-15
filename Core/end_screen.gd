extends Control

@export var stats_to_show: Array[Dictionary] = [
	{"name": "Player", "field": "name"},
	{"name": "Damage Dealt", "field": "damage_done"},
	{"name": "Max Damage Dealt", "field": "max_damage_done"},
	{"name": "Damage Taken", "field": "damage_taken"},
	{"name": "Max Damage Taken", "field": "max_damage_taken"},
	{"name": "Times Damage Taken", "field": "times_damage_taken"},
	{"name": "Mana Spent", "field": "mana_spent"},
	{"name": "Cards Played", "field": "cards_played"},
	{"name": "Mana Unspent", "field": "mana_unspent"},
	{"name": "Money Spent", "field": "money_spent"},
	{"name": "Cards Bought", "field": "cards_bought"},
	{"name": "Money Unspent", "field": "money_unspent"},
	{"name": "Turns Taken", "field": "turns_taken"}
] 

@onready var grid_container = $GridContainer

var victory: bool = true
func _ready() -> void:
	pass

func create_table(stats: Dictionary) -> void:
	await ready
	grid_container.columns = stats.size() + 1

	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color.DARK_OLIVE_GREEN
	
	var even_style = StyleBoxFlat.new()
	even_style.bg_color = Color.SEA_GREEN
	
	var odd_style = StyleBoxFlat.new()
	odd_style.bg_color = Color.WEB_GREEN
	
	var is_even := true	
	for stat in stats_to_show:
		add_container(stat.name, header_style)	
		for player_name in stats:
			var player = stats[player_name]
			add_container(str(player[stat.field]), even_style if is_even else odd_style)
			is_even = !is_even
		

func add_container(text: String, style: StyleBox) -> void:
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(45, 5)
	container.add_theme_stylebox_override("panel", style)
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(label)
	grid_container.add_child(container)
