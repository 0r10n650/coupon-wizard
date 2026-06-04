extends Control

@onready var gold_label = $Panel/VBoxContainer/Header/GoldContainer/GoldLabel
@onready var upgrades_container = $Panel/VBoxContainer/ScrollContainer/UpgradesList
@onready var coupon_container = $Panel/VBoxContainer/CouponSection

var gold_icon = preload("res://Assets/gold_coin.png")

var upgrade_definitions = [
	{"id": "coupon_time", "name": "Maze Time Limit", "desc": "Increases time to complete mazes."},
	{"id": "coupon_retries", "name": "Coupon Retries", "desc": "Allows retrying a failed coupon."},
	{"id": "coupon_rect_percent", "name": "Rectangle Coupon %", "desc": "Increases Rectangle coupon discount."},
	{"id": "coupon_circle_percent", "name": "Circle Coupon %", "desc": "Increases Circle coupon discount."},
	{"id": "coupon_hexagon_percent", "name": "Hexagon Coupon %", "desc": "Increases Hexagon coupon discount."},
	{"id": "coupon_triangle_percent", "name": "Triangle Coupon %", "desc": "Increases Triangle coupon discount."},
	{"id": "coupon_star_percent", "name": "Star Coupon %", "desc": "Increases Star coupon discount."},
	{"id": "coupon_gear_percent", "name": "Gear Coupon %", "desc": "Increases Gear coupon discount."},
	{"id": "shopping_time", "name": "Shopping Time", "desc": "Increases the time limit for shopping."},
	{"id": "coupon_slots", "name": "Coupon Slots", "desc": "Unlocks an additional coupon slot (max 5)."},
	{"id": "checkout_time", "name": "Checkout Time", "desc": "Increases global time limit for checkout."},
	{"id": "checkout_vision", "name": "Checkout Vision", "desc": "Allows seeing an extra upcoming arrow."},
]

func _ready():
	refresh_ui()

func refresh_ui():
	gold_label.text = str(int(GameState.gold))
	
	for child in upgrades_container.get_children():
		child.queue_free()
		
	for upg in upgrade_definitions:
		var item = create_upgrade_item(upg)
		upgrades_container.add_child(item)

	_refresh_coupon_section()

func create_upgrade_item(def: Dictionary) -> Control:
	var hbox = HBoxContainer.new()
	
	var label_vbox = VBoxContainer.new()
	label_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label = Label.new()
	var current_level = GameState.upgrades.get(def["id"], 0)
	name_label.text = "%s (Lv %d)" % [def["name"], current_level]
	
	var desc_label = Label.new()
	desc_label.text = def["desc"]
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.modulate = Color.GRAY
	
	label_vbox.add_child(name_label)
	label_vbox.add_child(desc_label)
	
	var buy_btn = Button.new()
	var cost = GameState.get_upgrade_cost(def["id"])
	buy_btn.text = " %d" % int(cost)
	buy_btn.icon = gold_icon
	buy_btn.expand_icon = true
	buy_btn.add_theme_constant_override("icon_max_width", 24)
	buy_btn.disabled = not GameState.can_afford(def["id"])
	
	buy_btn.pressed.connect(func(): _on_buy_pressed(def["id"]))
	
	hbox.add_child(label_vbox)
	hbox.add_child(buy_btn)
	
	# Add spacing separator
	var sep = HSeparator.new()
	sep.modulate = Color(1,1,1,0) # transparent
	
	var outer_vbox = VBoxContainer.new()
	outer_vbox.add_child(hbox)
	outer_vbox.add_child(sep)
	
	return outer_vbox

func _on_buy_pressed(upgrade_id: String):
	if GameState.purchase_upgrade(upgrade_id):
		refresh_ui()

func _refresh_coupon_section():
	for child in coupon_container.get_children():
		child.queue_free()

	var title = Label.new()
	title.text = "Coupon Loadout"
	title.add_theme_font_size_override("font_size", 16)
	coupon_container.add_child(title)

	var slots_row = HBoxContainer.new()
	slots_row.add_theme_constant_override("separation", 8)
	coupon_container.add_child(slots_row)

	for i in range(GameState.coupon_slots):
		slots_row.add_child(_make_slot_card(i))

	coupon_container.add_child(HSeparator.new())

	var collection_lbl = Label.new()
	collection_lbl.text = "Your Coupons"
	collection_lbl.add_theme_font_size_override("font_size", 13)
	coupon_container.add_child(collection_lbl)

	var unlocked = GameState.get_unlocked_coupons()
	if unlocked.is_empty():
		var none_lbl = Label.new()
		none_lbl.text = "None unlocked yet."
		none_lbl.modulate = Color.GRAY
		coupon_container.add_child(none_lbl)
	else:
		var collection_row = HBoxContainer.new()
		collection_row.add_theme_constant_override("separation", 8)
		for c in unlocked:
			collection_row.add_child(_make_collection_card(c))
		coupon_container.add_child(collection_row)


func _make_slot_card(slot_idx: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(110, 120)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)

	var header = Label.new()
	header.text = "Slot %d" % (slot_idx + 1)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)

	var equipped_id = ""
	if slot_idx < GameState.equipped_coupon_ids.size():
		equipped_id = GameState.equipped_coupon_ids[slot_idx]

	if equipped_id != "":
		var coupon = _find_coupon(equipped_id)
		if coupon:
			var n = Label.new()
			n.text = coupon["name"]
			n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			n.add_theme_font_size_override("font_size", 12)
			vbox.add_child(n)

			var d = Label.new()
			d.text = coupon["description"]
			d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			d.add_theme_font_size_override("font_size", 10)
			vbox.add_child(d)

			var remove_btn = Button.new()
			remove_btn.text = "Remove"
			remove_btn.pressed.connect(func():
				GameState.unequip_coupon(slot_idx)
				GameState.save_game()
				_refresh_coupon_section()
			)
			vbox.add_child(remove_btn)
	else:
		var empty_lbl = Label.new()
		empty_lbl.text = "(empty)"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.modulate = Color.GRAY
		vbox.add_child(empty_lbl)

	panel.add_child(vbox)
	return panel


func _make_collection_card(coupon: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(110, 140)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)

	var name_lbl = Label.new()
	name_lbl.text = coupon["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(name_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = coupon["description"]
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_size_override("font_size", 10)
	vbox.add_child(desc_lbl)

	var tier_lbl = Label.new()
	tier_lbl.text = coupon["tier"].to_upper()
	tier_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	match coupon["tier"]:
		"low":    tier_lbl.add_theme_color_override("font_color", Color.LIGHT_BLUE)
		"medium": tier_lbl.add_theme_color_override("font_color", Color.YELLOW)
		"high":   tier_lbl.add_theme_color_override("font_color", Color.ORANGE_RED)
	vbox.add_child(tier_lbl)

	var open_slot = _find_open_slot(coupon["id"])
	var equip_btn = Button.new()
	if open_slot == -1:
		equip_btn.text = "Slots full"
		equip_btn.disabled = true
	else:
		equip_btn.text = "→ Slot %d" % (open_slot + 1)
		equip_btn.pressed.connect(func():
			GameState.equip_coupon(coupon["id"], open_slot)
			GameState.save_game()
			_refresh_coupon_section()
		)
	vbox.add_child(equip_btn)

	panel.add_child(vbox)
	return panel


func _find_open_slot(coupon_id: String) -> int:
	for i in range(GameState.coupon_slots):
		var current = ""
		if i < GameState.equipped_coupon_ids.size():
			current = GameState.equipped_coupon_ids[i]
		if current == "" or current == coupon_id:
			return i
	return -1


func _find_coupon(id: String) -> Dictionary:
	for c in GameState.ALL_COUPONS:
		if c["id"] == id:
			return c
	return {}


func _on_close_button_pressed():
	var player = get_tree().current_scene.get_node_or_null("Player")
	if player and player.has_method("set_movement_locked"):
		player.set_movement_locked(false)
	queue_free()
