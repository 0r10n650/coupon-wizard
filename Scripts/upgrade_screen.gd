extends Control

# top bar
@onready var orders_btn = %OrdersBtn
@onready var upgrades_btn = %UpgradesBtn
@onready var coupons_btn = %CouponsBtn
@onready var start_shopping_btn = %StartShoppingBtn
@onready var order_count_label = %OrderCountLabel

# content panels (only one visible at a time)
@onready var orders_panel = %OrdersPanel
@onready var upgrades_panel = %UpgradesPanel
@onready var coupons_panel = %CouponsPanel

# upgrades list lives inside UpgradesPanel
@onready var upgrades_vbox  = %UpgradesVBox

# -- bottom bar
@onready var day_label   = %DayLabel
@onready var gold_label  = %GoldLabel
@onready var debt_label  = %DebtLabel
@onready var pay_debt_btn = %PayDebtBtn

# -- drag ghost lives here so it renders above everything
@onready var drag_layer  = %DragLayer

# signals
signal gold_changed(new_value: int)
signal debt_changed(new_value: int)

var gold_icon = preload("res://Assets/gold_coin.png")
const COIN    = "[img=16]res://Assets/gold_coin.png[/img]"

const COUPON_IMAGES = {
	"low_pct":    "res://assets/Coupons/circle_coupon.png",
	"low_flat":   "res://assets/Coupons/circle_coupon.png",
	"low_buy10":  "res://assets/Coupons/rectangle_coupon.png",
	"med_pct":    "res://assets/Coupons/hexagon_coupon.png",
	"med_buy5":   "res://assets/Coupons/hexagon_coupon.png",
	"med_double": "res://assets/Coupons/star_coupon.png",
	"high_pct":   "res://assets/Coupons/circle_coupon.png",
	"high_triple":"res://assets/Coupons/gear_coupon.png",
}

var upgrade_definitions = [
	{"id": "coupon_time",             "name": "Maze Time Limit",    "desc": "Increases time to complete mazes."},
	{"id": "coupon_retries",          "name": "Coupon Retries",     "desc": "Allows retrying a failed coupon."},
	{"id": "coupon_rect_percent",     "name": "Rectangle Coupon %", "desc": "Increases Rectangle coupon discount."},
	{"id": "coupon_circle_percent",   "name": "Circle Coupon %",    "desc": "Increases Circle coupon discount."},
	{"id": "coupon_hexagon_percent",  "name": "Hexagon Coupon %",   "desc": "Increases Hexagon coupon discount."},
	{"id": "coupon_triangle_percent", "name": "Triangle Coupon %",  "desc": "Increases Triangle coupon discount."},
	{"id": "coupon_star_percent",     "name": "Star Coupon %",      "desc": "Increases Star coupon discount."},
	{"id": "coupon_gear_percent",     "name": "Gear Coupon %",      "desc": "Increases Gear coupon discount."},
	{"id": "checkout_combo_time",     "name": "Combo Timer",        "desc": "Slows down combo expiration in checkout."},
	{"id": "checkout_shake_reduction","name": "Steady Rhythm",      "desc": "Reduces timer decay acceleration per combo hit."},
	{"id": "checkout_shake_delay",    "name": "Nerves of Steel",    "desc": "Delays the start of timer decay acceleration by more combo hits."},
	{"id": "checkout_bonus_arrow",    "name": "Bonus Arrow Value",  "desc": "Increases money earned for each arrow hit after reaching max combo."},
	{"id": "shopping_time",           "name": "Shopping Time",      "desc": "Increases the time limit for shopping."},
	{"id": "coupon_slots",            "name": "Coupon Slots",       "desc": "Unlocks an additional coupon slot (max 5)."},
	{"id": "orders",                  "name": "Order Slots",        "desc": "Increases how many orders you can take per day (max 5)."},
	{"id": "order_rerolls",           "name": "Order Rerolls",      "desc": "Allows rerolling the order pool once or twice per day."},
]

const SLOT_CARD_SIZE    = Vector2(95, 110)
const COLLECT_CARD_SIZE = Vector2(85, 95)
const SLOT_FONT         = 10
const COLLECT_FONT      = 9

# drag state
var drag_coupon_id:   String  = ""
var drag_source_slot: int     = -1
var drag_ghost:       Control = null
var _hovered_slot:    int     = -1

# built during _build_coupons_panel, used for drag hit-testing
var slot_cards:       Array   = []
var collection_cards: Array   = []


func _ready():
	GameState.save_current_scene(get_tree().current_scene.scene_file_path)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	orders_btn.pressed.connect(_show_orders)
	upgrades_btn.pressed.connect(_show_upgrades)
	coupons_btn.pressed.connect(_show_coupons)
	start_shopping_btn.pressed.connect(_on_start_shopping)
	pay_debt_btn.pressed.connect(_on_pay_debt)

	# start on the orders panel
	_show_orders()
	_update_order_count(0)
	_update_bottom_bar()

	# unlock a few coupons for testing
	if GameState.unlocked_coupon_ids.is_empty():
		GameState.unlock_coupon("low_pct")
		GameState.unlock_coupon("med_double")
		GameState.unlock_coupon("high_triple")


# ── panel switching ─────────────────────────────
func _switch_to(active_btn: Button, active_panel: Control):
	# hide everything
	for panel in [orders_panel, upgrades_panel, coupons_panel]:
		panel.visible = false
	for btn in [orders_btn, upgrades_btn, coupons_btn]:
		btn.modulate = Color(1, 1, 1, 0.55)
	# show active
	active_panel.visible = true
	active_btn.modulate = Color.WHITE

func _show_orders():
	_switch_to(orders_btn, orders_panel)
	orders_panel.build()
	
func _show_upgrades():
	_switch_to(upgrades_btn, upgrades_panel)
	_refresh_upgrades()

func _show_coupons():
	_switch_to(coupons_btn, coupons_panel)
	_build_coupons_panel()

func _update_order_count(count: int):
	order_count_label.text = "%d / %d" % [count, GameState.max_orders]
	if count == 0:
		start_shopping_btn.disabled = true
		start_shopping_btn.tooltip_text = "Select at least one order first"
	else:
		start_shopping_btn.disabled = false
		start_shopping_btn.tooltip_text = "Start your run"

func _update_bottom_bar():
	day_label.text  = "Day: %d" % GameState.current_day
	gold_label.text = "Gold: %s%d" % [COIN, int(GameState.gold)]
	debt_label.text = "Debt: %s%d" % [COIN, int(GameState.debt)]
	pay_debt_btn.disabled = GameState.gold <= 0 or GameState.debt <= 0


# ── upgrades panel ────────────────────────────────────────────

func _refresh_upgrades():
	for child in upgrades_vbox.get_children():
		child.queue_free()
	for def in upgrade_definitions:
		upgrades_vbox.add_child(_make_upgrade_row(def))


func _make_upgrade_row(def: Dictionary) -> Control:
	var hbox = HBoxContainer.new()

	var lv = VBoxContainer.new()
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_lbl = Label.new()
	name_lbl.text = "%s (Lv %d)" % [def["name"], GameState.upgrades.get(def["id"], 0)]

	var desc_lbl = Label.new()
	desc_lbl.text = def["desc"]
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.modulate = Color.GRAY

	lv.add_child(name_lbl)
	lv.add_child(desc_lbl)

	var cost = GameState.get_upgrade_cost(def["id"])
	var btn = Button.new()
	btn.text = " %d" % int(cost)
	btn.icon = gold_icon
	btn.expand_icon = true
	btn.add_theme_constant_override("icon_max_width", 24)
	btn.disabled = not GameState.can_afford(def["id"])
	btn.pressed.connect(func():
		if GameState.purchase_upgrade(def["id"]):
			_refresh_upgrades()
			_update_bottom_bar()
	)

	hbox.add_child(lv)
	hbox.add_child(btn)

	var sep = HSeparator.new()
	sep.modulate = Color(1, 1, 1, 0)

	var outer = VBoxContainer.new()
	outer.add_child(hbox)
	outer.add_child(sep)
	return outer


# ── coupons panel ─────────────────────────────────────────────
# Rebuilt from scratch each time the tab is opened. Since the panel
# is just hidden (not freed) between visits, we clear it first.

func _build_coupons_panel():
	for child in coupons_panel.get_children():
		child.queue_free()
	slot_cards.clear()
	collection_cards.clear()

	# loadout row
	var loadout_lbl = Label.new()
	loadout_lbl.text = "Loadout"
	loadout_lbl.add_theme_font_size_override("font_size", 14)
	loadout_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coupons_panel.add_child(loadout_lbl)

	var loadout_center = CenterContainer.new()
	loadout_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	coupons_panel.add_child(loadout_center)

	var loadout_row = HBoxContainer.new()
	loadout_row.add_theme_constant_override("separation", 8)
	loadout_center.add_child(loadout_row)

	for i in range(5):
		var card = _make_slot_card(i)
		slot_cards.append(card)
		loadout_row.add_child(card)

	coupons_panel.add_child(HSeparator.new())

	# collection grid
	var collection_lbl = Label.new()
	collection_lbl.text = "Collection  (drag to loadout)"
	collection_lbl.add_theme_font_size_override("font_size", 14)
	collection_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coupons_panel.add_child(collection_lbl)

	var grid_center = CenterContainer.new()
	grid_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_center.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	coupons_panel.add_child(grid_center)

	var grid = GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid_center.add_child(grid)

	for coupon in GameState.ALL_COUPONS:
		var card = _make_collection_card(coupon)
		collection_cards.append(card)
		grid.add_child(card)


# ── card builders ─────────────────────────────────────────────

func _make_slot_card(slot_idx: int) -> Control:
	var unlocked = slot_idx < GameState.coupon_slots

	var root = Control.new()
	root.custom_minimum_size = SLOT_CARD_SIZE
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.set_meta("slot_idx", slot_idx)

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(panel)

	if not unlocked:
		root.modulate = Color(0.38, 0.38, 0.38, 0.65)
		_add_centered_label(panel, "Slot %d\n🔒" % (slot_idx + 1), SLOT_FONT)
	else:
		var equipped_id = ""
		if slot_idx < GameState.equipped_coupon_ids.size():
			equipped_id = GameState.equipped_coupon_ids[slot_idx]

		if equipped_id != "":
			var coupon = _find_coupon(equipped_id)
			if coupon:
				_build_image_card(panel, coupon, SLOT_FONT)
			root.gui_input.connect(func(ev): _on_slot_pickup_input(ev, slot_idx))
		else:
			root.modulate = Color(0.7, 0.7, 0.7, 0.5)
			_add_centered_label(panel, "Slot %d\n(empty)" % (slot_idx + 1), SLOT_FONT)

	return root


func _make_collection_card(coupon: Dictionary) -> Control:
	var is_unlocked = coupon["id"] in GameState.unlocked_coupon_ids
	var in_loadout  = coupon["id"] in GameState.equipped_coupon_ids

	var root = Control.new()
	root.custom_minimum_size = COLLECT_CARD_SIZE
	root.set_meta("coupon_id", coupon["id"])

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(panel)

	if is_unlocked:
		_build_image_card(panel, coupon, COLLECT_FONT)
		if in_loadout:
			root.modulate = Color(0.5, 0.5, 0.5, 0.75)
		else:
			root.mouse_filter = Control.MOUSE_FILTER_STOP
			root.gui_input.connect(func(ev): _on_collection_pickup_input(ev, coupon["id"]))
	else:
		_build_mystery_card(panel, coupon)
		root.modulate = Color(0.3, 0.3, 0.3, 0.75)

	return root


func _build_image_card(parent: Control, coupon: Dictionary, font_size: int):
	if coupon["id"] in COUPON_IMAGES:
		var tex = TextureRect.new()
		tex.set_anchors_preset(Control.PRESET_FULL_RECT)
		tex.texture = load(COUPON_IMAGES[coupon["id"]])
		tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.mouse_filter = Control.MOUSE_FILTER_PASS
		parent.add_child(tex)

	var overlay = VBoxContainer.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay.mouse_filter = Control.MOUSE_FILTER_PASS

	var name_lbl = Label.new()
	name_lbl.text = coupon["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_font_size_override("font_size", font_size + 1)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.add_theme_constant_override("shadow_offset_x", 1)
	name_lbl.add_theme_constant_override("shadow_offset_y", 1)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	overlay.add_child(name_lbl)

	var tier_lbl = Label.new()
	tier_lbl.text = coupon["tier"].to_upper()
	tier_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_lbl.add_theme_font_size_override("font_size", font_size)
	tier_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	_apply_tier_color(tier_lbl, coupon["tier"])
	overlay.add_child(tier_lbl)

	parent.add_child(overlay)


func _build_mystery_card(parent: Control, coupon: Dictionary):
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS

	var q = Label.new()
	q.text = "???"
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.add_theme_font_size_override("font_size", 16)
	q.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(q)

	var t = Label.new()
	t.text = coupon["tier"].to_upper()
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", COLLECT_FONT)
	t.mouse_filter = Control.MOUSE_FILTER_PASS
	_apply_tier_color(t, coupon["tier"])
	vbox.add_child(t)

	parent.add_child(vbox)


func _add_centered_label(parent: Control, text: String, font_size: int):
	var lbl = Label.new()
	lbl.text = text
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(lbl)


func _apply_tier_color(lbl: Label, tier: String):
	match tier:
		"low":    lbl.add_theme_color_override("font_color", Color.LIGHT_BLUE)
		"medium": lbl.add_theme_color_override("font_color", Color.YELLOW)
		"high":   lbl.add_theme_color_override("font_color", Color.ORANGE_RED)


# ── drag & drop ───────────────────────────────────────────────
# Input flow:
#   mouse-down on collection/slot card  →  _start_drag()
#   _process each frame                 →  ghost follows cursor,
#                                          rect-test highlights target slot
#   mouse-up anywhere (_input)          →  _slot_index_at() decides drop or cancel

func _on_collection_pickup_input(ev: InputEvent, coupon_id: String):
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed:
		_start_drag(coupon_id, -1)


func _on_slot_pickup_input(ev: InputEvent, slot_idx: int):
	if not (ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and ev.pressed):
		return
	var equipped_id = ""
	if slot_idx < GameState.equipped_coupon_ids.size():
		equipped_id = GameState.equipped_coupon_ids[slot_idx]
	if equipped_id != "":
		_start_drag(equipped_id, slot_idx)


func _start_drag(coupon_id: String, source_slot: int):
	drag_coupon_id   = coupon_id
	drag_source_slot = source_slot

	if drag_ghost:
		drag_ghost.queue_free()
	drag_ghost = _build_ghost(coupon_id)
	drag_layer.add_child(drag_ghost)

	drag_ghost.pivot_offset = drag_ghost.custom_minimum_size / 2.0
	drag_ghost.position     = get_global_mouse_position() - drag_ghost.pivot_offset

	drag_ghost.scale = Vector2(0.7, 0.7)
	var t = create_tween()
	t.tween_property(drag_ghost, "scale", Vector2(1.1, 1.1), 0.1)
	t.tween_property(drag_ghost, "scale", Vector2(1.0, 1.0), 0.07)


func _build_ghost(coupon_id: String) -> Control:
	var root = Control.new()
	root.custom_minimum_size = SLOT_CARD_SIZE
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.modulate = Color(1, 1, 1, 0.85)
	root.add_child(panel)

	var coupon = _find_coupon(coupon_id)
	if coupon:
		_build_image_card(panel, coupon, SLOT_FONT)

	return root


# returns which unlocked slot index the point lands in, or -1
func _slot_index_at(global_pt: Vector2) -> int:
	for i in range(min(slot_cards.size(), GameState.coupon_slots)):
		var rect = Rect2(slot_cards[i].global_position, slot_cards[i].size)
		if rect.has_point(global_pt):
			return i
	return -1


func _commit_drop(target_slot: int):
	var target_id = ""
	if target_slot < GameState.equipped_coupon_ids.size():
		target_id = GameState.equipped_coupon_ids[target_slot]

	if drag_source_slot == -1:
		# collection → slot; bump displaced coupon back to collection
		if target_id != "":
			GameState.unequip_coupon(target_slot)
		GameState.equip_coupon(drag_coupon_id, target_slot)
	else:
		# slot → slot swap
		if target_id != "":
			GameState.equip_coupon(target_id, drag_source_slot)
		else:
			GameState.unequip_coupon(drag_source_slot)
		GameState.equip_coupon(drag_coupon_id, target_slot)

	GameState.save_game()
	_cancel_drag()
	_build_coupons_panel()


func _cancel_drag():
	drag_coupon_id   = ""
	drag_source_slot = -1
	_hovered_slot    = -1
	if drag_ghost:
		drag_ghost.queue_free()
		drag_ghost = null
	for card in slot_cards:
		card.modulate = Color.WHITE


func _process(_delta):
	if drag_ghost == null or drag_coupon_id == "":
		return

	drag_ghost.position = get_global_mouse_position() - drag_ghost.pivot_offset

	var hit = _slot_index_at(get_global_mouse_position())
	if hit != _hovered_slot:
		if _hovered_slot != -1 and _hovered_slot < slot_cards.size():
			slot_cards[_hovered_slot].modulate = Color.WHITE
		if hit != -1 and hit < slot_cards.size():
			_bump_card(slot_cards[hit])
			slot_cards[hit].modulate = Color(1.15, 1.15, 0.6)
		_hovered_slot = hit


func _input(ev: InputEvent):
	if not (ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed):
		return
	if drag_coupon_id == "":
		return
	var hit = _slot_index_at(get_global_mouse_position())
	if hit != -1:
		_commit_drop(hit)
	else:
		_cancel_drag()


func _bump_card(card: Control):
	var t = create_tween()
	t.tween_property(card, "scale", Vector2(1.12, 1.12), 0.07).set_trans(Tween.TRANS_BACK)
	t.tween_property(card, "scale", Vector2(1.0,  1.0),  0.1).set_trans(Tween.TRANS_BACK)


# ── helpers ───────────────────────────────────────────────────

func _find_coupon(id: String) -> Dictionary:
	for c in GameState.ALL_COUPONS:
		if c["id"] == id:
			return c
	return {}


func _on_pay_debt():
	var amount = min(GameState.gold, GameState.debt)
	if amount > 0:
		GameState.pay_debt(amount)
		_update_bottom_bar()


func _on_start_shopping():
	if GameState.active_orders.is_empty():
		return
	get_tree().change_scene_to_file("res://Scenes/shopping.tscn")
