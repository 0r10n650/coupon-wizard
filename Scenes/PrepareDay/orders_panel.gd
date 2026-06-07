extends VBoxContainer

@onready var _order_holder: HBoxContainer = %OrderHolder

@export var tutorial1: Order
@export var tutorial2: Order


func _ready() -> void:
	pass

func refresh(orders: Array[Order], unlocked_slots: int) -> void:
	var cards: Array = _order_holder.get_children()
	for i in cards.size():
		var card: OrderCard = cards[i]
		if i >= orders.size():
			card.visible = false
			continue
		card.visible = true
		card.setup(orders[i], i >= unlocked_slots)
