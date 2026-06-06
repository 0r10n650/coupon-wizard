class_name OrderCard
extends Control

# Emitted when the player clicks Select / Deselect on an ACTIVE card.
signal selection_toggled(idx: int)

# Emitted when the player clicks the buy button on a BUYABLE card.
signal purchase_requested(idx: int)

@onready var _bg_rect:      TextureRect  = %BgRect
@onready var _lock_overlay: Control      = %LockOverlay
@onready var _lock_icon:    TextureRect  = %LockIcon
@onready var _cost_label:   Label        = %CostLabel
@onready var _content:      Control      = %Content
@onready var _title_lbl:    Label        = %TitleLabel
@onready var _item_list:    VBoxContainer = %ItemList
@onready var _reward_lbl:   Label        = %RewardLabel
@onready var _select_btn:   Button       = %SelectButton
@onready var _buy_btn:      Button       = %BuyButton

var _slot_idx: int = -1


func setup(slot: OrderSlot, idx: int) -> void:
	_slot_idx = idx
	_apply_state(slot)


func set_selected(selected: bool) -> void:
	modulate = Color(0.65, 1.0, 0.65) if selected else Color.WHITE
	_select_btn.text = "Deselect" if selected else "Select"


# ---------------------------------------------------------------------------
# Private
# ---------------------------------------------------------------------------

func _apply_state(slot: OrderSlot) -> void:
	# Reset first so no stale state leaks between calls.
	modulate        = Color.WHITE
	_lock_overlay.visible = false
	_content.visible      = false
	_buy_btn.visible      = false
	_select_btn.visible   = false
	mouse_default_cursor_shape = Control.CURSOR_ARROW

	match slot.state:
		OrderSlot.State.ACTIVE:
			if slot.order == null:
				push_error("OrderCard: ACTIVE slot has null order at idx %d" % _slot_idx)
				return
			_content.visible    = true
			_select_btn.visible = true
			_populate_order(slot.order)

		OrderSlot.State.BUYABLE:
			_lock_overlay.visible = true
			_buy_btn.visible      = true
			_cost_label.text      = "%d g" % slot.unlock_cost
			_cost_label.visible   = true
			_lock_icon.visible    = true
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		OrderSlot.State.LOCKED_VISIBLE:
			_lock_overlay.visible = true
			_cost_label.text      = "%d g" % slot.unlock_cost
			_cost_label.visible   = true
			_lock_icon.visible    = true
			modulate              = Color(0.55, 0.55, 0.60, 0.85)

		OrderSlot.State.LOCKED_HIDDEN:
			_lock_overlay.visible = true
			_cost_label.visible   = false
			_lock_icon.visible    = false
			modulate              = Color(0.35, 0.35, 0.40, 0.7)


func _populate_order(order: Order) -> void:
	_title_lbl.text = order.title

	match order.difficulty:
		Order.Difficulty.EASY:   _title_lbl.add_theme_color_override("font_color", Color.LIGHT_BLUE)
		Order.Difficulty.MEDIUM: _title_lbl.add_theme_color_override("font_color", Color.YELLOW)
		Order.Difficulty.HARD:   _title_lbl.add_theme_color_override("font_color", Color.ORANGE_RED)

	for child in _item_list.get_children():
		child.queue_free()

	for ingredient in order.line_items:
		var row      = HBoxContainer.new()
		var name_lbl = Label.new()
		var qty_lbl  = Label.new()

		name_lbl.text = ingredient.name
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_size_override("font_size", 10)

		qty_lbl.text = "x%d" % order.line_items[ingredient]
		qty_lbl.add_theme_font_size_override("font_size", 10)
		qty_lbl.modulate = Color(0.6, 0.6, 0.6)

		row.add_child(name_lbl)
		row.add_child(qty_lbl)
		_item_list.add_child(row)

	var profit = order.reward() - order.raw_cost()
	_reward_lbl.text = "%d g  (+%d)" % [order.reward(), profit]


# ---------------------------------------------------------------------------
# Signal handlers (connected in the scene)
# ---------------------------------------------------------------------------

func _on_select_btn_pressed() -> void:
	selection_toggled.emit(_slot_idx)


func _on_buy_btn_pressed() -> void:
	purchase_requested.emit(_slot_idx)
