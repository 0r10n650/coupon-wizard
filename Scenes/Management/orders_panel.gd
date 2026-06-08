extends VBoxContainer
class_name OrdersPanel

signal order_selection_changed(order: Order, selected: bool)

@onready var _flavor_lbl: Label = %FlavorLabel
@onready var _order_holder: HBoxContainer = %OrderHolder
@onready var _cards: Array[OrderCard] = [%OrderCard1, %OrderCard2, %OrderCard3, %OrderCard4, %OrderCard5]
@onready var _btns: Array[Button] = [%SelectBtn1, %SelectBtn2, %SelectBtn3, %SelectBtn4, %SelectBtn5]
@onready var _reroll_btn: Button = %RerollButton

@export var tutorial1: Order
@export var tutorial2: Order


func _ready() -> void:
	for i in _btns.size():
		_btns[i].pressed.connect(_on_select_pressed.bind(i))
	refresh()

func refresh() -> void:
	var pool: Array[Order] = GameState.daily_order_pool
	var unlocked: int = GameState.get_unlocked_order_slots()

	# Update cards with real order data.
	for i in _cards.size():
		# No order exists for this slot.
		if i >= pool.size():
			_cards[i].lock_empty()
		else:
			_cards[i].setup(pool[i], i >= unlocked)
			_cards[i].set_selected(GameState.active_orders.has(pool[i]))

		# Update buttons in regards to current state.
		var selectable := i < unlocked and i < pool.size()
		_btns[i].visible = selectable
		if selectable:
			_btns[i].text = "Deselect" if _cards[i].is_selected() else "Select"

	var rerolls := GameState.rerolls_remaining
	_reroll_btn.text = "↺ x%d" % rerolls
	_reroll_btn.disabled = rerolls <= 0

func _on_select_pressed(slot_idx: int) -> void:
	var card := _cards[slot_idx]
	var order := GameState.daily_order_pool[slot_idx]
	var selecting := not card.is_selected()
	card.set_selected(selecting)
	_btns[slot_idx].text = "Deselect" if selecting else "Select"
	order_selection_changed.emit(order, selecting)
