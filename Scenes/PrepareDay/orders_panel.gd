class_name OrdersPanel
extends VBoxContainer

# Emitted when the player selects / deselects an order.
signal order_selection_changed(order: Order, selected: bool)

# Emitted when the player wants to purchase a slot unlock.
# Parent (e.g. PrepScreen) is responsible for deducting gold and calling
# confirm_slot_purchase() if the transaction succeeds.
signal slot_purchase_requested(slot_idx: int, cost: int)

# Emitted when the player spends a reroll.
signal reroll_used()

const OrderCard := preload("res://Scenes/PrepareDay/OrderCard.tscn")

const SLOT_COSTS   := [0, 0, 50, 120, 220]  # indices 0-4; first two are free
const MAX_SLOTS    := 5
const FLAVOR_TEXT  := {
	1: "You have one order to fill today! Good luck.",
	2: "Word's spreading — you've got one more order slot today. Don't overcommit!",
}
const FLAVOR_DEFAULT := "New orders roll in each morning. Unlock more slots to take on bigger days."

@onready var _flavor_lbl:   Label          = $FlavorLabel
@onready var _card_row:     HBoxContainer  = $CardRow
@onready var _reroll_btn:   Button         = $RerollButton
@onready var _reroll_count: Label          = $RerollCountLabel

var _slots:          Array[OrderSlot] = []
var _cards:          Array[OrderCard] = []
var _selected_idx:   int              = -1
var _rerolls_left:   int              = 0
var _day:            int              = 1


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

# Call this from PrepScreen (or wherever the panel lives) after the day state
# is ready. `orders` should be a pre-generated Array[Order] of active orders
# for this day — the panel doesn't generate them itself.
func setup(day: int, orders: Array, unlocked_count: int, rerolls: int) -> void:
	_day           = day
	_rerolls_left  = rerolls
	_selected_idx  = -1

	_flavor_lbl.text = FLAVOR_TEXT.get(day, FLAVOR_DEFAULT)
	_build_slots(orders, unlocked_count)
	_rebuild_cards()
	_refresh_reroll_ui()


# Called by the parent after it validates and deducts gold.
func confirm_slot_purchase(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= _slots.size():
		return
	var slot = _slots[slot_idx]
	if slot.state != OrderSlot.State.BUYABLE:
		return

	# The order is already in the slot — it was hidden until now.
	slot.state = OrderSlot.State.ACTIVE
	_promote_next_slot(slot_idx + 1)
	_rebuild_cards()


# ---------------------------------------------------------------------------
# Private — slot construction
# ---------------------------------------------------------------------------

func _build_slots(orders: Array, unlocked_count: int) -> void:
	_slots.clear()

	# Active slots first.
	for i in unlocked_count:
		if i < orders.size() and orders[i] != null:
			_slots.append(OrderSlot.new(OrderSlot.State.ACTIVE, orders[i]))
		else:
			# Pool came up short — treat as hidden rather than crash.
			_slots.append(OrderSlot.new(OrderSlot.State.LOCKED_HIDDEN))

	# The remainder up to MAX_SLOTS.
	var remaining = MAX_SLOTS - unlocked_count
	for i in remaining:
		var abs_idx = unlocked_count + i
		var cost    = SLOT_COSTS[abs_idx]

		if i == 0 and _day >= 3:
			# First locked slot after the active ones is BUYABLE on day 3+.
			_slots.append(OrderSlot.new(OrderSlot.State.BUYABLE, null, cost))
		elif i == 1 and _day >= 3:
			# One slot ahead of BUYABLE shows its price but can't be bought yet.
			_slots.append(OrderSlot.new(OrderSlot.State.LOCKED_VISIBLE, null, cost))
		else:
			_slots.append(OrderSlot.new(OrderSlot.State.LOCKED_HIDDEN, null, cost))


func _promote_next_slot(from_idx: int) -> void:
	# Walk forward from from_idx, promoting HIDDEN → VISIBLE → BUYABLE in order.
	for i in range(from_idx, _slots.size()):
		var slot = _slots[i]
		match slot.state:
			OrderSlot.State.LOCKED_HIDDEN:
				slot.state = OrderSlot.State.LOCKED_VISIBLE
				return
			OrderSlot.State.LOCKED_VISIBLE:
				slot.state = OrderSlot.State.BUYABLE
				return


# ---------------------------------------------------------------------------
# Private — card construction
# ---------------------------------------------------------------------------

func _rebuild_cards() -> void:
	for card in _cards:
		card.queue_free()
	_cards.clear()

	for i in _slots.size():
		var card: OrderCard = OrderCard.instantiate()
		_card_row.add_child(card)
		card.setup(_slots[i], i)
		card.selection_toggled.connect(_on_card_selection_toggled)
		card.purchase_requested.connect(_on_card_purchase_requested)
		_cards.append(card)


# ---------------------------------------------------------------------------
# Private — reroll
# ---------------------------------------------------------------------------

func _refresh_reroll_ui() -> void:
	var has_rerolls = _rerolls_left > 0
	_reroll_btn.visible   = _day >= 3
	_reroll_count.visible = _day >= 3
	_reroll_btn.disabled  = not has_rerolls
	_reroll_count.text    = "%d remaining" % _rerolls_left


# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_card_selection_toggled(idx: int) -> void:
	var slot = _slots[idx]
	if slot.state != OrderSlot.State.ACTIVE or slot.order == null:
		return

	var selecting = _selected_idx != idx
	if _selected_idx >= 0:
		_cards[_selected_idx].set_selected(false)
		order_selection_changed.emit(_slots[_selected_idx].order, false)

	if selecting:
		_selected_idx = idx
		_cards[idx].set_selected(true)
		order_selection_changed.emit(slot.order, true)
	else:
		_selected_idx = -1


func _on_card_purchase_requested(idx: int) -> void:
	if idx < 0 or idx >= _slots.size():
		return
	if _slots[idx].state != OrderSlot.State.BUYABLE:
		return
	slot_purchase_requested.emit(idx, _slots[idx].unlock_cost)


func _on_reroll_btn_pressed() -> void:
	if _rerolls_left <= 0:
		return
	_rerolls_left -= 1
	_refresh_reroll_ui()
	reroll_used.emit()
