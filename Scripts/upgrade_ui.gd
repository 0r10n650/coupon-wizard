extends Control

@onready var gold_label = $Panel/VBoxContainer/Header/GoldContainer/GoldLabel
@onready var upgrades_container = $Panel/VBoxContainer/ScrollContainer/UpgradesList

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
	{"id": "checkout_combo_time", "name": "Combo Timer", "desc": "Slows down combo expiration in checkout."},
	{"id": "checkout_shake_reduction", "name": "Steady Rhythm", "desc": "Reduces timer decay acceleration per combo hit."},
	{"id": "checkout_shake_delay", "name": "Nerves of Steel", "desc": "Delays the start of timer decay acceleration by more combo hits."},
	{"id": "checkout_bonus_arrow", "name": "Bonus Arrow Value", "desc": "Increases money earned for each arrow hit after reaching max combo."},
	{"id": "shopping_time", "name": "Shopping Time", "desc": "Increases the time limit for shopping."}
]

func _ready():
	refresh_ui()

func refresh_ui():
	gold_label.text = str(int(GameState.gold))
	
	# Clear existing
	for child in upgrades_container.get_children():
		child.queue_free()
		
	for upg in upgrade_definitions:
		var item = create_upgrade_item(upg)
		upgrades_container.add_child(item)

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

func _on_close_button_pressed():
	var player = get_tree().current_scene.get_node_or_null("Player")
	if player and player.has_method("set_movement_locked"):
		player.set_movement_locked(false)
	queue_free()
