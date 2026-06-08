extends VBoxContainer
class_name OrdersPanel

signal order_selection_changed(order: Order, selected: bool)
signal order_slot_purchased()

@onready var _flavor_lbl: Label = %FlavorLabel
@onready var _order_holder: HBoxContainer = %OrderHolder
@onready var _cards: Array[OrderCard] = [%OrderCard1, %OrderCard2, %OrderCard3, %OrderCard4, %OrderCard5]
@onready var _btns: Array[Button] = [%SelectBtn1, %SelectBtn2, %SelectBtn3, %SelectBtn4, %SelectBtn5]
@onready var _reroll_btn: Button = %RerollButton

@export var tutorial1: Order
@export var tutorial2: Order


func _ready() -> void:
	_flavor_lbl.text = GameState.pending_order_text
	for i in _btns.size():
		_btns[i].pressed.connect(_on_select_pressed.bind(i))
	refresh()

func refresh() -> void:
	var pool: Array[Order] = GameState.daily_order_pool
	var unlocked: int = GameState.get_unlocked_order_slots()
	var gold_icon = preload("res://Assets/gold_coin.png")

	# Update cards with real order data.
	for i in _cards.size():
		# No order exists for this slot.
		if i >= pool.size():
			_cards[i].lock_empty()
			_btns[i].visible = false
		else:
			var is_locked = i >= unlocked
			_cards[i].setup(pool[i], is_locked)
			if is_locked:
				_cards[i].set_selected(false)
			else:
				_cards[i].set_selected(GameState.active_orders.has(pool[i]))

			if not is_locked:
				_btns[i].visible = true
				_btns[i].text = "Deselect" if _cards[i].is_selected() else "Select"
				_btns[i].icon = null
				_btns[i].disabled = false
			elif i == unlocked:
				_btns[i].visible = true
				var cost = GameState.get_order_slot_cost(i)
				_btns[i].text = "Unlock %d" % cost
				_btns[i].icon = gold_icon
				_btns[i].expand_icon = true
				_btns[i].add_theme_constant_override("icon_max_width", 16)
				_btns[i].disabled = GameState.gold < cost
			else:
				_btns[i].visible = false

	var rerolls := GameState.rerolls_remaining
	_reroll_btn.text = "↺ x%d" % rerolls
	_reroll_btn.disabled = rerolls <= 0

func _on_select_pressed(slot_idx: int) -> void:
	var unlocked: int = GameState.get_unlocked_order_slots()
	if slot_idx >= unlocked:
		if slot_idx == unlocked:
			var cost = GameState.get_order_slot_cost(slot_idx)
			if GameState.purchase_order_slot(slot_idx, cost):
				refresh()
				order_slot_purchased.emit()
		return

	var card := _cards[slot_idx]
	var order := GameState.daily_order_pool[slot_idx]
	var selecting := not card.is_selected()
	card.set_selected(selecting)
	_btns[slot_idx].text = "Deselect" if selecting else "Select"
	order_selection_changed.emit(order, selecting)
