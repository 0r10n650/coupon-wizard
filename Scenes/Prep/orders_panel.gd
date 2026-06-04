# OrdersPanel — attach to the OrdersPanel node inside upgrade_screen.tscn
# Expects to be a VBoxContainer with %StartShoppingBtn wired in the parent.
# Call build() from _show_orders() in upgrade_screen.gd.

extends VBoxContainer

const MIN_SELECTED = 1

var available_orders: Array = []
var selected_orders: Array = []
var order_cards: Array = [] # OrderCards, index matches available_orders


func build():
	for child in get_children():
		child.queue_free()
	available_orders.clear()
	selected_orders.clear()

	GameState.generate_daily_orders()
	available_orders = GameState.daily_order_pool.duplicate()

	# card row
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var card_row = HBoxContainer.new()
	card_row.add_theme_constant_override("separation", 12)
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	scroll.add_child(card_row)

	for i in range(available_orders.size()):
		var card = _make_order_card(i, available_orders[i])
		order_cards.append(card)
		card_row.add_child(card)

func _make_order_card(idx: int, order: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(160, 240)
	panel.set_meta("order_idx", idx)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	# size badge
	var size_lbl = Label.new()
	size_lbl.text = order["size"].to_upper()
	size_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	size_lbl.add_theme_font_size_override("font_size", 11)
	match order["size"]:
		"small":  size_lbl.add_theme_color_override("font_color", Color.LIGHT_BLUE)
		"medium": size_lbl.add_theme_color_override("font_color", Color.YELLOW)
		"large":  size_lbl.add_theme_color_override("font_color", Color.ORANGE_RED)
	vbox.add_child(size_lbl)

	# category hint — tells player which aisles to visit
	var cat_lbl = Label.new()
	cat_lbl.text = "  ".join(order["categories"])
	cat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cat_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cat_lbl.add_theme_font_size_override("font_size", 10)
	cat_lbl.modulate = Color.GRAY
	vbox.add_child(cat_lbl)

	vbox.add_child(HSeparator.new())

	# line items — scrollable in case of large order
	var item_scroll = ScrollContainer.new()
	item_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(item_scroll)

	var item_list = VBoxContainer.new()
	item_list.add_theme_constant_override("separation", 2)
	item_scroll.add_child(item_list)

	for line in order["line_items"]:
		var row = HBoxContainer.new()

		var item_lbl = Label.new()
		item_lbl.text = line["name"]
		item_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_lbl.add_theme_font_size_override("font_size", 11)
		row.add_child(item_lbl)

		var qty_lbl = Label.new()
		qty_lbl.text = "x%d" % line["quantity"]
		qty_lbl.add_theme_font_size_override("font_size", 11)
		qty_lbl.modulate = Color.GRAY
		row.add_child(qty_lbl)

		item_list.add_child(row)

	vbox.add_child(HSeparator.new())

	# reward row
	var reward_row = HBoxContainer.new()

	var reward_icon = TextureRect.new()
	reward_icon.texture = load("res://Assets/gold_coin.png")
	reward_icon.custom_minimum_size = Vector2(16, 16)
	reward_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reward_row.add_child(reward_icon)

	var reward_lbl = Label.new()
	reward_lbl.text = "%d  (+%d)" % [order["reward"], order["reward"] - order["raw_cost"]]
	reward_lbl.add_theme_font_size_override("font_size", 12)
	reward_lbl.add_theme_color_override("font_color", Color.GOLD)
	reward_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_row.add_child(reward_lbl)

	vbox.add_child(reward_row)

	# select button
	var sel_btn = Button.new()
	sel_btn.text = "Select"
	sel_btn.custom_minimum_size = Vector2(0, 32)
	sel_btn.pressed.connect(func(): _toggle_selection(idx))
	vbox.add_child(sel_btn)

	return panel

func _toggle_selection(idx: int):
	if idx in selected_orders:
		selected_orders.erase(idx)
		_set_card_selected(idx, false)
	elif selected_orders.size() < GameState.max_orders:
		selected_orders.append(idx)
		_set_card_selected(idx, true)

	GameState.confirm_orders(selected_orders)  # keep active_orders in sync as player clicks
	
	# bubble the count up to the upgrade screen
	var upgrade_screen = get_tree().current_scene
	upgrade_screen._update_order_count(selected_orders.size())

func _set_card_selected(idx: int, selected: bool):
	if idx >= order_cards.size():
		return
	var card = order_cards[idx]
	card.modulate = Color(0.6, 1.0, 0.6) if selected else Color.WHITE

	# update the button text on the card
	var btn = card.get_node_or_null("VBoxContainer/Button") # fallback
	# find the select button by iterating — avoids brittle path dependency
	for child in card.get_child(0).get_children():
		if child is Button:
			child.text = "Deselect" if selected else "Select"
