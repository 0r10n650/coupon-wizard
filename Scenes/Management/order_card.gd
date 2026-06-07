class_name OrderCard
extends TextureRect

var _order: Order = null
var _selected: bool = false

@onready var _lock: TextureRect         = $MarginContainer/LockImage
@onready var _text_container: VBoxContainer = $MarginContainer/TextContainer
@onready var _title: Label              = $MarginContainer/TextContainer/OrderTitle
@onready var _slot1: HBoxContainer      = $MarginContainer/TextContainer/ItemContainer
@onready var _slot2: HBoxContainer      = $MarginContainer/TextContainer/ItemContainer2
@onready var _slot3: HBoxContainer      = $MarginContainer/TextContainer/ItemContainer3
@onready var _item1: Label              = $MarginContainer/TextContainer/ItemContainer/Item1
@onready var _count1: Label             = $MarginContainer/TextContainer/ItemContainer/Count1
@onready var _item2: Label              = $MarginContainer/TextContainer/ItemContainer2/Item2
@onready var _count2: Label             = $MarginContainer/TextContainer/ItemContainer2/Count2
@onready var _item3: Label              = $MarginContainer/TextContainer/ItemContainer3/Item3
@onready var _count3: Label             = $MarginContainer/TextContainer/ItemContainer3/Count3
@onready var _reward: Label             = $MarginContainer/TextContainer/RewardContainer/RewardLabel


func setup(order: Order, is_locked: bool = false) -> void:
	_populate_order(order, is_locked)

func is_selected() -> bool:
	return _selected

func set_selected(selected: bool) -> void:
	_selected = selected
	modulate = Color("#7df47a") if selected else Color.WHITE

func lock_empty() -> void:
	_populate_order(null, true)
	
func _populate_order(order: Order, is_locked: bool) -> void:
	_lock.visible = is_locked
	_text_container.visible = not is_locked
	modulate = Color("#1c1c1c") if is_locked else Color.WHITE

	if is_locked:
		return

	_order = order
	_title.text = order.title

	var item_rows: Array = [
		[_slot1, _item1, _count1],
		[_slot2, _item2, _count2],
		[_slot3, _item3, _count3],
	]

	for row in [_slot1, _slot2, _slot3]:
		row.visible = false

	var idx = 0
	for ingredient: Ingredient in order.line_items:
		if idx >= item_rows.size():
			print("Order is too large to display!")
			break
		var row = item_rows[idx]
		row[0].visible = true
		row[1].text = ingredient.name
		row[2].text = "x%d" % order.line_items[ingredient]
		idx += 1

	_reward.text = "%d (+%d)" % [order.raw_cost(), order.reward() - order.raw_cost()]
