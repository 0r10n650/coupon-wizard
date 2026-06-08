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

# upgrades list lives inside UpgradesPanel
@onready var upgrades_vbox = %UpgradesVBox

# -- bottom bar
@onready var day_label   = %DayLabel
@onready var gold_label  = %GoldLabel
@onready var debt_label  = %DebtLabel
@onready var pay_debt_btn = %PayDebtBtn

signal gold_changed(new_value: int)
signal debt_changed(new_value: int)

var gold_icon = preload("res://Assets/gold_coin.png")
const COIN = "[img=16]res://Assets/gold_coin.png[/img]"

var upgrade_definitions = [
	{"id": "coupon_time",     "name": "Maze Time Limit",  "desc": "Increases time to complete mazes."},
	{"id": "coupon_retries",  "name": "Coupon Retries",   "desc": "Allows retrying a failed coupon."},
	{"id": "shopping_time",   "name": "Shopping Time",    "desc": "Increases the time limit for shopping."},
	{"id": "checkout_time",   "name": "Checkout Time",    "desc": "Increases global time limit for checkout."},
	{"id": "checkout_vision", "name": "Checkout Vision",  "desc": "Allows seeing an extra upcoming arrow."},
	{"id": "coupon_slots",    "name": "Coupon Slots",     "desc": "Unlocks an additional coupon slot (max 5)."},
	{"id": "orders",          "name": "Order Slots",      "desc": "Increases how many orders you can take per day (max 5)."},
	{"id": "order_rerolls",   "name": "Order Rerolls",    "desc": "Allows rerolling the order pool once or twice per day."},
]

func _ready() -> void:
	GameState.save_current_scene(scene_file_path)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	orders_btn.pressed.connect(_show_orders)
	upgrades_btn.pressed.connect(_show_upgrades)
	coupons_btn.pressed.connect(func(): SceneLoader.load_scene("res://Scenes/ui/CouponUpgrades/coupon_upgrade_scene.tscn"))
	start_shopping_btn.pressed.connect(_on_start_shopping)
	pay_debt_btn.pressed.connect(_on_pay_debt)

	orders_panel.order_selection_changed.connect(_on_order_selection_changed)
	if orders_panel.has_signal("order_slot_purchased"):
		orders_panel.order_slot_purchased.connect(_update_bottom_bar)

	_show_orders()
	_update_bottom_bar()
	_update_order_count(GameState.active_orders.size())

# ── panel switching ─────────────────────────────

func _switch_to(active_btn: Button, active_panel: Control):
	for panel in [orders_panel, upgrades_panel]:
		panel.visible = false
	for btn in [orders_btn, upgrades_btn, coupons_btn]:
		btn.modulate = Color(1, 1, 1, 0.55)
	active_panel.visible = true
	active_btn.modulate = Color.WHITE

func _show_orders():
	_switch_to(orders_btn, orders_panel)
	orders_panel.refresh()

func _show_upgrades():
	_switch_to(upgrades_btn, upgrades_panel)
	_refresh_upgrades()

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
	var current_val = GameState.get_upgrade_value(def["id"])
	var next_val = GameState.get_upgrade_next_value(def["id"])
	var val_text = ""
	if next_val != null:
		val_text = " [%s -> %s]" % [str(current_val), str(next_val)]
	else:
		val_text = " [Max]"
	desc_lbl.text = def["desc"] + val_text
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

# ── order panel handlers ──────────────────────────────────────

func _on_order_selection_changed(order: Order, selected: bool):
	if selected:
		if not GameState.active_orders.has(order):
			GameState.active_orders.append(order)
	else:
		GameState.active_orders.erase(order)
	_update_order_count(GameState.active_orders.size())

func _on_pay_debt():
	var amount = min(GameState.gold, GameState.debt)
	if amount > 0:
		GameState.pay_debt(amount)
		_update_bottom_bar()
		if GameState.debt <= 0:
			SceneLoader.load_scene("res://Scenes/ui/win_screen.tscn")

func _on_start_shopping():
	if GameState.active_orders.is_empty():
		return
	SceneLoader.load_scene("res://Scenes/Shopping/shopping.tscn")
