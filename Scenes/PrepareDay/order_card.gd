@tool
class_name OrderCard
extends Control

var _order: Order = null
var _pending_args: Array = []

@onready var _lock: TextureRect = %LockImage
@onready var _text_container: VBoxContainer = %TextContainer
@onready var _title: Label = $MarginContainer/VBoxContainer/OrderTitle
@onready var _slot1: HBoxContainer = $MarginContainer/VBoxContainer/ItemContainer
@onready var _slot2: HBoxContainer = $MarginContainer/VBoxContainer/ItemContainer2
@onready var _slot3: HBoxContainer = $MarginContainer/VBoxContainer/ItemContainer3
@onready var _item1: Label  = $MarginContainer/VBoxContainer/ItemContainer/Item1
@onready var _count1: Label = $MarginContainer/VBoxContainer/ItemContainer/Count1
@onready var _item2: Label  = $MarginContainer/VBoxContainer/ItemContainer2/Item2
@onready var _count2: Label = $MarginContainer/VBoxContainer/ItemContainer2/Count2
@onready var _item3: Label  = $MarginContainer/VBoxContainer/ItemContainer3/Item3
@onready var _count3: Label = $MarginContainer/VBoxContainer/ItemContainer3/Count3
@onready var _reward: Label = $MarginContainer/VBoxContainer/RewardContainer/RewardLabel


func _ready() -> void:
	if not _pending_args.is_empty():
		_populate_order(_pending_args[0], _pending_args[1])
		_pending_args.clear()

func setup(order: Order, is_locked: bool = false) -> void:
	if not is_node_ready():
		_pending_args = [order, is_locked]
		return
	_populate_order(order, is_locked)
	
func set_selected(selected: bool) -> void:
	modulate = Color(0.65, 1.0, 0.65) if selected else Color.WHITE

func _populate_order(order: Order, is_locked: bool) -> void:
	_lock.visible = is_locked
	if is_locked:
		_text_container.visible = false
		modulate = Color("#1c1c1c")
		return
	_order = order
	_title.text = order.title

	var slots: Array = [
		[_slot1, _item1, _count1],
		[_slot2, _item2, _count2],
		[_slot3, _item3, _count3],
	]

	# Hide all slots first, then fill from the top.
	for row in slots:
		row[0].visible = false

	var idx := 0
	for ingredient: Ingredient in order.line_items:
		if idx >= slots.size():
			break
		var row = slots[idx]
		row[0].visible = true
		row[1].text = ingredient.name
		row[2].text = "x%d" % order.line_items[ingredient]
		idx += 1

	_reward.text = "🪙%d (+%d)" % [order.raw_cost(), order.reward() - order.raw_cost()]
