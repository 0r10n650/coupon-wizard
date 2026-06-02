extends Panel

signal coupon_selected(coupon_id)
signal close_requested

var total_discount_label: Label

func _ready():
	# Add total discount label under the header HBox
	var vbox = $MarginContainer/VBoxContainer
	total_discount_label = Label.new()
	total_discount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total_discount_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(total_discount_label)
	# Move it to be just under the title bar (index 1)
	vbox.move_child(total_discount_label, 1)
	
	refresh_magazine()

func get_coupon_name(coupon_id: int) -> String:
	var maze_type = (coupon_id - 1) % 6
	match maze_type:
		1: return "Rectangle"
		4: return "Circle"
		3: return "Hexagon"
		2: return "Triangle"
		0: return "Star"
		5: return "Gear"
		_: return "Unknown"

func refresh_magazine():
	if total_discount_label:
		total_discount_label.text = "Current Total Discount: %d%% Off" % int(GameState.get_total_discount_percent())
		
	var grid = $MarginContainer/VBoxContainer/GridContainer
	# We must defer child clearing or clear immediately. Since queue_free takes a frame,
	# we should remove children from the node tree immediately before calling queue_free
	# to avoid them sticking around until the end of the frame when adding new buttons.
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
		
	for i in range(6):
		var coupon_id = i + 1
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(120, 180)
		
		var c_name = get_coupon_name(coupon_id)
		var c_pct = GameState.get_coupon_percent(coupon_id)
		
		# Check if successful
		var is_claimed = false
		for c in GameState.daily_state["successful_coupons"]:
			if c["id"] == coupon_id:
				is_claimed = true
				break
				
		if is_claimed:
			btn.text = "%s\n[CLAIMED]\n(%d%% Off)" % [c_name, c_pct]
			btn.disabled = true
		elif not GameState.can_try_coupon(coupon_id):
			btn.text = "%s\n[LOCKED]\n(%d%% Off)" % [c_name, c_pct]
			btn.disabled = true
		else:
			btn.text = "%s\n(%d%% Off)\n[PLAY]" % [c_name, c_pct]
			btn.pressed.connect(_on_coupon_pressed.bind(coupon_id))
			
		grid.add_child(btn)

func _on_coupon_pressed(id: int):
	coupon_selected.emit(id)

func remove_coupon(id: int):
	refresh_magazine()

func _on_close_button_pressed():
	close_requested.emit()
