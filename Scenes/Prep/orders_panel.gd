# Attached to OrdersPanel.
# Build from _show_orders() in upgrade_screen.gdOrdersPanel — attach to the OrdersPanel node inside upgrade_screen.tscn

extends VBoxContainer

const MIN_SELECTED = 1

var available_orders: Array = []
var selected_orders: Array = []
var order_cards: Array = [] # OrderCards, index matches available_orders


func build():
	# capture selection state before wiping anything
	var prev_selected = selected_orders.duplicate()

	for child in get_children():
		child.queue_free()
	available_orders.clear()
	selected_orders.clear()

	GameState.prepare_daily_orders()
	if prev_selected.is_empty() and GameState.current_day <= 2:
		prev_selected = [0]
		
	match GameState.current_day:
		1: _build_day1()
		2: _build_day2()
		_: _build_normal()

	# restore visual selection state against the freshly built cards
	for idx in prev_selected:
		if idx < selected_orders.size():
			selected_orders.append(idx)
			_set_card_selected(idx, true)

	var upgrade_screen = get_tree().current_scene
	upgrade_screen._update_order_count(selected_orders.size())

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


#---Build Orders---#
func _build_day1():
	_add_tutorial_banner(
		"Your first order!",
		"Grab these items and bring them to checkout. Incomplete orders only give a partial refund.",
		Color(0.4, 0.8, 0.4)
	)
	var card = _make_order_card(0, GameState.daily_order_pool[0])
	available_orders.append(card)
	add_child(card)
	
	# auto-confirm — selection restore in build() will handle the visual
	GameState.confirm_orders([0])

func _build_day2():
	_add_tutorial_banner(
		"You can take on more orders — but be careful.",
		"Unfinished orders return only 50% of their item cost. Only take what you can carry.",
		Color(0.9, 0.75, 0.2)
	)

	var card_row = HBoxContainer.new()
	card_row.add_theme_constant_override("separation", 12)
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(card_row)

	for i in range(GameState.daily_order_pool.size()):
		var card = _make_order_card(i, GameState.daily_order_pool[i])
		available_orders.append(card)
		card_row.add_child(card)

	# pre-confirm first order — build() restores the visual after this returns
	GameState.confirm_orders([0])
	
func _build_normal():
	var card_row = HBoxContainer.new()
	card_row.add_theme_constant_override("separation", 12)
	card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(card_row)

	for i in range(GameState.daily_order_pool.size()):
		var card = _make_order_card(i, GameState.daily_order_pool[i])
		available_orders.append(card)
		card_row.add_child(card)

	if int(GameState.get_upgrade_value("order_rerolls")) > 0:
		add_child(_make_reroll_btn())

func _add_tutorial_banner(title_text: String, body_text: String, col: Color):
	var panel = PanelContainer.new()

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", col)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var body = Label.new()
	body.text = body_text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 12)
	body.modulate = Color(0.85, 0.85, 0.85)
	vbox.add_child(body)

	add_child(panel)

func _make_reroll_btn() -> Button:
	var btn = Button.new()
	btn.name = "RerollBtn"
	btn.custom_minimum_size = Vector2(0, 36)

	if GameState.rerolls_remaining > 0:
		btn.text = "Reroll Orders (%d left)" % GameState.rerolls_remaining
		btn.disabled = false
	else:
		btn.text = "No rerolls left"
		btn.disabled = true

	btn.pressed.connect(func():
		GameState.reroll_orders()
		selected_orders.clear()
		build()
	)
	return btn
