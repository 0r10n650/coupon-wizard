extends PanelContainer
class_name receipt

var successful_items
var destroyed_items
var item_count = 0
var add_discount_amount = 0
var add_credit_amount = 0
const ROW_SCENE = preload("res://Scenes/ui/ReceiptItem.tscn")
@onready var item_container = %itemContainerV
@onready var discount_label = %DiscountLabel
@onready var success_total_label = %SuccessLabel
@onready var destroyed_total_label = %DestroyedLabel
@onready var total_label = %TotalLabel

@onready var discount = $VBoxContainer/Discount
@onready var success = $VBoxContainer/Success
@onready var destroyed = $VBoxContainer/Destroyed
@onready var total = $VBoxContainer/Total
@onready var button = $VBoxContainer/Button
@onready var sep2 = $VBoxContainer/Seperator2
@onready var sep3 = $VBoxContainer/Seperator3
@onready var sep4 = $VBoxContainer/Seperator4
@onready var sep5 = $VBoxContainer/Seperator5

func load_items(item_group, destroyed):
	var grouped_items = {}
	
	for item in item_group:
		if item.name in grouped_items:
			grouped_items[item.name]["count"] += 1
		else:
			grouped_items[item.name] = {"item": item, "count": 1}
	
	for key in grouped_items:
		var new_row = ROW_SCENE.instantiate()
		new_row.setup(grouped_items[key]["item"], grouped_items[key]["count"], destroyed)
		item_container.add_child(new_row)
		await get_tree().process_frame  # wait for layout to update

			# slide the whole receipt up by the height of the new row
		var tween = create_tween()
		tween.tween_property(self, "position:y", position.y - new_row.size.y, 0.2)
		await get_tree().create_timer(0.3).timeout 

func setup(s_items, d_items):
	if not is_node_ready():
		await ready
	successful_items = s_items
	destroyed_items = d_items
	
	discount.visible = false
	success.visible = false
	destroyed.visible = false
	total.visible = false
	button.visible = false
	sep2.visible = false
	sep3.visible = false
	sep4.visible = false

	await load_items(successful_items, false)
	await load_items(destroyed_items, true)
	await load_total()
	sep2.visible = true
	
	# reveal totals one by one
	await get_tree().create_timer(0.3).timeout
	discount.visible = true
	
	await get_tree().create_timer(0.4).timeout
	success.visible = true
	
	destroyed.visible = true
	
	sep3.visible = true
	
	total.visible = true
	
	sep4.visible = true
	
	button.visible = true
	
	sep5.visible = true
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 230, 0.2)

func load_total():
	var successful_total = 0
	for item in successful_items:
		if item != null:
			var val = item.get("price")
			if val != null:
				successful_total += int(round(val))
			
	var destroyed_total = 0
	for item in destroyed_items:
		if item != null:
			var val = item.get("price")
			if val != null:
				destroyed_total += int(round(val))

	var discount_pct = GameState.discount
	var final_debt_added = (successful_total + destroyed_total - discount_pct)
	
	success_total_label.text = "%.2f" % successful_total
	destroyed_total_label.text = "%.2f" % destroyed_total
	discount_label.text = "-%.2f" % discount_pct
	total_label.text = "%.2f" % final_debt_added
	
	add_discount_amount = discount_pct
	add_credit_amount = final_debt_added
	##_process_payment(final_debt_added, discount_amount, panel)

func _process_payment():
	GameState.gold += add_discount_amount # You still get cash back for the discount
	GameState.debt += add_credit_amount
	GameState.advance_day()
	
	queue_free()
	get_tree().change_scene_to_file("res://Scenes/Management/management_screen.tscn")
