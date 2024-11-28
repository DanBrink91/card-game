class_name Buff
extends Control

@onready var stack_label: Label = $StackLabel
@onready var buff_texture: TextureRect = $BuffTexture
@onready var tooltip = $tooltip
@onready var tooltip_text_label = $tooltip/PanelContainer/RichTextLabel

var buff: BaseBuff

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mouse_entered.connect(on_mouse_over)
	mouse_exited.connect(on_mouse_exit)

func set_buff(new_buff: BaseBuff) -> void:
	if not is_node_ready():
		await ready
	buff = new_buff
	tooltip_text_label.text = new_buff.description
	buff_texture.texture = new_buff.icon
	update()

func update() -> void:
	if buff:
		stack_label.text = str(buff.stacks)

func on_mouse_over() -> void:
	tooltip.visible = true
	z_index = RenderingServer.CANVAS_ITEM_Z_MAX

func on_mouse_exit() -> void:
	tooltip.visible = false
	z_index = 0
