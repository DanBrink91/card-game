class_name Shop_Card
extends Control

signal card_clicked(card_node:Shop_Card)

var card_data: BaseCard = null  # Reference to the base card resource

@onready var card_node: CardNode = $CardNode
@onready var amount_label: Label = $CenterContainer/AmountLabel

@export var stock: int = 8

func _ready() -> void:
	card_node.set_card_data(card_data) 
	card_node.card_double_clicked.connect(_on_card_node_clicked)

func refresh_display():
	amount_label.text = str(stock)
	card_node.refresh_display()

func _on_card_node_clicked(card: CardNode) -> void:
	card_clicked.emit(self)
