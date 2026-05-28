extends Panel

signal coupon_selected(coupon_id)
signal close_requested

func _ready():
	# Setup some test coupons
	var grid = $MarginContainer/VBoxContainer/GridContainer
	for i in range(6):
		var btn = Button.new()
		btn.text = "Coupon " + str(i + 1)
		btn.custom_minimum_size = Vector2(120, 180)
		btn.pressed.connect(_on_coupon_pressed.bind(i + 1))
		grid.add_child(btn)

func _on_coupon_pressed(id: int):
	coupon_selected.emit(id)

func remove_coupon(id: int):
	# For now, just disable or hide it
	var grid = $MarginContainer/VBoxContainer/GridContainer
	for child in grid.get_children():
		if child.text == "Coupon " + str(id):
			child.disabled = true
			child.text = "Used"

func _on_close_button_pressed():
	close_requested.emit()
